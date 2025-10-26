import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:typeset/typeset.dart';

class BottomMessageBar extends ConsumerStatefulWidget {
  final VoidCallback onEmojiTap;
  final VoidCallback onAttachmentTap;
  final VoidCallback onMicTap;
  final Function(String) onSend;
  final Function(String) onEdit;
  final Function(String)? onSubmitted;
  final void Function(Uint8List)? onImagePasted;
  final void Function()? onFieldTap;
  final TypeSetEditingController? keyboardController;
  final FocusNode? focusNode;

  const BottomMessageBar({
    super.key,
    required this.onEmojiTap,
    required this.onAttachmentTap,
    required this.onMicTap,
    required this.onSend,
    required this.onEdit,
    this.onSubmitted,
    this.onImagePasted,
    this.keyboardController,
    this.focusNode,
    this.onFieldTap,
  });

  @override
  ConsumerState<BottomMessageBar> createState() => _BottomMessageBarState();
}

class _BottomMessageBarState extends ConsumerState<BottomMessageBar> {
  late final TypeSetEditingController _internalController;
  late final TypeSetEditingController messageController;

  @override
  void initState() {
    super.initState();
    _internalController = TypeSetEditingController();
    messageController = widget.keyboardController ?? _internalController;
  }

  @override
  void dispose() {
    if (widget.keyboardController == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(chatStateController.notifier);
    final state = ref.watch(chatStateController);

    final isEditing = state.isEditing;
    final isRecording = state.isRecording;
    final isThreading = state.isThreading;
    final isLight = context.isLight;

    const iconLight = Color(0xFF54666F);
    const iconPadding = EdgeInsets.only(left: 5, right: 5, bottom: 5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isLight
            ? ThemeConstants.hometoolbarLight2
            : ThemeConstants.messageBarDark,
        border: Border(
          top: BorderSide(
            color: isLight ? Colors.grey[300]! : ThemeConstants.darkAppbar,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // === LEFT ICON (EMOJI / CLEAR / DELETE) ===
          Padding(
            padding: iconPadding,
            child: _LeftIconSwitcher(
              isEditing: isEditing,
              isThreading: isThreading,
              isLight: isLight,
              onClear: () {
                notifier.cancelEditing();
                messageController.clear();
              },
              onDeleteThread: notifier.cancelThread,
              onEmojiTap: widget.onEmojiTap,
            ),
          ),

          // === MESSAGE INPUT FIELD ===
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: TextField(
                autofocus: false,
                focusNode: widget.focusNode,
                controller: messageController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Type a message",
                  border: InputBorder.none,
                ),
                onTap: widget.onFieldTap,
                onSubmitted: widget.onSubmitted,
                contentInsertionConfiguration: ContentInsertionConfiguration(
                  onContentInserted: (KeyboardInsertedContent content) {
                    if (content.mimeType.startsWith('image/')) {
                      widget.onImagePasted?.call(content.data!);
                    } else if (content.mimeType == 'text/plain') {
                      messageController.text +=
                          String.fromCharCodes(content.data!);
                    }
                  },
                ),
                onChanged: (value) {
                  if (isThreading) {ref.read(chatStateController.notifier).onTyping(value);}
                },
              ),
            ),
          ),

          // === ATTACHMENT / ADD ICON ===
          Padding(
            padding: iconPadding,
            child: _AttachmentIconSwitcher(
              isEditing: isEditing,
              isThreading: isThreading,
              isLight: isLight,
              messageController: messageController,
              onAttachmentTap: widget.onAttachmentTap,
              onAddPressed: () {
                messageController.text = "";
                notifier.addThread(messageController.text);
                },
            ),
          ),

          // === SEND / MIC ICON ===
          Padding(
            padding: iconPadding,
            child: _SendMicIconSwitcher(
              messageController: messageController,
              isEditing: isEditing,
              isRecording: isRecording,
              isThreading: isThreading,
              isLight: isLight,
              onMicTap: widget.onMicTap,
              onSend: (text) {
                isEditing ? widget.onEdit(text) : widget.onSend(text);
                messageController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEPARATE WIDGETS FOR PERFORMANCE & CLARITY
// ============================================================================

class _LeftIconSwitcher extends StatelessWidget {
  final bool isEditing;
  final bool isThreading;
  final bool isLight;
  final VoidCallback onClear;
  final VoidCallback onDeleteThread;
  final VoidCallback onEmojiTap;

  const _LeftIconSwitcher({
    required this.isEditing,
    required this.isThreading,
    required this.isLight,
    required this.onClear,
    required this.onDeleteThread,
    required this.onEmojiTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: anim,
          child: child,
        ),
      ),
      child: isEditing
          ? IconButton(
              key: const ValueKey("clearButton"),
              icon: Icon(
                CupertinoIcons.clear,
                color: isLight
                    ? const Color(0xFF54666F)
                    : ThemeConstants.textDark,
              ),
              onPressed: onClear,
            )
          : isThreading
              ? IconButton(
                  key: const ValueKey("deleteThread"),
                  onPressed: onDeleteThread,
                  icon: vectorBuild(IconPaths.trash1),
                )
              : IconButton(
                  key: const ValueKey("emojiButton"),
                  icon: const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Color(0xFF54666F),
                  ),
                  onPressed: onEmojiTap,
                ),
    );
  }
}

class _AttachmentIconSwitcher extends StatelessWidget {
  final bool isEditing;
  final bool isThreading;
  final bool isLight;
  final TypeSetEditingController messageController;
  final VoidCallback onAttachmentTap;
  final VoidCallback onAddPressed;

  const _AttachmentIconSwitcher({
    required this.isEditing,
    required this.isThreading,
    required this.isLight,
    required this.messageController,
    required this.onAttachmentTap,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child:
          isEditing
              ? const SizedBox.shrink(key: ValueKey("hiddenAttachment"))
              : isThreading
              ? ValueListenableBuilder<TextEditingValue>(
                key: const ValueKey("addButton"),
                valueListenable: messageController,
                builder: (context, value, _) {
                  final isEmpty = value.text.trim().isEmpty;
                  final targetColor =
                      isEmpty
                          ? ThemeConstants.iconColorNeutral
                          : (isLight
                              ? ThemeConstants.textLight
                              : ThemeConstants.textDark);

                  return TweenAnimationBuilder<Color?>(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    tween: ColorTween(end: targetColor),
                    builder: (context, color, child) {
                      return IconButton(
                        onPressed: onAddPressed,
                        icon: Icon(Icons.add_rounded, size: 28, color: color),
                      );
                    },
                  );
                },
              )
              : IconButton(
                  key: const ValueKey("attachmentButton"),
                  onPressed: onAttachmentTap,
                  icon: const Icon(
                    Icons.attach_file,
                    color: Color(0xFF54666F),
                  ),
                ),
    );
  }
}
class _SendMicIconSwitcher extends StatelessWidget {
  final TypeSetEditingController messageController;
  final bool isEditing;
  final bool isRecording;
  final bool isThreading;
  final bool isLight;
  final VoidCallback onMicTap;
  final Function(String) onSend;

  const _SendMicIconSwitcher({
    required this.messageController,
    required this.isEditing,
    required this.isRecording,
    required this.isThreading,
    required this.isLight,
    required this.onMicTap,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: messageController,
      builder: (context, value, _) {
        final text = value.text.trim();
        final isEmpty = text.isEmpty;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: anim,
              child: child,
            ),
          ),
          child: isEmpty
              ? _MicButton(
                  key: const ValueKey("micButton"),
                  isRecording: isRecording,
                  isThreading: isThreading,
                  isLight: isLight,
                  onMicTap: onMicTap,
                  isFieldEmpty: messageController.text.isEmpty,
                )
              : isThreading
                  ? _MicButton( // Changed from SizedBox.shrink to _MicButton
                      key: const ValueKey("threadSendButton"),
                      isRecording: isRecording,
                      isThreading: isThreading,
                      isLight: isLight,
                      onMicTap: onMicTap,
                      isFieldEmpty: messageController.text.isEmpty,
                    )
                  : IconButton(
                      key: const ValueKey("sendButton"),
                      onPressed: () => onSend(text),
                      icon: Icon(
                        isEditing
                            ? CupertinoIcons.check_mark
                            : Icons.send_rounded,
                        color: ThemeConstants.sinisterSeed,
                      ),
                    ),
        );
      },
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isRecording;
  final bool isThreading;
  final bool isLight;
  final bool isFieldEmpty;
  final VoidCallback onMicTap;

  const _MicButton({
    super.key,
    required this.isRecording,
    required this.isThreading,
    required this.isLight,
    required this.onMicTap,
    required this.isFieldEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutQuint,
      scale: isRecording ? 1.5 : 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            height: isRecording ? 30 : 0,
            width: isRecording ? 30 : 0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isLight
                      ? ThemeConstants.sacredSeed
                      : ThemeConstants.sinisterSeed)
                  .withValues(alpha: 0.5),
            ),
          ),
          if (isThreading)
            IconButton(
              onPressed: () => debugPrint("Send Thread"),
              icon: Transform.translate(
                offset: const Offset(-5, 3),
                child: vectorBuild(
                  scale: 1.25,
                  IconPaths.sendBubble,
                  color: isFieldEmpty ? ThemeConstants.iconColorNeutral : ThemeConstants.sinisterSeed,
                ),
              ),
            )
          else
            IconButton(
              onPressed: onMicTap,
              icon: Icon(
                Icons.mic,
                color: isRecording
                    ? (isLight
                        ? const Color(0xFF1784B6)
                        : ThemeConstants.sinisterSeed)
                    : const Color(0xFF54666F),
              ),
            ),
        ],
      ),
    );
  }
}