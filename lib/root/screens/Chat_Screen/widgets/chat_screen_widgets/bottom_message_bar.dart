import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:typeset/typeset.dart';

class BottomMessageBar extends StatefulWidget {
  final VoidCallback onEmojiTap;
  final VoidCallback onAttachmentTap;
  final VoidCallback onMicTap;
  final Function(String) onSend;
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
    this.onSubmitted,
    this.onImagePasted,
    this.keyboardController,
    this.focusNode,
    this.onFieldTap,
  });

  @override
  State<BottomMessageBar> createState() => _BottomMessageBarState();
}

class _BottomMessageBarState extends State<BottomMessageBar> {
  late final TypeSetEditingController _internalController;
  late final TypeSetEditingController messageController;

  @override
  void initState() {
    super.initState();
    _internalController = TypeSetEditingController();
    // If parent provided controller, use that; else use internal
    messageController = widget.keyboardController ?? _internalController;
  }

  @override
  void dispose() {
    // Only dispose internal controller (don’t dispose external one passed in)
    if (widget.keyboardController == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const iconLight = Color(0xFF54666F);
    const iconPadding =
        EdgeInsets.only(left: 5.0, right: 5.0, top: 0, bottom: 5);

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
          Padding(
            padding: iconPadding,
            child: IconButton(
              onPressed: widget.onEmojiTap,
              icon: const Icon(Icons.emoji_emotions_outlined, color: iconLight),
            ),
          ),
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
                    debugPrint(
                      "Keyboard inserted content: ${content.mimeType}",
                    );

                    if (content.mimeType.startsWith('image/')) {
                      widget.onImagePasted?.call(content.data!);
                    } else if (content.mimeType == 'text/plain') {
                      // Append pasted plain text
                      messageController.text +=
                          String.fromCharCodes(content.data!);
                    }
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: iconPadding,
            child: IconButton(
              onPressed: widget.onAttachmentTap,
              icon: const Icon(Icons.attach_file, color: iconLight),
            ),
          ),
          Padding(
            padding: iconPadding,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: messageController,
              builder: (context, value, child) {
                final text = value.text.trim();
                if (text.isEmpty) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final isRecording = ref.watch(chatStateController.select((s) => s.isRecording));
                      return AnimatedScale(
                        duration: Duration(milliseconds: 250),
                        curve: Curves.easeInOutQuint,
                        scale: isRecording ? 1.5 : 1.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              height: isRecording ? 30 : 0,
                              width: isRecording ? 30 : 0,
                              duration: Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (context.isLight ? ThemeConstants.sacredSeed : ThemeConstants.sinisterSeed).withValues(alpha: 0.5)
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onMicTap,
                              icon: Icon(Icons.mic, color: isRecording ? (context.isLight ? const Color.fromARGB(255, 23, 132, 182) : ThemeConstants.sinisterSeed) : iconLight , ),
                            ),
                          ],
                        ),
                      );
                    }
                  );
                } else {
                  return IconButton(
                    onPressed: () {
                      widget.onSend(text);
                      messageController.clear();
                    },
                    icon: Icon(
                      Icons.send,
                      color: context.isLight
                          ? ThemeConstants.sinisterSeed
                          : ThemeConstants.sinisterSeed,
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
