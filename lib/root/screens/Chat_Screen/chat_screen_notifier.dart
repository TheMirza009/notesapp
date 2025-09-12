import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/chat_list_extension.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class ChatScreenNotifier extends Notifier<Chat> {
  final String initText = "This is a new chat. Start typing to create your first note.";
  bool isSelecting = false;
  late String chatId;

  @override
  Chat build() {
    // Grab chatList from global provider
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

  void sendMessage(String text) {
    final newMessage = Message(text: text, time: DateTime.now());
    final updatedMessages = state.messages.removeMessageWithText(initText);
    final updatedChat = state.copyWith(
      messages: [...updatedMessages, newMessage],
      preview: newMessage.text,
      date: newMessage.time,
    );
    updateChat(updatedChat);
  }

  Future<void> pickImage() async {
    final image = await MediaHandler.pickImage();
    if (image == null) return;
    final newImageMessage = Message(text: "", time: DateTime.now(), media: image);
    final updatedChat = state.copyWith(
      messages: [...state.messages, newImageMessage],
      preview: "📷 Photo",
      date: newImageMessage.time,
    );
    updateChat(updatedChat);
  }

  void toggleSender(Message message) {
    if (message.id == null) return;
    final updatedMessages = state.messages.toggleSenderById(message.id!);
    final updatedChat = state.copyWith(messages: updatedMessages);
    updateChat(updatedChat);
  }

  int selectCount() {
    return state.messages.selectedCount;
  }

  void selectMessage(Message message) {
    if (message.id == null) return;
    isSelecting = true;
    final updatedMessages = state.messages.selectMessageByID(message.id!);
    final updatedChat = state.copyWith(messages: updatedMessages);
    updateChat(updatedChat);
  }

  void unselectMessage(Message message) {
    if (message.id == null) return;
    isSelecting = true;
    final updatedMessages = state.messages.unselectMessageByID(message.id!);
    final updatedChat = state.copyWith(messages: updatedMessages);
    updateChat(updatedChat);

    if (state.messages.allUnselected) {
      isSelecting = false;
    }
  }

  void unSelectAllMessages() {
    isSelecting = false;
    final updatedMessages = state.messages.unselectAll();
    final updatedChat = state.copyWith(messages: updatedMessages);
    updateChat(updatedChat);
  }

  void deleteMessage(Message message) async {
    if (message.id == null) return;
    // If it's not a text message, delete the file from storage
    if (message.media != null && message.media!.type != Mediatype.text) {
      await MediaHandler.deleteMedia(message.media!);
    }
    final updatedMessages = state.messages.removeMessageById(message.id!);
    final updatedChat = state.copyWith(messages: updatedMessages);
    updateChat(updatedChat);
    unSelectAllMessages();
  }

  void deleteSelected() {
    if (state.messages.allUnselected) return;
    final updatedMessages = state.messages.deleteSelectedMessages();
    final updatedChat = state.copyWith(messages: updatedMessages);
    updateChat(updatedChat);
    isSelecting = false;
  }
  
  void updateChat(Chat updatedChat) {
    ref.read(chatListProvider.notifier).updateChat(updatedChat);
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
    if (state.messages.isEmpty || (state.messages.length == 1 && state.messages[0].text == initText)) {
      ref.read(chatListProvider.notifier).removeChat(state);
    }
  }
}

/// Provider
final chatScreenController = NotifierProvider<ChatScreenNotifier, Chat>(ChatScreenNotifier.new);
