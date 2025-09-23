import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/core/extensions/message_list_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_2.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_3.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/date_chip.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/ripple_menu.dart';
import 'package:notesapp/root/screens/chat_screen/components/bottom_message_bar.dart' show BottomMessageBar;
import 'package:notesapp/root/screens/chat_screen/components/chat_appbar.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu_2.dart';
import 'package:notesapp/root/widgets/glass_container.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
import 'package:svg_flutter/svg.dart';
import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';

class ChatScreen extends ConsumerWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatMessagesController.notifier);
    final messages = ref.watch(chatMessagesController);
    final selectedChat = ref.watch(chatListProvider).selectedChat;
    String chatTitle = selectedChat!.title ?? "New Note";
    String? chatPhoto = selectedChat.chatPhotoPath; // Chat Photo reception

    final backgroundGradient =  context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;
    String imageURL1 = "https://downloadscdn6.freepik.com/23/2149338/2149337920.jpg?filename=close-up-colored-plant-leaf.jpg&token=exp=1757671394~hmac=ae1b322f07f0d05b06685f2df9830845&filename=2149337920.jpg";
    String imageURL2 = 'https://4kwallpapers.com/images/wallpapers/dark-blue-pink-3840x2160-12661.jpg';

    return PopScope(
      onPopInvokedWithResult: (didPop, context) {
        notifier.removeChatIfEmpty();
      },
      child: GestureDetector(
        onTap: () => notifier.unSelectAllMessages(),
        child: Scaffold(
          body: Container(
            height: ThemeConstants.screenHeight,
            width: ThemeConstants.screenWidth,
            decoration: BoxDecoration(gradient: backgroundGradient, 
            // image: DecorationImage(
            //   image: NetworkImage(imageURL2),
            //   fit: BoxFit.fitHeight,
            //   ),
            ),
            child: Column(
              children: [
                ChatAppBar(
                  chatPhotoPath: chatPhoto,
                  leading: notifier.isSelecting
                    ? IconButton(
                      onPressed: () => notifier.unSelectAllMessages(),
                      icon: Icon(Icons.clear, color: ThemeConstants.iconColorNeutral,),
                    )
                    : IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        },
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: ThemeConstants.iconColorNeutral,),
                    ),
                  lastEdited: messages.isNotEmpty ? messages.last.time : DateTime.now(),
                  isSelecting: notifier.isSelecting,
                  title: notifier.isSelecting ? "${notifier.selectCount()} Notes selected" : chatTitle,
                  onTitleTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => ChatDetailScreen(chat: chat),
                      ),
                    );
                  },
                  onSearchTap: () => print("notifier.loadFromDatabase()"),
                  onOptionsPressed: (value) {
                    notifier.handleChatScreenOptions(value, chat);
                  },
                  actions: notifier.isSelecting
                    ? [ IconButton(onPressed: () => notifier.deleteSelected(), icon: Icon(Icons.delete_outline_rounded))]
                    : null,
                ),
                Expanded(
                  child: messages.isEmpty 
                  ? NothingToSee() 
                  : ListView.builder(
                      padding: EdgeInsets.symmetric( horizontal: 0), // ThemeConstants.screenWidth * 0.03, ),
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return Container(
                            height: 150,
                            color: Colors.transparent,
                          );
                        }
                        
                        final message = messages[index];
                        final info = messages.layoutInfo(index);
                    
                        return Column(
                          children: [
                              if (info.showDateChip) DateChip(message.time),
                                MessageBubble(
                                  style: BubbleStyle.opaque,
                                  message: message,
                                  isSelecting: notifier.isSelecting,
                                  topPadding: info.topPadding,
                                  bottomPadding: info.bottomPadding,
                                  onTapWhileSelecting: () {
                                    message.isSelected
                                        ? notifier.unselectMessage(message)
                                        : notifier.selectMessage(message);
                                  },
                                  onTap: () {
                                      if (message.isImage) {
                                        final imageMessages =  messages.imageMedias;
                                        final initialIndex = imageMessages.indexOfMediaIsarID(message);
                                        print(message);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => GalleryViewWrapper(
                                              chatTitle: chatTitle,
                                              galleryItems: imageMessages,
                                              initialIndex: initialIndex,
                                            ),
                                          )
                                        );
                                      } else {
                                        message.isSender = !message.isSender;
                                        notifier.updateMessage(message);
                                      }
                                    },
                                  onLongPress: (pos) {
                                    notifier.selectMessage(message);
                                    CustomContextMenu.showMenuAt(
                                      context,
                                      position: pos,
                                      menuItems: messageHoldOptions(isImage: message.isImage),
                                      triangleHorizontalOffset: message.isSender ? 120 : 40,
                                      onSelected: (val) => notifier.handleMessageMenuAction(val, message),
                                    );
                                  },
                                ),
                          ],
                        );
                      },
                    ),
                ),

                BottomMessageBar(
                  onEmojiTap: () => debugPrint("Emoji tapped"),
                  onAttachmentTap: () => notifier.pickImage(),
                  onMicTap: () => debugPrint("notifier.state"),
                  onSend: (txt) => notifier.sendMessage(txt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageContextMenu(
    BuildContext context,
    Offset details,
    Message message,
    VoidCallback onDeleteMessage,
  ) {
    CustomContextMenu2(
      position: details,
      items: [MenuItem.text("Delete", onDeleteMessage)],
    ).show(context);
  }
}
