import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/presentation/screens/Chat_Detail/screens/chat_detail_screen_divided.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/components/chat_appbar.dart';

class ChatAppBarWrapper extends ConsumerStatefulWidget {
  const ChatAppBarWrapper({super.key});

  @override
  ConsumerState<ChatAppBarWrapper> createState() => _ChatAppBarWrapperState();
}

class _ChatAppBarWrapperState extends ConsumerState<ChatAppBarWrapper> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint("🔃 Chat App Bar rebuilt");

    final chatController = ref.watch(chatStateController.notifier);


    final isSearching = ref.watch(chatStateController.select((s) => s.isSearching));
    final isSelecting = ref.watch(chatStateController.select((s) => s.isSelecting));
    final isEditing = ref.watch(chatStateController.select((s) => s.isEditing));
    final selectedCount = ref.watch(chatStateController.select((s) => s.selectedMessages.length));
    final lastEdited = ref.watch(chatStateController.select((s) => s.messages.isNotEmpty ? s.messages.last.time : DateTime.now()));

    final chat = ref.watch(chatListProvider).selectedChat;
    final chatTitle = chat?.title ?? "New Note";
    final chatPhoto = chat?.chatPhotoPath;

    return AbsorbPointer(
      absorbing: isEditing,
      child: ChatAppBar(
        chatPhotoPath: chatPhoto,
        leading: isSelecting
            ? IconButton(
                onPressed: chatController.unSelectAllMessages,
                icon: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: isEditing ? 0.25 : 1,
                  child: Icon(
                    Icons.clear,
                    color: ThemeConstants.iconColorNeutral,
                  ),
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
            ? (isEditing ? "Editing Note" : "$selectedCount Notes selected")
            : chatTitle,
        onTitleTap: () {
          if (chat != null) {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => ChatDetailScreenDivided(chat: chat)),
            );
          }
        },
        onSearchTap: chatController.toggleSearch,
        showActionsIcon: !isSearching,
        onOptionsPressed: (value) => chatController.handleChatScreenOptions(value, chat!),
        actions: isSelecting
            ? [
                IconButton(
                  onPressed: chatController.deleteSelected,
                  icon: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: isEditing ? 0.25 : 1,
                    child: const Icon(Icons.delete_outline_rounded)),
                ),
              ]
            : null,
      ),
    );
  }
}
