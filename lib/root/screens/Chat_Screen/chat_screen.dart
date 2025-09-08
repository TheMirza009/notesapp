import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/chat_list_extension.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
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
    final bool isChatEmpty = currentChat.messages.isEmpty;
    final ChatListNotifier chatNotifier = ref.read(chatListProvider.notifier);
    LinearGradient backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;

    // Functions
    void sendMessage(String text) {
      final Message newMessage = Message(text: text, time: DateTime.now());
      final initMessage = currentChat.messages.getMessageByText(
        "This is a new chat. Start typing to create your first note.",
      );
      final updatedMessages = currentChat.messages.where((message) => message != initMessage) .toList();
      final updatedChat = currentChat.copyWith(
        messages: [...updatedMessages, newMessage],
        preview: newMessage.text,
        date: newMessage.time,
      );
      chatNotifier.updateChat(updatedChat); // update globally ✅
    }

    void toggleSender(Message message) {
      final Message? msgToUpdate = currentChat.messages.getMessageByTime(
        message.time,
      );
      if (msgToUpdate != null) {
        final updatedMessages = currentChat.messages.map((message) {
              if (message.time == msgToUpdate.time) {
                return message.copyWith(isSender: !message.isSender);
              }
              return message;
            }).toList();
        final updatedChat = currentChat.copyWith(messages: updatedMessages);
        chatNotifier.updateChat(updatedChat);
      }
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
          decoration: BoxDecoration(gradient: backgroundGradient),
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
                          ? currentChat.messages.map((message) {
                            return MessageBubble(
                              message: message,
                              onTap: () => toggleSender(message),
                              );
                          }).toList()
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
