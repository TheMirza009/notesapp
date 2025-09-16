import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier.dart';

class ChatScreenOverride extends ConsumerWidget {
  const ChatScreenOverride({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(chatScreenController);
    final notifier = ref.read(chatScreenController.notifier);

    return ChatScreen(
      currentChat: chat,
      notifier: notifier,
    );
  }
}
