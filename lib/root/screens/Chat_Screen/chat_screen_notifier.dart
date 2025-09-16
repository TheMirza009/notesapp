import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/message_list_layout.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';


/// ------------------ Provider ------------------
final chatScreenController = NotifierProvider<ChatScreenNotifier, Chat>(
  () => ChatScreenNotifier(
        Chat()..title = "Placeholder" // dummy chat, will never be used
      ),
);
class ChatScreenNotifier extends Notifier<Chat> {
  Chat initialChat;

  ChatScreenNotifier(this.initialChat);

  bool _initialized = false;
  final Isar isar = IsarDatabase.isar;
  bool isSelecting = false;

  @override
  Chat build() {
    if (!_initialized) {
      _initialized = true;
      _initialize();
    }
    return initialChat;
  }

  Future<void> _initialize() async {
    final freshChat = await isar.chats.get(initialChat.isarID);
    if (freshChat != null) {
      await freshChat.messages.load();
      await Future.wait(freshChat.messages.map((m) => m.media.load()));
      print("Loaded: $freshChat");
      state = freshChat;
    }
  }

  // ---------------- Messaging ----------------

  Future<void> sendMessage(String text) async {
    deleteInitMessage();

    final newMessage = Message()
      ..text = text
      ..isSender = true
      ..isSelected = false
      ..time = DateTime.now();

    await isar.writeTxn(() async {
      await isar.messages.put(newMessage);
      initialChat.messages.add(newMessage);
      await initialChat.messages.save();
      initialChat.preview = newMessage.text;
      initialChat.date = newMessage.time;
      await isar.chats.put(initialChat);
    });

    // Sync with chat list
    ref.read(chatListProvider.notifier).updateChat(initialChat);

    state = initialChat;
  }

  Future<void> pickImage() async {
    final pickedMedia = await MediaHandler.pickImage();
    if (pickedMedia == null) return;

    deleteInitMessage();

    await isar.writeTxn(() async {
      await isar.medias.put(pickedMedia);
    });

    final persistedMedia = await isar.medias.get(pickedMedia.isarId);
    if (persistedMedia == null) return;

    final newMessage = Message()
      ..isSender = true
      ..isSelected = false
      ..time = DateTime.now()
      ..media.value = persistedMedia;

    await isar.writeTxn(() async {
      await isar.messages.put(newMessage);
      await newMessage.media.save();
      initialChat.messages.add(newMessage);
      await initialChat.messages.save();

      initialChat.preview = "📷 Photo";
      initialChat.date = newMessage.time;
      await isar.chats.put(initialChat);
    });

    await newMessage.media.load();
    ref.read(chatListProvider.notifier).updateChat(initialChat);

    state = initialChat;
  }

  void deleteInitMessage() {
    const String initID = "0000";
    const String initText = "This is a new chat. Start typing to create your first note.";

    if (initialChat.messages.isEmpty) return;

    final first = initialChat.messages.first;
    if (first.id == initID && first.text == initText) {
      deleteMessage(first);
    }
  }

  /// ------------------ Message selection ------------------

  void selectMessage(Message message) async {
    if (message.id == null) return;
    isSelecting = true;
    message.isSelected = true;
    await updateMessage(message);
  }

  void unselectMessage(Message message) async {
    if (message.id == null) return;
    message.isSelected = false;
    await updateMessage(message);

    if (initialChat.messages.every((m) => !m.isSelected)) {
      isSelecting = false;
    }
  }

  void unSelectAllMessages() async {
    isSelecting = false;
    for (var m in initialChat.messages) {
      m.isSelected = false;
      await updateMessage(m);
    }
    state = initialChat;
  }

  int selectCount() => initialChat.messages.where((m) => m.isSelected).length;

  /// ------------------ Update / Delete ------------------
  /// 
  Future<void> _refreshState() async {
    final freshChat = await isar.chats.get(initialChat.isarID);
    if (freshChat != null) {
      await freshChat.messages.load();
      await Future.wait(freshChat.messages.map((m) => m.media.load()));
      state = freshChat; // new instance from Isar → Riverpod sees update
    }
  }

  Future<void> updateMessage(Message message) async {
    await isar.writeTxn(() async {
      final existing = await isar.messages.get(message.isarId);
      if (existing != null) {
        existing.text = message.text;
        existing.isSelected = message.isSelected;
        existing.isSender = message.isSender;
        await isar.messages.put(existing);
      } else {
        await isar.messages.put(message);
      }
    });
    initialChat = state;
     await _refreshState();
  }

  Future<void> deleteMessage(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.delete(message.isarId);

      initialChat.messages.remove(message);
      // initialChat.preview = initialChat.messages.toList().last.text;
      await initialChat.messages.save();
      await isar.chats.put(initialChat);
    });

    if (message.media.value?.type != Mediatype.text && message.media.value != null && state.messages.isNotEmpty) {
      await MediaHandler.deleteMedia(message.media.value!);
    }

    state = initialChat;
  }

  Future<void> deleteSelected() async {
    final selected = initialChat.messages.where((m) => m.isSelected).toList();
    if (selected.isEmpty) return;

    for (var m in selected) {
      await deleteMessage(m);
    }

    isSelecting = false;
    state = initialChat;
  }

  /// ------------------ Utility ------------------

  void handleMessageMenuAction(String action, Message message) {
    switch (action) {
      case 'deleteMessage':
        deleteMessage(message);
        break;
      case 'reply':
        print("Reply to `${message.text}`");
        break;
      case 'copy':
        Utils.copyToClipboard(message.text);
        break;
      case 'toggleSender':
        message.isSender = !message.isSender;
        updateMessage(message);
        break;
    }
  }

  Future<void> updateTitle(String newTitle) async {
    final updated = initialChat.copyWith(title: newTitle);

    await isar.writeTxn(() async {
      await isar.chats.put(updated);
    });
    ref.read(chatListProvider.notifier).updateChat(updated);
    // initialChat = updated;
    state = updated;
    print("Init title: ${initialChat.title}");
    print("State title: ${state.title}");
  }



  void removeChatIfEmpty() {
    const String initID = "0000";
    const String initText = "This is a new chat. Start typing to create your first note.";
    
    final messages = initialChat.messages;
    if (messages.isEmpty || (messages.length == 1 && messages.first.text == initText && messages.first.text == initID)) {
      // deleteMessage(messages.first);
      ref.read(chatListProvider.notifier).removeChat(initialChat);
    }
  }
}

