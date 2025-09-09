import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';

class BottomMessageBar extends StatefulWidget {
  final VoidCallback onEmojiTap;
  final VoidCallback onAttachmentTap;
  final VoidCallback onMicTap;
  final Function(String) onSend;
  final Function(String)? onSubmitted;

  const BottomMessageBar({
    super.key,
    required this.onEmojiTap,
    required this.onAttachmentTap,
    required this.onMicTap,
    required this.onSend,
    this.onSubmitted,
  });

  @override
  State<BottomMessageBar> createState() => _BottomMessageBarState();
}

class _BottomMessageBarState extends State<BottomMessageBar> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const iconLight = Color(0xFF54666F);
    const iconPadding = EdgeInsets.only(left: 5.0, right: 5.0, top: 0, bottom: 5);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 8
        // vertical: context.screenWidth * 0.02,
        // horizontal: context.screenWidth * 0.04,
      ),
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
              padding: EdgeInsets.only(left: 5),
              child: TextField(
                autofocus: true,
                controller: _messageController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 5, // expand up to 5 lines
                decoration: const InputDecoration(
                  hintText: "Type a message",
                  border: InputBorder.none,
                ),
                onSubmitted: widget.onSubmitted,
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
              valueListenable: _messageController,
              builder: (context, value, child) {
                final text = value.text.trim();
                if (text.isEmpty) {
                  return IconButton(
                    onPressed: widget.onMicTap,
                    icon: const Icon(Icons.mic, color: iconLight),
                  );
                } else {
                  return IconButton(
                    onPressed: () {
                      widget.onSend(text);
                      _messageController.clear();
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
