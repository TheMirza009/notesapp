import 'dart:async';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:riverpod/riverpod.dart';
import 'package:isar/isar.dart';

/// Provider for the notifier
final chatMessagesController =
    NotifierProvider.autoDispose<ChatMessagesNotifier, List<Message>>(
  () => ChatMessagesNotifier(),
);

class ChatMessagesNotifier extends AutoDisposeNotifier<List<Message>> {
  final _isar = IsarDatabase.isar;
  Chat? _chat; // read-only reference
  bool isLoading = false;
  bool isSelecting = false;

  @override
  List<Message> build() {
    final selectedChat = ref.watch(chatListProvider).selectedChat;
    if (selectedChat == null) {
      return []; // gracefully return empty, no crash
    }
    _chat = selectedChat;
    _hydrateMessages();
    return [];
  }

  /// Load messages from DB and update state
  Future<void> _hydrateMessages() async {
    if (_chat == null || isLoading) return;
    isLoading = true;

    final freshChat = await _isar.chats.get(_chat!.isarID);
    if (freshChat != null) {
      await freshChat.messages.load();
      await Future.wait(freshChat.messages.map((m) => m.media.load()));

      state = freshChat.messages.toList();
    }

    isLoading = false;
  }

  /// Update or add a message
  Future<void> updateMessage(Message message) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.messages.get(message.isarId);
      if (existing != null) {
        existing.text = message.text;
        existing.isSender = message.isSender;
        await _isar.messages.put(existing);
      } else {
        await _isar.messages.put(message);
      }
    });

    // Update state in memory
    final messages = [...state];
    final index = messages.indexWhere((m) => m.isarId == message.isarId);
    if (index != -1) {
      messages[index] = message;
    } else {
      messages.add(message);
    }

    state = messages;
  }

  /// Send a text message
  Future<void> sendMessage(String text) async {
    if (_chat == null) return;


    final newMessage = Message()
      ..text = text
      ..time = DateTime.now()
      ..isSender = true;

    await _isar.writeTxn(() async {
      await _isar.messages.put(newMessage);
      if (_chat != null) {
        _chat!.messages.add(newMessage);
        await _chat!.messages.save();
        await _isar.chats.put(_chat!);
      }
    });

    state = [...state, newMessage];
    deleteInitMessage();
  }

  /// Pick image and send as message
  Future<void> pickImage() async {
    final pickedMedia = await MediaHandler.pickImage();
    if (pickedMedia == null) return;

    deleteInitMessage();

    await _isar.writeTxn(() async {
      await _isar.medias.put(pickedMedia);
    });

    final persistedMedia = await _isar.medias.get(pickedMedia.isarId);
    if (persistedMedia == null) return;

    final newMessage = Message()
      ..isSender = true
      ..time = DateTime.now()
      ..media.value = persistedMedia;

    await _isar.writeTxn(() async {
      await _isar.messages.put(newMessage);
      if (_chat != null) {
        _chat!.messages.add(newMessage);
        await _chat!.messages.save();
        await _isar.chats.put(_chat!);
      }
    });

    state = [...state, newMessage];
  }

  Future<void> deleteInitMessage() async {
    if (_chat == null || state == null || state!.isEmpty) return;

    const String initID = "0000";
    const String initText = "This is a new chat. Start typing to create your first note.";

    final firstMessage = state!.first;
    if (firstMessage.id == initID && firstMessage.text == initText) {
       deleteMessage(firstMessage);
    }
  }


  /// Delete a single message
  Future<void> deleteMessage(Message message) async {
    await _isar.writeTxn(() async {
      await _isar.messages.delete(message.isarId);
      if (_chat != null) {
        _chat!.messages.remove(message);
        await _chat!.messages.save();
        await _isar.chats.put(_chat!);
      }
    });

    if (message.media.value != null && message.media.value!.type != Mediatype.text) {
      await MediaHandler.deleteMedia(message.media.value!);
    }

    state = state.where((m) => m.isarId != message.isarId).toList();
  }

  /// Delete selected messages
  Future<void> deleteSelected() async {
    final selected = state.where((m) => m.isSelected).toList();
    if (selected.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final m in selected) {
        await _isar.messages.delete(m.isarId);
        if (_chat != null) {
          _chat!.messages.remove(m);
        }

        if (m.media.value != null && m.media.value!.type != Mediatype.text) {
          await MediaHandler.deleteMedia(m.media.value!);
        }
      }
      if (_chat != null) await _chat!.messages.save();
      if (_chat != null) await _isar.chats.put(_chat!);
    });

    unSelectAllMessages();
    state = state.where((m) => !selected.contains(m)).toList();
  }

  /// Select / unselect messages
  void selectMessage(Message message) {
    message.isSelected = true;
    isSelecting = true;
    state = [...state];
  }

  void unselectMessage(Message message) {
    message.isSelected = false;
    if (state.every((m) => !m.isSelected)) isSelecting = false;
    state = [...state];
  }

  void unSelectAllMessages() {
    for (var m in state) m.isSelected = false;
    isSelecting = false;
    state = [...state];
  }

  void selectAllMessages() {
    for (var m in state) m.isSelected = true;
    isSelecting = true;
    state = [...state];
  }

  int selectCount() => state.where((m) => m.isSelected).length;

  /// Clears the selected chat
  void clearChat() {
    ref.read(chatListProvider.notifier).clearSelectedChat();
    state = [];
  }

  void removeChatIfEmpty() async {
  if (_chat == null) return;

  // Always re-fetch a managed copy
  final managedChat = await _isar.chats.get(_chat!.isarID);
  if (managedChat == null) return;

  await managedChat.messages.load();

  // Handle empty case
  if (managedChat.messages.isEmpty) {
    ref.read(chatListProvider.notifier).removeChat(managedChat);
    return;
  }

  // Handle init placeholder
  const String initText = "This is a new chat. Start typing to create your first note.";
  const String initID = "0000";

  if (managedChat.messages.length == 1 &&
      managedChat.messages.first.text == initText &&
      managedChat.messages.first.id == initID) {
    ref.read(chatListProvider.notifier).removeChat(managedChat);
  }
}



    /// Context menu actions
  void handleMessageMenuAction(String action, Message message) {
    switch (action) {
      case 'deleteMessage':
        deleteMessage(message);
        isSelecting = false;
        break;
      case 'reply':
        print("Reply to `${message.text}`");
        unSelectAllMessages();
        break;
      case 'copy':
        Utils.copyToClipboard(message.text);
        unSelectAllMessages();
        break;
      case 'toggleSender':
        message.isSender = !message.isSender;
        updateMessage(message);
        unSelectAllMessages();
        break;
    }
  }
}
