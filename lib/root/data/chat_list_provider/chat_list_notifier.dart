import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/data/dummy_data/dummy_chats.dart';
import 'package:notesapp/root/data/models/chat_model.dart';

// Notifier that controls a list of chats
class ChatListNotifier extends StateNotifier<List<Chat>> {
  ChatListNotifier() : super(dummyChats);

  void addChat(Chat chat) {
    state = [...state, chat]; // immutable update
  }

  void removeChat(Chat chat) {
    state = state.where((c) => c != chat).toList();
  }

  void clearChats() {
    state = [];
  }
}

// The provider
final chatListProvider = StateNotifierProvider<ChatListNotifier, List<Chat>>((ref) {
  return ChatListNotifier();
});
