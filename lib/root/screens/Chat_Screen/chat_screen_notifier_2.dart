import 'dart:async';

import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:riverpod/riverpod.dart';
import 'package:isar/isar.dart';

/// ChatScreenNotifier is responsible for managing the lifecycle of a single chat
class ChatScreenNotifier extends AutoDisposeNotifier<Chat?> {
  late final Isar _isar;
  Chat? _chat; // snapshot from chatListProvider
  bool _isLoading = false;
  bool isSelecting = false;

  @override
  Chat? build() {
    _isar = IsarDatabase.isar;

    // Get currently selected chat from chatListProvider
    _chat = ref.watch(chatListProvider.notifier).selectedChat;

    if (_chat == null) {
      return null;
    }
    _hydrateChat(_chat!);  // Start async hydration in background

    // Optimistically return initial reference, UI won’t block
    return _chat;
  }

  /// Load full chat with messages + media from Isar and update state
  Future<void> _hydrateChat(Chat chat) async {
    if (_isLoading) return; // prevent double fetch
    _isLoading = true;

    final freshChat = await _isar.chats.get(chat.isarID);
    if (freshChat != null) {
      await freshChat.messages.load();
      await Future.wait(freshChat.messages.map((m) => m.media.load()));

      state = freshChat; // notify listeners with hydrated version
      print("Loaded from Isar: $freshChat");
    }

    _isLoading = false;
  }

  /// Clears the current chat selection → called when pressing back
  void clearChat() {
    ref.read(chatListProvider.notifier).selectedChat = null;
    state = null;
  }

  Future<void> updateMessage(Message message) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.messages.get(message.isarId);
      if (existing != null) {
        existing.text = message.text;
        existing.isSelected = message.isSelected;
        existing.isSender = message.isSender;
        await _isar.messages.put(existing);
      } else {
        await _isar.messages.put(message);
      }
    });

    await _hydrateChat(_chat!);
  }

  /// Send a new text message
  Future<void> sendMessage(String text) async {
    if (_chat == null) return;

    // Create the message
    final newMessage = Message().copyWith(
      text: text,
      time: DateTime.now(),
    );

    // Mutate in-memory chat instantly
    await _isar.writeTxn(() async {
      await _isar.messages.put(newMessage);
      _chat!.messages.add(newMessage);
      await _chat!.messages.save();
    });

    _chat!
      ..preview = text
      ..date = newMessage.time;

    ref.read(chatListProvider.notifier).updateChat(_chat!);

      _hydrateChat(_chat!);
      // ref.invalidateSelf();
  }
  
  selectMessage() {
    print("");
  }
  unSelectAllMessages() {
    print("");
  }
  deleteMessage() {
    print("");
  }
  removeChatIfEmpty() {
    print("");
  }
  selectCount() {
    print("");
  }
  
  deleteSelected() {
    print("");
  }
  unselectMessage() {
    print("");
  }
  handleMessageMenuAction() {
    print("");
  }
}
/// Provider for the notifier
final chatScreenController =
    NotifierProvider.autoDispose<ChatScreenNotifier, Chat?>(
  () => ChatScreenNotifier(),
);
