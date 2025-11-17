import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_base_state.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/date_chip.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/message_bubble.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/overlays/overlay_handler.dart';
import 'package:notesapp/root/screens/Settings/notifier/settings_notifier.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';
import 'package:notesapp/root/widgets/video_view/video_gallery_player.dart';
import 'package:open_file/open_file.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MessageListWrapper extends ConsumerStatefulWidget {
  const MessageListWrapper({super.key});

  @override
  ConsumerState<MessageListWrapper> createState() => _MessageListWrapperState();
}

class _MessageListWrapperState extends ConsumerState<MessageListWrapper> 
  with AutomaticKeepAliveClientMixin {
  
  @override 
  bool get wantKeepAlive => true;

  bool _isInitialBuild = true; // ✅ Track first build only

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final notifier = ref.read(chatStateController.notifier);
    final messages = ref.watch(chatStateController.select((s) => s.messages));
    final isLoading = ref.watch(chatStateController.select((s) => s.isLoading));
    final shouldStartFromBottom = !(ref.read(settingsController)?.chatDisplayAscending ?? true);

    // ✅ Reset flag when loading (new chat selected)
    if (isLoading) {
      _isInitialBuild = true;
    }

    // Calculate initial index and alignment
    final int initialIndex;
    double initialAlignment = 0.0; // Default: align to top
    
    if (_isInitialBuild && !isLoading && messages.isNotEmpty && messages.length >= 3) {
      if (shouldStartFromBottom) {
        initialIndex = messages.length;
        initialAlignment = 0.8; // ✅ Align to BOTTOM of screen
      } else {
        initialIndex = 0;
        initialAlignment = 0.0; // Align to top
      }
      _isInitialBuild = false;
    } else {
      initialIndex = 0;
      initialAlignment = 0.0;
    }

    return Expanded(
      child: isLoading 
          ? const LoadIndicator() 
          : messages.isEmpty
              ? const NothingToSee()
              : AbsorbPointer(
                  absorbing: ref.watch(chatStateController.select((s) => s.isEditing)),
                  child: ScrollablePositionedList.builder(
                    key: ValueKey(isLoading), // ✅ Only rebuild on loading state change
                    itemScrollController: notifier.itemScrollController,
                    itemPositionsListener: notifier.itemPositionsListener,
                    itemCount: messages.length + 1,
                    addSemanticIndexes: true,
                    initialScrollIndex: initialIndex,
                    initialAlignment: initialAlignment,
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const SizedBox(height: 150);
                      }

                      final message = messages[index];
                      return ProviderScope(
                        overrides: [
                          messageProvider.overrideWithValue(message),
                        ],
                        child: const _MessageItemBuilder(),
                      );
                    },
                  ),
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
    // final message = ref.watch(messageProvider);
    final message = ref.watch(messageProvider);
    final messageIsarId = message.isarId;
    final bubbleStyle = ref.watch(settingsController)?.selectedBubbleStyle ?? BubbleStyle.opaque;

    if (message == null) {
      return const SizedBox.shrink(); // Message got deleted -> don't render
    }

    if (message.isImage) {
      final path = message.media.value?.path;
      if (path != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          precacheImage(
            ExtendedFileImageProvider(File(path), cacheRawData: true),
            context,
          );
        });
      }
    }

    // 👇 Watch only derived info for this index
    final info = ref.watch( chatStateController.select((s) => s.messages.layoutInfoById(messageIsarId)));
    final isHighlighted = ref.watch( chatStateController.select((s) => s.highlightedMessage?.isarId == messageIsarId), );
    final isSelected = ref.watch( chatStateController.select((s) => s.selectedMessages.any((m) => m.isarId == messageIsarId)),);
    final isSelecting = ref.watch( chatStateController.select((s) => s.isSelecting));
    final isEditing = ref.watch( chatStateController.select((s) => s.isEditing));
    final bubbleColor = ref.watch( chatStateController.select((s) => s.bubbleColor));

    debugPrint("🔃 Built message: ${message.text}");

    return Column(
      children: [
        if (info.showDateChip) DateChip(message.time),
        RepaintBoundary(
          child: MessageBubble(
            style: bubbleStyle,
            message: message,
            isSelecting: isSelecting,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            topPadding: info.topPadding,
            bottomPadding: info.bottomPadding,
            bubbleColor:  bubbleColor,
            // interactions
            onSwipe: () {
              if (isEditing == false) {
                ref.read(overlayHandlerProvider).showReplyAnchor(context); // show hidden
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(chatStateController.notifier).setAnchorMessage(message, context); // trigger slide
                });
              }
            },
            onTapWhileSelecting: () {
              if (isEditing == false) {
                isSelected
                ? ref.read(chatStateController.notifier).unselectMessage(message)
                : ref.read(chatStateController.notifier).selectMessage(message);
              }
            },
            onTap: () async {
              if (!isEditing) {
                if (ref.read(overlayHandlerProvider).isAttachmentOpen) {
                  ref.read(overlayHandlerProvider).closeAttachmentBoard();
                }
                if (message.isImage || message.isVideo) {
                  // final allImages = ref.read(chatStateController).messages.imageMedias;
                  final allMedia = ref.read(chatStateController).messages.imagesAndVideos;
                  final initialIndex = allMedia.indexOfMediaIsarID(message);
                  final heroTag = message.media.value?.path ?? message.isarId;

                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      barrierColor: Colors.black, // Slight fade
                      transitionDuration: const Duration(milliseconds: 250),
                      pageBuilder: (_, __, ___) => GalleryViewWrapper(
                        galleryItems: allMedia, // allImages,
                        initialIndex: initialIndex,
                        showOptions: true,
                        // options: message.isVideo ? galleryVideoOptions : galleryOptions,
                        // onOptionSelect: (value) => handleGalleryOptions(
                        //   context,
                        //   ref,
                        //   value,
                        //   allMedia[initialIndex],
                        //   // allImages[initialIndex],
                        // ),
                      ),
                      transitionsBuilder: (_, animation, secondaryAnimation, child) {
                        // Use curved animation for smoother start/end
                        final curvedAnimation = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        );

                        return FadeTransition(
                          opacity: curvedAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                } else if (message.isDocument) {
                await OpenFile.open(message.media!.value!.path!);
              } else {
                ref.read(chatStateController.notifier).toggleSender(message);
              }
              }
            },
            onLongPress: (pos) {
              if (ref.read(overlayHandlerProvider).isAttachmentOpen) {
                  ref.read(overlayHandlerProvider).closeAttachmentBoard();
                }
              final notifier = ref.read(chatStateController.notifier);
              notifier.selectMessage(message);
              notifier.searchFocusNode.unfocus();
              notifier.keyboardFocusNode.unfocus();
              CustomContextMenu.showMenuAt(
                context,
                position: pos,
                triangleHorizontalOffset: message.isSender ? 120 : 40,
                menuItems: messageHoldOptions(isMedia: (message.isImage || message.isDocument || message.isAudio || message.isVideo), message: message ),
                onSelected: (val) => notifier.handleMessageMenuAction(val, message, context),
              );
            },
            onReplyTap: () => ref.read(chatStateController.notifier).scrollToMessage(message.replyingTo.value!.isarId),
            onThreadCleared: () async => await ref.read(chatStateController.notifier).removeLastThread(),
          ),
        ),
      ],
    );
  }
}


class LoadIndicator extends StatelessWidget {
  final Color? color;
  final double? size;
  const LoadIndicator({super.key, this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter, // 👈 top center instead of center
      child: Padding(
        padding: const EdgeInsets.only(top: 50), // optional spacing from top
        child: SizedBox(
          height: size ?? 40,
          width: size ?? 40,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            strokeCap: StrokeCap.round,
            color: color ?? (context.isLight
                ? ThemeConstants.sacredSeed
                : ThemeConstants.sinisterSeed),
          ),
        ),
      ),
    );
  }
}
