import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/wrappers/chat_appbar_wrapper.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/wrappers/chat_searchbar.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/wrappers/overlays/overlay_handler.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/wrappers/message_list_wrapper.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/wrappers/bottom_message_bar_wrapper.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/wrappers/emoji_board_wrapper.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/components/auto_hide_scroll_to_bottom.dart';

class ChatScreenGlassBody extends ConsumerWidget {
  const ChatScreenGlassBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatStateController.notifier);
    final backgroundGradient = context.isLight
        ? Gradients.lightBackground
        : Gradients.darkChatBackground;

    return GestureDetector(
      onTap: () {
        notifier.stopSearching();
        notifier.searchFocusNode.unfocus();
        notifier.keyboardFocusNode.unfocus();
        notifier.hideEmojiPicker();
        notifier.unSelectAllMessages();
        ref.read(overlayHandlerProvider).closeAttachmentBoard();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1️⃣ Clear background
            Image.asset(
              "assets/backgrounds/abstract_blue.jpg",
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // 2️⃣ Foreground chat layout (no individual blurs)
            Column(
              children: const [
                ChatAppBarWrapper(),
                ChatSearchBar(),
                MessageListWrapper(),
                BottomMessageBarWrapper(),
                EmojiBoardWrapper(),
              ],
            ),
          ],
        ),

        // Floating Action Button (same logic)
        floatingActionButton: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(chatStateController);

            if (state.showEmojis ||
                state.isSearching ||
                state.messages.isEmpty) {
              return const SizedBox.shrink();
            }

            return AutoHideScrollToBottom(
              itemScrollController: notifier.itemScrollController,
              itemPositionsListener: notifier.itemPositionsListener,
              lastIndex: state.messages.length - 1,
              bottomPadding: notifier.isReplying ? 135 : 80,
              backgroundColor: context.isLight
                  ? const Color(0xFFD5F0FF)
                  : const Color(0xFF94C1DB),
            );
          },
        ),
      ),
    );
  }
}
