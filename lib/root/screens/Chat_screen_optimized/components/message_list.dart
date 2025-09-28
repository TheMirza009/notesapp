import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/core/extensions/message_list_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_3.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/date_chip.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/chat_screen_optimized.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';


final Provider<int> indexProvider = Provider<int>((_) => 0);

class MessageList extends ConsumerWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("🔄 Message list rebuilt");

    final notifier = ref.read(chatStateController.notifier);

    // Only rebuild when message list changes length/content
    final messages = ref.watch(chatStateController.select((s) => s.messages));

    return Expanded(
      child: messages.isEmpty ? NothingToSee() : ScrollablePositionedList.builder(
        itemScrollController: notifier.itemScrollController,
        itemPositionsListener: notifier.itemPositionsListener,
        itemCount: messages.length + 1,
        itemBuilder: (context, index) {
          if (index == messages.length) return const SizedBox(height: 150);
      
          return ProviderScope(
            overrides: [indexProvider.overrideWith((_) => index)],
            child: const _MessageItemBuilder());
        },
      ),
    );
  }
}

class _MessageItemBuilder extends ConsumerWidget {
  const _MessageItemBuilder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.read(indexProvider);

    // 👇 Watch only this message
    final message = ref.watch( chatStateController.select((s) => s.messages[index]), );

    // 👇 Watch only derived info for this index
    final info = ref.watch( chatStateController.select((s) => s.messages.layoutInfo(index)), );
    final isHighlighted = ref.watch( chatStateController.select((s) => s.highlightedMessage?.isarId == message.isarId), );
    final isSelected = ref.watch( chatStateController.select((s) => s.isSelected(message)), );
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
                message.isSender = !message.isSender;
                notifier.updateMessage(message);
              }
            },
            onLongPress: (pos) {
              final notifier = ref.read(chatStateController.notifier);
              notifier.selectMessage(message);
              notifier.searchFocusNode.unfocus();
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
