import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/chat_appbar.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/notifier/chat_state.dart';

class ChatAppBarWrapper extends ConsumerWidget {
  const ChatAppBarWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("🔃 Chat App Bar rebuilt");

    final chatController = ref.watch(chatStateController.notifier);


    final isSearching = ref.watch(chatStateController.select((s) => s.isSearching));
    final isSelecting = ref.watch(chatStateController.select((s) => s.isSelecting));
    final selectedCount = ref.watch(chatStateController.select((s) => s.selectedMessages.length));
    final lastEdited = ref.watch(chatStateController.select((s) => s.messages.isNotEmpty ? s.messages.last.time : DateTime.now()));

    final chat = ref.watch(chatListProvider).selectedChat;
    final chatTitle = chat?.title ?? "New Note";
    final chatPhoto = chat?.chatPhotoPath;

    return ChatAppBar(
      chatPhotoPath: chatPhoto,
      leading: isSelecting
          ? IconButton(
              onPressed: chatController.unSelectAllMessages,
              icon: Icon(
                Icons.clear,
                color: ThemeConstants.iconColorNeutral,
              ),
            )
          : IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: ThemeConstants.iconColorNeutral,
              ),
            ),
      lastEdited: lastEdited,
      isSelecting: isSelecting,
      title: isSelecting
          ? "$selectedCount Notes selected"
          : chatTitle,
      onTitleTap: () {
        if (chat != null) {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => ChatDetailScreen(chat: chat)),
          );
        }
      },
      onSearchTap: chatController.toggleSearch,
      showActionsIcon: isSearching,
      onOptionsPressed: (value) => chatController.handleChatScreenOptions(value, chat!),
      actions: isSelecting
          ? [
              IconButton(
                onPressed: chatController.deleteSelected,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ]
          : null,
    );
  }
}
