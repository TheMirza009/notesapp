import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/chat_screen/components/bottom_message_bar.dart' show BottomMessageBar;
import 'package:notesapp/root/screens/chat_screen/components/chat_appbar.dart';
import 'package:notesapp/root/screens/chat_screen/components/message_bubble.dart' show MessageBubble;

class ChatScreen extends ConsumerStatefulWidget {
  final Chat? chat;
  const ChatScreen({super.key, this.chat});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {

  List<Message> dummyMessages = [
    Message(
      text: "How does Grid Computing work? Explain its Working with an appropriate Diagram.",
      time: DateTime.now(),
      isSender: false,
      type: Mediatype.text,
    ),
    Message(
      text: "See this diagram.",
      time: DateTime.now(),
      isSender: true,
      type: Mediatype.text,
    ),
  ];

  void _sendMessage(String text) {
    setState(() {
      // dummyMessages.add(Message(text: text, time: DateTime.now()));
      widget.chat!.messages.add(Message(text: text, time: DateTime.now()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final Chat currentChat = widget.chat ?? Chat.emptyChat();
    bool isChatEmpty = currentChat.messages.length == 1;
    return PopScope(
      onPopInvokedWithResult: (didPop, context) {
        final chatNotifier = ref.read(chatListProvider.notifier);
        if (isChatEmpty) {
          chatNotifier.removeChat(currentChat);
        }
      },

      child: Scaffold(
        body: Container(
          height: ThemeConstants.screenHeight,
          width: ThemeConstants.screenWidth,
          decoration: BoxDecoration(gradient: Gradients.lightBackground),
          child: Column(
            children: [
              ChatAppBar(
                title: currentChat.title!,
                lastEdited: currentChat.messages.isNotEmpty
                        ? currentChat.messages.last.time
                        : DateTime.now(),
                onTitleTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => ChatDetailScreen(chat: currentChat)));
                },
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: ThemeConstants.screenWidth * 0.03,
                  ),
                  children:
                      currentChat.messages.isNotEmpty
                          ? currentChat.messages
                              .map((message) => MessageBubble(message: message))
                              .toList()
                          : 
                          [
                            Center(
                              child: Text(
                                "No messages yet.",
                                style: TextStyle(
                                  color: ThemeConstants.homeSubtitleLight,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                ),
              ),
              BottomMessageBar(
                screenWidth: ThemeConstants.screenWidth,
                onEmojiTap: () {
                  print("Emoji tapped"); // Placeholder
                },
                onAttachmentTap: () {
                  print("Attachment tapped"); // Placeholder
                },
                onMicTap: () {
                  print("Microphone tapped"); // Placeholder
                },
                onSend: (text) => _sendMessage(text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
