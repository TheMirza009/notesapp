import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Chat_screen/components/anchor_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/components/bottom_message_bar_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/components/chat_appbar_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/components/chat_searchbar.dart';
import 'package:notesapp/root/screens/Chat_screen/components/emoji_board_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/components/message_list.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/auto_hide_scroll_to_bottom.dart';

//TODO: 2. Notifier needs robustness and double checks
//TODO: 5. Full-sized images being shown as thumbnails
//TODO: 6. Everything rebuilds when the long press is called
//TODO: 7. Search does not show new messages
//TODO: 8. First message does not change state.

final StateProvider<bool> isNewChat = StateProvider((_) => false);

class ChatScreen extends ConsumerWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final notifier = ref.read(chatMessagesController.notifier);
    final notifier = ref.read(chatStateController.notifier);
    final canPop = ref.watch( chatStateController.select((s) => !s.isSearching && !s.showEmojis));
    final backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;
    final newChat = ref.read(isNewChat);
    debugPrint("🔃 ChatScreen rebuilt");

    if (newChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatStateController.notifier).keyboardFocusNode.requestFocus();
        ref.read(isNewChat.notifier).state = false;
      });
    }

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
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: Column(
              children: [
                const ChatAppBarWrapper(),
                const ChatSearchBar(),
                const MessageListWrapper(),
                const AnchorWrapper(),
                const BottomMessageBarWrapper(),
                const EmojiBoardWrapper(),
              ],
            ),
          ),
          floatingActionButton: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(chatStateController);
              if (state.showEmojis || state.isSearching || state.messages.isEmpty) {
                return const SizedBox.shrink(); // hide FAB
              }

              return AutoHideScrollToBottom(
                itemScrollController: notifier.itemScrollController,
                itemPositionsListener: notifier.itemPositionsListener,
                lastIndex: state.messages.length - 1,
                bottomPadding: notifier.isReplying ? 135 : 80,
                backgroundColor: context.isLight ? const Color(0xFFD5F0FF) : const Color(0xFF94C1DB),
              );
            },
          ),
        ),
      ),
    );
  }
}
