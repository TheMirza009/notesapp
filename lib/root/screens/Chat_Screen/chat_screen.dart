import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_extension.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/chat_screen/components/bottom_message_bar.dart' show BottomMessageBar;
import 'package:notesapp/root/screens/chat_screen/components/chat_appbar.dart';
import 'package:notesapp/root/screens/chat_screen/components/message_bubble.dart' show MessageBubble;

class ChatScreen extends ConsumerWidget {
  final String chatId; // only keep ID, not Chat
  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Declarations 
    final List<Chat> chatList = ref.watch(chatListProvider);
    final Chat currentChat = chatList.getChatByID(chatId);
    final bool isChatEmpty = currentChat.messages.length == 1;
    final ChatListNotifier chatNotifier = ref.read(chatListProvider.notifier);

    // Functions
    void sendMessage(String text) {
      final Message newMessage = Message(text: text, time: DateTime.now());
      final updatedChat = currentChat.copyWith(
        messages: [...currentChat.messages, newMessage],
        preview: newMessage.text,
        date: newMessage.time,
      );
      chatNotifier.updateChat(updatedChat); // update globally ✅
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, context) {
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
                onSend: (text) => sendMessage(text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
