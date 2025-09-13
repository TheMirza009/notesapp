import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/chat_list_isar_extensions.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/data/repository/chat_repository.dart';

class ChatScreenNotifier extends Notifier<Chat> {
  final String initText = "This is a new chat. Start typing to create your first note.";
  bool isSelecting = false;
  late String chatId;

  @override
  Chat build() {
    // Grab chatList from global provider
    if (chatId == null) return Chat.emptyChat();
    final chatList = ref.watch(chatListProvider);
    final chat = chatList.getChatByID(chatId);
    return chat;
  }

  /// Set which chat this controller should manage
  void init(String id) {
    chatId = id;
    state = ref.read(chatListProvider).getChatByID(id);
    ref.invalidateSelf();
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
final chatScreenController = NotifierProvider<ChatScreenNotifier, Chat>(ChatScreenNotifier.new);
