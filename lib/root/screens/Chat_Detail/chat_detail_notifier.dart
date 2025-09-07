import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/data/models/chat_model.dart';

final chatDetailProvider = StateNotifierProvider.family<ChatDetailNotifier, Chat, Chat>((ref, chat) {
  return ChatDetailNotifier(chat);
});

class ChatDetailNotifier extends StateNotifier<Chat> {
  ChatDetailNotifier(super.chat);

  void updateTitle(String newTitle) {
    state = state.copyWith(title: newTitle);
  }
}
