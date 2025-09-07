import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/models/chat_model.dart';

class ChatDetailNotifier extends StateNotifier<Chat> {
  ChatDetailNotifier(super.chat);

  void updateTitle(String newTitle, WidgetRef ref) {
    // 1. Update local state for this screen
    final updatedChat = state.copyWith(title: newTitle);
    state = updatedChat;

    // 2. Update the global list so the rest of the app sees the change
    ref.read(chatListProvider.notifier).updateChat(updatedChat);
  }
}
