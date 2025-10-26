import 'package:flutter/material.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/content/thread_message_view.dart';

class ThreadTestScreen extends StatelessWidget {
  const ThreadTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ThreadMessageView());
  }
}