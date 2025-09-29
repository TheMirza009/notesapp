
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_3.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/auto_hide_scroll_to_bottom.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/components/anchor_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/components/bottom_message_bar_optim.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/components/chat_appbar_optim.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/components/chat_searchbar.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/components/emoji_board_optim.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/components/message_list.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';

//TODO: 1. GalleryWrapper cannot see Chat Title.
//TODO: 2. Notifier needs robustness and double checks
//TODO: 3. Chat Screen still rebuilds every time.
//TODO: 4. Scroll-To-Bottom button still appears above Emojiboard 
//TODO: 5. Sending a message rebuilds the appbar.
//TODO: 5. Full-sized images being shown as thumbnails
//TODO: 6. Everything rebuilds when the long press is called

class ChatScreenOptimized extends ConsumerWidget {
  final Chat chat;
  const ChatScreenOptimized({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final notifier = ref.read(chatMessagesController.notifier);
    final notifier = ref.read(chatStateController.notifier);
    final canPop = ref.read(chatStateController.select((s) => !s.isSearching && !s.showEmojis));
    final backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;

    debugPrint("🔃 ChatScreen rebuilt");

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
    final state = ref.read(chatStateController);
    final notifier = ref.read(chatStateController.notifier);

    // intercept back button
    if (state.showEmojis) {
      notifier.hideEmojiPicker();
      return; // prevent popping
    }

    if (state.isSearching) {
      notifier.stopSearching();
      return; // prevent popping
    }

    // ✅ nothing to intercept → allow pop
    notifier.unSelectAllMessages();
    notifier.clearAnchorMessage();
    notifier.removeChatIfEmpty();
  },
      child: GestureDetector(
        onTap: () {
          notifier.stopSearching();
          notifier.searchFocusNode.unfocus();
          notifier.keyboardFocusNode.unfocus();
          notifier.hideEmojiPicker();
          notifier.unSelectAllMessages();
        },
        child: Scaffold(
          // ✅ Scaffold provides background, don’t wrap in another Container
          body: Container(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: Column(
              children: [
                const ChatAppBarWrapper(),
                const ChatSearchBar(),
                const MessageList(),
                const AnchorWrapperOptimized(),
                const BottomMessageBarOptimized(),
                const EmojiBoardWrapper(),
              ],
            ),
          ),
          floatingActionButton: Consumer(
            builder: (context, ref, _) {
              final messages = ref.watch(chatStateController.select((s) => s.messages));
              return AutoHideScrollToBottom(
                itemScrollController: notifier.itemScrollController,
                itemPositionsListener: notifier.itemPositionsListener,
                lastIndex: messages.isNotEmpty ? messages.length - 1 : 0,
                bottomPadding: notifier.isReplying ? 135 : 80,
                backgroundColor: context.isLight
                    ? const Color(0xFFD5F0FF)
                    : const Color(0xFF94C1DB),
              );
            },
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
