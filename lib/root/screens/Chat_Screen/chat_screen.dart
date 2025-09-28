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
import 'package:notesapp/root/screens/Chat_Screen/components/auto_hide_scroll_to_bottom.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/date_chip.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/emoji_board.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/ripple_menu.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/wrappers/anchor_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/notifier/chat_state_notifier.dart';
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
    // Using the new ChatStateNotifier
    final chatController = ref.read(chatStateController.notifier);
    final chatState = ref.watch(chatStateController);

    final selectedChat = ref.watch(chatListProvider).selectedChat;
    final chatTitle = selectedChat?.title ?? "New Note";
    final chatPhoto = selectedChat?.chatPhotoPath;

    final headerColor =
        context.isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
    final backgroundGradient =
        context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;

    print("🔃 ChatScreen rebuilt");

    return PopScope(
      canPop: !chatState.isSearching && !chatState.showEmojis,
      onPopInvokedWithResult: (didPop, context) {
        chatController.closeSearchAndKeyboard();
        chatController.unSelectAllMessages();
        chatController.clearAnchorMessage();
        chatController.removeChatIfEmpty();
      },
      child: GestureDetector(
        onTap: () {
          chatController.closeSearchAndKeyboard();
          chatController.unSelectAllMessages();
        },
        child: Container(
          height: ThemeConstants.screenHeight,
          width: ThemeConstants.screenWidth,
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: (chatState.isSearching && chatState.showEmojis)
                ? null
                : AutoHideScrollToBottom(
                    itemScrollController: chatController.itemScrollController,
                    itemPositionsListener: chatController.itemPositionsListener,
                    lastIndex: chatState.messages.length - 1,
                    bottomPadding: chatController.isReplying ? 135 : 80,
                    backgroundColor: context.isLight
                        ? const Color(0xFFD5F0FF)
                        : const Color(0xFF94C1DB),
                  ),
            body: Column(
              children: [
                /// Chat App Bar
                RebuildCounter(
                  name: "Appbar",
                  child: ChatAppBar(
                    chatPhotoPath: chatPhoto,
                    leading: chatState.isSelecting
                        ? IconButton(
                            onPressed: chatController.unSelectAllMessages,
                            icon: Icon(Icons.clear,
                                color: ThemeConstants.iconColorNeutral),
                          )
                        : IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back_ios_new_rounded,
                                color: ThemeConstants.iconColorNeutral),
                          ),
                    lastEdited: chatState.messages.isNotEmpty
                        ? chatState.messages.last.time
                        : DateTime.now(),
                    isSelecting: chatState.isSelecting,
                    title: chatState.isSelecting
                        ? "${chatState.selectedMessages.length} Notes selected"
                        : chatTitle,
                    onTitleTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => ChatDetailScreen(chat: chat),
                        ),
                      );
                    },
                    onSearchTap: chatController.toggleSearch,
                    showActionsIcon: !chatState.isSearching,
                    onOptionsPressed: (value) => chatController.handleChatScreenOptions(value, chat),
                    actions: chatState.isSelecting
                        ? [
                            IconButton(
                              onPressed: chatController.deleteSelected,
                              icon: Icon(Icons.delete_outline_rounded),
                            )
                          ]
                        : null,
                  ),
                ),

                /// Chat Searchbar
                RebuildCounter(
                  name: "Searchbar",
                  child: AnimatedSize(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOutQuint,
                    child: chatState.isSearching
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 40),
                              child: SearchBar(
                                focusNode: chatController.searchFocusNode,
                                controller: chatController.searchController,
                                autoFocus: false,
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                shadowColor:
                                    WidgetStatePropertyAll(Colors.transparent),
                                backgroundColor:
                                    WidgetStatePropertyAll(headerColor),
                                leading: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Icon(Icons.search,
                                      color: ThemeConstants.iconLight),
                                ),
                                trailing: [
                                  if (chatController.searchController.text.isNotEmpty)
                                    IconButton(
                                        onPressed: chatController.clearSearch,
                                        icon: Icon(Icons.clear_rounded))
                                ],
                                hintText: "Search in notes...",
                                hintStyle: WidgetStatePropertyAll(
                                  TextStyle(
                                      color: ThemeConstants.iconLight,
                                      fontWeight: FontWeight.w500),
                                ),
                                onChanged: chatController.searchChats,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                /// Messages List
                Expanded(
                  child: chatState.messages.isEmpty
                      ? const NothingToSee()
                      : ScrollablePositionedList.builder(
                          itemScrollController: chatController.itemScrollController,
                          itemPositionsListener: chatController.itemPositionsListener,
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          addAutomaticKeepAlives: true,
                          itemCount: chatState.messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == chatState.messages.length) {
                              return Container(
                                height: 150,
                                color: Colors.transparent,
                              );
                            }

                            final message = ref.watch(
                              chatStateController.select(
                                (s) => s.messages[index],
                              ),
                            );

                            final isHighlighted = ref.watch(
                              chatStateController.select(
                                  (s) => s.highlightedMessage?.isarId == message.isarId),
                            );

                            final info = chatState.messages.layoutInfo(index);

                            return Column(
                              children: [
                                if (info.showDateChip) DateChip(message.time),
                                RepaintBoundary(
                                  child: MessageBubble(
                                    key: ValueKey(message.id),
                                    style: BubbleStyle.opaque,
                                    message: message,
                                    isSelecting: chatState.isSelecting,
                                    isHighlighted: isHighlighted,
                                    topPadding: info.topPadding,
                                    bottomPadding: info.bottomPadding,
                                    onSwipe: () =>
                                        chatController.setAnchorMessage(message),
                                    onTapWhileSelecting: () {
                                      chatState.isSelected(message)
                                          ? chatController.unselectMessage(message)
                                          : chatController.selectMessage(message);
                                    },
                                    onTap: () {
                                      if (message.isImage) {
                                        final imageMessages =
                                            chatState.messages.imageMedias;
                                        final initialIndex =
                                            imageMessages.indexOfMediaIsarID(message);

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
                                        chatController.toggleSender(message);
                                      }
                                    },
                                    onLongPress: (pos) {
                                      chatController.selectMessage(message);
                                      chatController.searchFocusNode.unfocus();
                                      CustomContextMenu.showMenuAt(
                                        context,
                                        position: pos,
                                        menuItems:
                                            messageHoldOptions(isImage: message.isImage),
                                        triangleHorizontalOffset:
                                            message.isSender ? 120 : 40,
                                        onSelected: (val) => chatController
                                            .handleMessageMenuAction(val, message),
                                      );
                                    },
                                    onReplyTap: () => chatController
                                        .scrollToMessage(message.replyingTo.value!.isarId),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                /// Anchor Wrapper
                RebuildCounter(
                  name: "Anchor Wrapper",
                  child: RepaintBoundary(
                    child: AnchorWrapper(
                      text: chatState.anchorMessage?.text,
                      media: chatState.anchorMessage?.media.value,
                      onClear: chatController.clearAnchorMessage,
                    ),
                  ),
                ),

                /// Message Bar
                RebuildCounter(
                  name: "Message bar",
                  child: BottomMessageBar(
                    focusNode: chatController.keyboardFocusNode,
                    keyboardController: chatController.keyboardController,
                    onFieldTap: chatController.hideEmojiPicker,
                    onEmojiTap: chatController.toggleEmojiPicker,
                    onAttachmentTap: chatController.pickImage,
                    onMicTap: () => debugPrint("Mic tapped"),
                    onSend: chatController.sendMessage,
                    onImagePasted: (bytes) => chatController.pickImage(imageBytes: bytes),
                  ),
                ),

                /// Emoji Board
                RebuildCounter(
                  name: "Emoji board",
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: chatState.showEmojis ? 280 : 0,
                        child: EmojiBoard(
                          showEmojis: chatState.showEmojis,
                          textController: chatController.keyboardController,
                          keyboardHeight: 280,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
