import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
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

class _BottomMessageBarState extends ConsumerState<BottomMessageBar>
    with SingleTickerProviderStateMixin {
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

    const iconLight = Color(0xFF54666F);
    const iconPadding = EdgeInsets.only(left: 5, right: 5, bottom: 5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.isLight
            ? ThemeConstants.hometoolbarLight2
            : ThemeConstants.messageBarDark,
        border: Border(
          top: BorderSide(
            color: context.isLight
                ? Colors.grey[300]!
                : ThemeConstants.darkAppbar,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // === EMOJI / CLEAR ICON SWITCHER ===
          Padding(
            padding: iconPadding,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: isEditing
                  ? IconButton(
                      key: const ValueKey("clearButton"),
                      icon: Icon(CupertinoIcons.clear, color: context.isLight ? iconLight : ThemeConstants.textDark ),
                      onPressed: () {
                        notifier.cancelEditing();
                        messageController.clear();
                      },
                    )
                  : IconButton(
                      key: const ValueKey("emojiButton"),
                      icon: const Icon(Icons.emoji_emotions_outlined,
                          color: iconLight),
                      onPressed: widget.onEmojiTap,
                    ),
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
              ),
            ),
          ),

          // === ATTACHMENT ICON ===
          Padding(
            padding: iconPadding,
            child: AnimatedSlide(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeIn,
              offset: Offset(isEditing ? 0.5 : 0, 0),
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 200),
                opacity: isEditing ? 0 : 1,
                child: IconButton(
                  onPressed: widget.onAttachmentTap,
                  icon: const Icon(Icons.attach_file, color: iconLight),
                ),
              ),
            ),
          ),

          // === SEND / MIC ICON ===
          Padding(
            padding: iconPadding,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: messageController,
              builder: (context, value, _) {
                final text = value.text.trim();
                if (text.isEmpty) {
                  // === MIC ICON ===
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
                            color: (context.isLight
                                    ? ThemeConstants.sacredSeed
                                    : ThemeConstants.sinisterSeed)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onMicTap,
                          icon: Icon(
                            Icons.mic,
                            color: isRecording
                                ? (context.isLight
                                    ? const Color(0xFF1784B6)
                                    : ThemeConstants.sinisterSeed)
                                : iconLight,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // === SEND / EDIT (CHECKMARK) ICON ===
                  return IconButton(
                    onPressed: () {
                      isEditing
                          ? widget.onEdit(text)
                          : widget.onSend(text);
                      messageController.clear();
                    },
                    icon: Icon(
                      isEditing
                          ? CupertinoIcons.check_mark
                          : Icons.send_rounded,
                      color: ThemeConstants.sinisterSeed,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
