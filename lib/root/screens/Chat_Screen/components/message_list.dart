import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
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
    final isLoading = ref.watch(chatStateController.notifier).isLoading;

  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //   if (notifier.itemScrollController.isAttached && messages.isNotEmpty) {
  //     notifier.itemScrollController.jumpTo(index: messages.length - 1);
  //   }
  // });

    return Expanded(
      child: isLoading ? _LoadIndicator() : messages.isEmpty
          ? const NothingToSee()
          : ScrollablePositionedList.builder(
              itemScrollController: notifier.itemScrollController,
              itemPositionsListener: notifier.itemPositionsListener,
              itemCount: messages.length + 1,
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const SizedBox(key: ValueKey('padding'), height: 150);
                }

                final message = messages[index]; // 👈 Get the message directly
                return ProviderScope(
                  overrides: [
                    // messageIdProvider.overrideWith((_) => messageId),
                    messageProvider.overrideWithValue(message), // 👈 Pass the message instead of finding it later
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
final messageProvider = Provider<Message>((_) => throw UnimplementedError());

class _MessageItemBuilder extends ConsumerWidget {
  const _MessageItemBuilder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(messageProvider);

    if (message == null) {
      return const SizedBox.shrink(); // Message got deleted -> don't render
    }

    if (message.isImage) {
      final path = message.media.value?.path;
      if (path != null) {
        precacheImage(ExtendedFileImageProvider(File(path), cacheRawData: true), context);
      }
    }

    // 👇 Watch only derived info for this index
    final info = ref.watch( chatStateController.select((s) => s.messages.layoutInfoById(message.isarId)));
    final isHighlighted = ref.watch( chatStateController.select((s) => s.highlightedMessage?.isarId == message.isarId), );
    final isSelected = ref.watch( chatStateController.select((s) => s.selectedMessages.any((m) => m.isarId == message.isarId)), );
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


class _LoadIndicator extends StatelessWidget {
  const _LoadIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter, // 👈 top center instead of center
      child: Padding(
        padding: const EdgeInsets.only(top: 50), // optional spacing from top
        child: SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            strokeCap: StrokeCap.round,
            color: context.isLight
                ? ThemeConstants.sacredSeed
                : ThemeConstants.sinisterSeed,
          ),
        ),
      ),
    );
  }
}
