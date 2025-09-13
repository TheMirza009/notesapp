import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';

class TestChatScreen extends StatefulWidget {
  final Chat chat;
  const TestChatScreen({super.key, required this.chat});

  @override
  State<TestChatScreen> createState() => _TestChatScreenState();
}


class _TestChatScreenState extends State<TestChatScreen> {
  List<Message> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.messageBarDark,
      appBar: AppBar(
        title: Text("Chat: ${widget.chat.title}"),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '', // <-- disable tooltip
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final Message message = messages[index];
              return MessageBubble(message: message);
            }),
          ),
        ],
      ),
    );
  }
}