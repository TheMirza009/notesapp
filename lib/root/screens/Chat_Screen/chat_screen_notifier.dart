import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/chat_list_isar_extensions.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class ChatScreenNotifier extends Notifier<Chat> {
  final String initText = "This is a new chat. Start typing to create your first note.";
  bool isSelecting = false;
  final Id chatId;

  ChatScreenNotifier(this.chatId);

  @override
Chat build() {
  // Start async loading
  _loadChat();
  final Chat chat = Chat()
  ..messages = IsarLinks<Message>();

  // Return a placeholder chat (won’t matter, since the real chat will replace it)
  return chat;
}


  Future<void> _loadChat() async {
  // Find the chat by Isar auto-increment ID
  final chatFromIsar = await IsarDatabase.isar.chats
      .where()
      .isarIDEqualTo((chatId)) // assuming chatId is a String; convert to int
      .findFirst();

  if (chatFromIsar != null) {
    // Fetch messages that belong to this chat, sorted by time
    final messages = await IsarDatabase.isar.messages
        .filter()
        .chat((q) => q.isarIDEqualTo(chatFromIsar.isarID))
        .findAll();

    // Update state with real messages
    state = chatFromIsar.copyWith(messages: messages);
  }
}


  /// Send a text message and persist it
  Future<void> sendMessage(String text) async {
    final newMessage = Message()
      ..text = text
      ..time = DateTime.now();

    final updatedMessages = state.messages.toList().removeMessageWithText(initText);
    final updatedChat = state.copyWith(
      messages: [...updatedMessages, newMessage],
      preview: newMessage.text,
      date: newMessage.time,
    );

    await updateChat(updatedChat); // ⬅️ persist to Isar
  }

  /// Pick image, wrap in a Message, and persist it
  Future<void> pickImage() async {
    final image = await MediaHandler.pickImage();
    if (image == null) return;

    final newImageMessage = Message()
      ..text = ""
      ..time = DateTime.now()
      ..media.value = image;

    final updatedChat = state.copyWith(
      messages: [...state.messages, newImageMessage],
      preview: "📷 Photo",
      date: newImageMessage.time,
    );

    await updateChat(updatedChat); // ⬅️ persist to Isar
  }

  void toggleSender(Message message) async {
    if (message.id == null) return;
    final updatedMessages = state.messages.toList().toggleSenderById(message.id!);
    final updatedChat = state.copyWith(messages: updatedMessages);
    await updateChat(updatedChat); // ⬅️ persist to Isar
  }

  int selectCount() => state.messages.toList().selectedCount;

  void selectMessage(Message message) async {
    if (message.id == null) return;
    isSelecting = true;
    final updatedMessages = state.messages.toList().selectMessageByID(message.id!);
    final updatedChat = state.copyWith(messages: updatedMessages);
    await updateChat(updatedChat); // ⬅️ persist to Isar
  }

  void unselectMessage(Message message) async {
    if (message.id == null) return;
    isSelecting = true;
    final updatedMessages = state.messages.toList().unselectMessageByID(message.id!);
    final updatedChat = state.copyWith(messages: updatedMessages);
    await updateChat(updatedChat); // ⬅️ persist to Isar

    if (updatedMessages.allUnselected) {
      isSelecting = false;
    }
  }

  void unSelectAllMessages() async {
    isSelecting = false;
    final updatedMessages = state.messages.toList().unselectAll();
    final updatedChat = state.copyWith(messages: updatedMessages);
    await updateChat(updatedChat); // ⬅️ persist to Isar
  }

  Future<void> deleteMessage(Message message) async {
    if (message.id == null) return;

    // If it's not a text message, delete the file from storage
    if (message.media.value != null && message.media.value!.type != Mediatype.text) {
      await MediaHandler.deleteMedia(message.media.value!);
    }

    final updatedMessages = state.messages.toList().removeMessageById(message.id!);
    final updatedChat = state.copyWith(messages: updatedMessages);
    await updateChat(updatedChat); // ⬅️ persist to Isar

    unSelectAllMessages();
  }

  Future<void> deleteSelected() async {
    if (state.messages.toList().allUnselected) return;
    final updatedMessages = state.messages.toList().deleteSelectedMessages();
    final updatedChat = state.copyWith(messages: updatedMessages);
    await updateChat(updatedChat); // ⬅️ persist to Isar
    isSelecting = false;
  }
  
  /// Centralized update (sync state + provider + Isar)
  Future<void> updateChat(Chat updatedChat) async {
    await ref.read(chatListProvider.notifier).updateChat(updatedChat);
    state = updatedChat; // keep local state synced
  }

  /// Message options callbacks
  void handleMessageMenuAction(String action, Message message) {
    if (action == 'deleteMessage') {
      deleteMessage(message);
    } else if (action == 'reply') {
      print("Reply to `${message.text}`");
    } else if (action == 'copy') {
      Utils.copyToClipboard(message.text);
    }
  }

  void removeChatIfEmpty() {
    final messages = state.messages.toList();
    if (messages.isEmpty || (messages.length == 1 && messages[0].text == initText)) {
      ref.read(chatListProvider.notifier).removeChat(state);
    }
  }
}

/// Provider
NotifierProvider<ChatScreenNotifier, Chat> chatScreenController(Id chatId) => NotifierProvider<ChatScreenNotifier, Chat>(() => ChatScreenNotifier(chatId));
