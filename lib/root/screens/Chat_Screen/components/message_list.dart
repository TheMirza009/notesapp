import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/core/extensions/message_list_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/date_chip.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/message_bubble/message_bubble.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MessageListWrapper extends ConsumerWidget {
  const MessageListWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatStateController.notifier);
    final messages = ref.watch( chatStateController.select((s) => s.messages));

  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //   if (notifier.itemScrollController.isAttached && messages.isNotEmpty) {
  //     notifier.itemScrollController.jumpTo(index: messages.length - 1);
  //   }
  // });

    return Expanded(
      child: messages.isEmpty
          ? const NothingToSee()
          : ScrollablePositionedList.builder(
              itemScrollController: notifier.itemScrollController,
              itemPositionsListener: notifier.itemPositionsListener,
              itemCount: messages.length + 1,
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const SizedBox(height: 150);
                }

                final messageId = messages[index].isarId; // 👈 use either IsarID or UUID not index
                return ProviderScope(
                  overrides: [
                    messageIdProvider.overrideWith((_) => messageId),
                  ],
                  child: const _MessageItemBuilder(),
                );
              },
            ),
    );
  }
}

// Provide the ID instead of index
final messageIdProvider = Provider<int>((_) => throw UnimplementedError());

class _MessageItemBuilder extends ConsumerWidget {
  const _MessageItemBuilder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageId = ref.read(messageIdProvider);

    // 👇 Watch only this message
    // Find this message by ID instead of index
    final Message? message = ref.watch(
      chatStateController.select<Message?>((state) {
        return state.messages.cast<Message?>().firstWhere(
          (message) => message!.isarId == messageId,
          orElse: () => null,
        );
      }),
    );

    if (message == null) {
      return const SizedBox.shrink(); // Message got deleted -> don't render
    }

    // 👇 Watch only derived info for this index
    final info = ref.watch( chatStateController.select((s) => s.messages.layoutInfoById(messageId)));
    final isHighlighted = ref.watch( chatStateController.select((s) => s.highlightedMessage?.isarId == messageId), );
    final isSelected = ref.watch( chatStateController.select((s) => s.selectedMessages.any((m) => m.isarId == messageId)), );
    final isSelecting = ref.watch( chatStateController.select((s) => s.isSelecting), );

    print("🔃 Built message: ${message.text}");

    return Column(
      children: [
        if (info.showDateChip) DateChip(message.time),
        RepaintBoundary(
          child: MessageBubble(
            key: ValueKey(message.id),
            style: BubbleStyle.opaque,
            message: message,
            isSelecting: isSelecting,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            topPadding: info.topPadding,
            bottomPadding: info.bottomPadding,

            // interactions
            onSwipe: () => ref.read(chatStateController.notifier).setAnchorMessage(message),
            onTapWhileSelecting: () => isSelected
                ? ref.read(chatStateController.notifier).unselectMessage(message)
                : ref.read(chatStateController.notifier).selectMessage(message),
            onTap: () {
              if (message.isImage) {
                final allImages = ref.read(chatStateController).messages.imageMedias;
                final initialIndex = allImages.indexOfMediaIsarID(message);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GalleryViewWrapper(
                      galleryItems: allImages,
                      initialIndex: initialIndex,
                    ),
                  ),
                );
              } else {
                final notifier = ref.read(chatStateController.notifier);
                notifier.toggleSender(message);
                // message.isSender = !message.isSender;
                // notifier.updateMessage(message);
              }
            },
            onLongPress: (pos) {
              final notifier = ref.read(chatStateController.notifier);
              notifier.selectMessage(message);
              notifier.searchFocusNode.unfocus();
              notifier.keyboardFocusNode.unfocus();
              CustomContextMenu.showMenuAt(
                context,
                position: pos,
                menuItems: messageHoldOptions(isImage: message.isImage),
                triangleHorizontalOffset: message.isSender ? 120 : 40,
                onSelected: (val) => notifier.handleMessageMenuAction(val, message),
              );
            },
            onReplyTap: () => ref.read(chatStateController.notifier).scrollToMessage(message.replyingTo.value!.isarId),
          ),
        ),
      ],
    );
  }
}
