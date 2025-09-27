import 'package:chat_bubbles/bubbles/bubble_special_one.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/core/extensions/message_list_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/rebuild_counter.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_3.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/date_chip.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';


// Gives you a single message by isarId
final messageProvider = Provider.family<Message, int>((ref, int id) {
  final messages = ref.watch(chatMessagesController);
  return messages.firstWhere((m) => m.isarId == id);
});


class MessageListWrapper extends ConsumerWidget {
  final String chatTitle;
  const MessageListWrapper({super.key, required this.chatTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatMessagesController.notifier);
    // final messages = ref.watch(chatMessagesController);
    final messages = ref.read(chatMessagesController);
    final messageCount = ref.watch( chatMessagesController.select((list) => list.length), );

    if (messageCount == 0) {
      return const NothingToSee();
    }

    return ScrollablePositionedList.builder(
      itemScrollController: notifier.itemScrollController,
      itemPositionsListener: notifier.itemPositionsListener,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      addAutomaticKeepAlives: true,
      itemCount: messageCount + 1,
      itemBuilder: (context, index) {
        if (index == messageCount) {
          return const SizedBox(height: 150);
        }

        final id = messages[index].isarId;

        // 1. Watch the message itself
       final message = ref.watch(messageProvider(id));

        // 2. Watch only this message’s highlight state
        final isHighlighted = ref.watch(
          chatMessagesController.notifier.select((n) => n.isHighlighted(id)),
        );

        final info = messages.layoutInfo(index);

        return Column(
          children: [
            if (info.showDateChip) DateChip(message.time),
            MessageBubble(
              key: ValueKey(message.id),
              style: BubbleStyle.opaque,
              message: message,
              isSelecting: notifier.isSelecting,
              isHighlighted: isHighlighted,
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
                  menuItems: messageHoldOptions(isImage: message.isImage),
                  triangleHorizontalOffset: message.isSender ? 120 : 40,
                  onSelected: (val) =>
                      notifier.handleMessageMenuAction(val, message),
                );
              },
              onReplyTap: () => notifier.scrollToMessage(message.replyingTo.value!.isarId),
            ),
          ],
        );
      },
    );
  }
}
