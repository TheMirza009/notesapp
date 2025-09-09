import 'dart:io';

import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/chat_list_extension.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/chat_screen/components/bottom_message_bar.dart' show BottomMessageBar;
import 'package:notesapp/root/screens/chat_screen/components/chat_appbar.dart';
import 'package:notesapp/root/screens/chat_screen/components/message_bubble.dart' show MessageBubble;
import 'package:notesapp/root/widgets/custom_context_menu.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
import 'package:svg_flutter/svg.dart';

class ChatScreen extends ConsumerWidget {
  final String chatId; // only keep ID, not Chat
  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Declarations 
    final List<Chat> chatList = ref.watch(chatListProvider);
    final Chat currentChat = chatList.getChatByID(chatId);
    final bool isChatEmpty = currentChat.messages.isEmpty;
    final ChatListNotifier chatListNotifier = ref.read(chatListProvider.notifier);
    LinearGradient backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;

    // Functions
    void sendMessage(String text) {
      const initText = "This is a new chat. Start typing to create your first note.";
      final newMessage = Message(text: text, time: DateTime.now()); // Create new message
      final updatedMessages = currentChat.messages.removeMessageWithText(initText); // Remove init message if it exists

      // Add new message
      final updatedChat = currentChat.copyWith(
        messages: [...updatedMessages, newMessage],
        preview: newMessage.text,
        date: newMessage.time,
      );
      
      // update globally ✅
      chatListNotifier.updateChat(updatedChat); 
    }


    void toggleSender(Message message) {
      if (message.id == null) return; // Early return on null
      final updatedMessages = currentChat.messages.toggleSenderById( message.id! ); // Call extension method
      final updatedChat = currentChat.copyWith(messages: updatedMessages); // Create updated list
      chatListNotifier.updateChat(updatedChat); // ✅ update globally
    }

    void deleteMessage(Message message) {
      if (message.id == null) return;
      final updatedMessages = currentChat.messages.removeMessageById(message.id!);
      final updatedChat = currentChat.copyWith(messages: updatedMessages);
      chatListNotifier.updateChat(updatedChat);
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, context) {
        if (isChatEmpty) {
          chatListNotifier.removeChat(currentChat);
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
                lastEdited: currentChat.messages.isNotEmpty ? currentChat.messages.last.time : DateTime.now(),
                onTitleTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => ChatDetailScreen(chat: currentChat)));
                },
                onOptionsPressed: () {
                  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

                  showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      10,
                      200, // left & top
                      overlay.size.width - 10, // right
                      overlay.size.height - 200, // bottom
                    ),
                    items: [
                      const PopupMenuItem<String>(
                        value: "data",
                        child: Text("Data"),
                      ),
                      const PopupMenuItem<String>(
                        value: "settings",
                        child: Text("Settings"),
                      ),
                    ],
                  ).then((value) {
                    if (value != null) {
                      print("Selected: $value");
                    }
                  });
                }

              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: ThemeConstants.screenWidth * 0.03,
                  ),
                  children:
                      currentChat.messages.isNotEmpty
                          ? currentChat.messages.map((message) {
                            // return DateChip(date: message.time, ); 
                            // BubbleSpecialOne(text: message.text, isSender: message.isSender, color: ThemeConstants.senderBlue, );
                            return MessageBubble(
                              message: message,
                              onTap: () => toggleSender(message),
                              onDeleteMessage: () => deleteMessage(message),
                              );
                          }).toList()
                          : 
                          [
                            NothingToSee()
                          ],
                ),
              ),
              BottomMessageBar(
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
