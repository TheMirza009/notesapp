import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
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
import 'package:notesapp/core/utils/rebuild_counter.dart';
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
import 'package:notesapp/root/screens/Chat_Screen/components/anchor_wrapper.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/auto_hide_scroll_to_bottom.dart';
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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';


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
    Color headerColor =  context.isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
    final backgroundGradient =  context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;
    String imageURL1 = "https://downloadscdn6.freepik.com/23/2149338/2149337920.jpg?filename=close-up-colored-plant-leaf.jpg&token=exp=1757671394~hmac=ae1b322f07f0d05b06685f2df9830845&filename=2149337920.jpg";
    String imageURL2 = 'https://4kwallpapers.com/images/wallpapers/dark-blue-pink-3840x2160-12661.jpg';

    return PopScope(
      canPop: !notifier.isSearching,
      onPopInvokedWithResult: (didPop, context) {
        notifier.isSearching = false;
        notifier.searchFocusNode.unfocus();
        notifier.unSelectAllMessages();
        notifier.clearAnchorMessage();
        notifier.removeChatIfEmpty();
      },
      child: GestureDetector(
        onTap: () {
          notifier.searchFocusNode.unfocus();
          notifier.unSelectAllMessages();
        },
        child: Scaffold(
          floatingActionButton: notifier.isSearching ? null : 
          AutoHideScrollToBottom(
            itemScrollController: notifier.itemScrollController,
            itemPositionsListener: notifier.itemPositionsListener,
            lastIndex: messages.length - 1,
            bottomPadding: notifier.isReplying ? 135 : 80,
            backgroundColor: context.isLight ? const Color(0xFFD5F0FF) : const Color(0xFF94C1DB),
          ),
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
                  onSearchTap: () => notifier.toggleSearch(),
                  showActionsIcon: !notifier.isSearching,
                  onOptionsPressed: (value) {
                    notifier.handleChatScreenOptions(value, chat);
                  },
                  actions: notifier.isSelecting
                    ? [ IconButton(onPressed: () => notifier.deleteSelected(), icon: Icon(Icons.delete_outline_rounded))]
                    : null,
                ),
        
                
                /// Chat Searchbar
                 AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOutQuint,
                  child: notifier.isSearching ? Padding(
                    padding: const EdgeInsets.only(left: 12.0, bottom: 0, right: 12, top: 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:notifier.isSearching ? 40 : 0,
                        // maxWidth: notifier.isSearching ? double.maxFinite : 0
                      ),
                      child: SearchBar(
                        focusNode: notifier.searchFocusNode,
                        controller: notifier.searchController,
                        autoFocus: false,
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12))),
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        shadowColor: WidgetStatePropertyAll(Colors.transparent),
                        backgroundColor: WidgetStatePropertyAll(headerColor),
                        leading: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.search, color: ThemeConstants.iconLight,),
                        ),
                        trailing: [notifier.searchController.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear_rounded), onPressed: notifier.clearSearch,) : SizedBox.shrink()] ,
                        hintText: "Search in notes...",
                        hintStyle: WidgetStatePropertyAll(TextStyle(color: ThemeConstants.iconLight, fontWeight: FontWeight.w500)),
                        onChanged: (value) => notifier.searchChats(value),
                      ),
                    ),
                  ) : SizedBox.shrink(),
                ),
        
        
                Expanded(
                  child: messages.isEmpty 
                  ? NothingToSee() 
                  : ScrollablePositionedList.builder(
                      itemScrollController: notifier.itemScrollController,
                      itemPositionsListener: notifier.itemPositionsListener,
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
                            RepaintBoundary(
                              child: MessageBubble(
                                key: ValueKey(message.id),
                                style: BubbleStyle.opaque,
                                message: message,
                                isSelecting: notifier.isSelecting,
                                isHighlighted: ref.watch( chatMessagesController.notifier.select( (c) => c.isHighlighted(message.isarId), ), ),
                                topPadding: info.topPadding,
                                bottomPadding: info.bottomPadding,
                                onSwipe: () => notifier.setAnchorMessage(message),
                                onTapWhileSelecting: () {
                                  message.isSelected
                                  ? notifier.unselectMessage(message)
                                  : notifier.selectMessage(message);
                                },
                                onTap: () {
                                  if (message.isImage) {
                                    final imageMessages = messages.imageMedias;
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
                                      ),
                                    );
                                  } else {
                                    message.isSender = !message.isSender;
                                    notifier.updateMessage(message);
                                  }
                                },
                                onLongPress: (pos) {
                                  notifier.selectMessage(message);
                                  notifier.searchFocusNode.unfocus();
                                  CustomContextMenu.showMenuAt(
                                    context,
                                    position: pos,
                                    menuItems: messageHoldOptions(
                                      isImage: message.isImage,
                                    ),
                                    triangleHorizontalOffset: message.isSender ? 120 : 40,
                                    onSelected: (val) => notifier.handleMessageMenuAction( val, message, ),
                                  );
                                },
                                onReplyTap: () => notifier.scrollToMessage(message.replyingTo.value!.isarId),
                                ),
                            ),
                            ],
                          );
                      },
                    ),
                ),
        
                AnchorWrapper(
                  text: notifier.anchorMessage?.text,
                  media: notifier.anchorMessage?.media.value,
                  onClear: notifier.clearAnchorMessage,
                ),
        
                BottomMessageBar(
                  focusNode: notifier.keyboardFocusNode,
                  keyboardController: notifier.keyboardController,
                  onEmojiTap: () => debugPrint("Emoji tapped"),
                  onAttachmentTap: () => notifier.pickImage(),
                  onMicTap: () => debugPrint("notifier.state"),
                  onSend: (txt) => notifier.sendMessage(txt),
                  onImagePasted: (imageBytes) => notifier.pickImage(imageBytes: imageBytes) ,
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
