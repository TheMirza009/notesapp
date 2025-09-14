import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/bottom_message_bar.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';
import 'package:notesapp/root/widgets/glass_container.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';

class TestChatScreen extends StatefulWidget {
  final Chat chat;
  const TestChatScreen({super.key, required this.chat});

  @override
  State<TestChatScreen> createState() => _TestChatScreenState();
}


class _TestChatScreenState extends State<TestChatScreen> {
  List<Message> messages = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    // Load the messages linked to this chat
    await widget.chat.messages.load();

    setState(() {
      messages = widget.chat.messages.toList();
    });
  }

  Future<void> _sendMessage(String text) async {
    final isar = Isar.getInstance('isar');
    if (isar == null) {
      throw Exception("Isar has not been initialized.");
    }

    // Message creation
    final newMessage = Message()
    ..text = text
    ..isSender = true
    ..isSelected = false
    ..time = DateTime.now();

    // Database save
    await isar.writeTxn(() async {

      // add to messages database
      await isar.messages.put(newMessage);

      // connect to chat object
      widget.chat.messages.add(newMessage); // adding to local detached chat object
      await widget.chat.messages.save();

      // update chat
      widget.chat.preview = newMessage.text;
      widget.chat.date = newMessage.time;
      await isar.chats.put(widget.chat);
    });

    setState(() {
      messages.add(newMessage);
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.textLight,
      appBar: AppBar(
        title: Text("Chat: ${widget.chat.title}"),
        backgroundColor: ThemeConstants.messageBarDark,
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
            child: messages.isEmpty 
            ? NothingToSee() 
            : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final Message message = messages[index];
                return GlassContainer(child: Text(message.text));
              return MessageBubble(message: message, );
            }),
          ),
          BottomMessageBar(
            onEmojiTap: () {},
            onAttachmentTap: () {},
            onMicTap: () {},
            onSend: (text) {
              print(text);
              _sendMessage(text);
            },
          )
        ],
      ),
    );
  }
}