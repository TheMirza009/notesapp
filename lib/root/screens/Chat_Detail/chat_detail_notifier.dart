import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier.dart';

class ChatDetailNotifier extends StateNotifier<Chat> {
  ChatDetailNotifier(super.chat);

  void updateTitle(String newTitle, WidgetRef ref) async {
    // 1. Update local state for this screen
    final updatedChat = state.copyWith(title: newTitle);
    state = updatedChat;

    // 2. Update the global list so the rest of the app sees the change
    await ref.read(chatListProvider.notifier).updateChat(updatedChat);

  }
}
