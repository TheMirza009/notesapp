import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/chat_list_extension.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class ChatScreenNotifier extends Notifier<Chat> {
  final String initText = "This is a new chat. Start typing to create your first note.";
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

  void deleteMessage(Message message) {
    if (message.id == null) return;
    final updatedMessages = state.messages.removeMessageById(message.id!);
    final updatedChat = state.copyWith(messages: updatedMessages);
    updateChat(updatedChat);
  }
  
  void updateChat(Chat updatedChat) {
    ref.read(chatListProvider.notifier).updateChat(updatedChat);
    state = updatedChat; // keep local state synced
  }

  void removeChatIfEmpty() {
    if (state.messages.isEmpty || (state.messages.length == 1 && state.messages[0].text == initText)) {
      ref.read(chatListProvider.notifier).removeChat(state);
    }
  }
}

/// Provider
final chatScreenController = NotifierProvider<ChatScreenNotifier, Chat>(ChatScreenNotifier.new);
