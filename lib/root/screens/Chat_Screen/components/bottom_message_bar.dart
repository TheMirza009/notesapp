import 'package:flutter/material.dart';

class BottomMessageBar extends StatelessWidget {
  final double screenWidth;
  final VoidCallback onEmojiTap;
  final VoidCallback onAttachmentTap;
  final VoidCallback onMicTap;
  final VoidCallback onSend;

  const BottomMessageBar({
    required this.screenWidth,
    required this.onEmojiTap,
    required this.onAttachmentTap,
    required this.onMicTap,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    const IconLight = Color(0xFF54666F);
    TextEditingController messageController = TextEditingController();

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenWidth * 0.02,
        horizontal: screenWidth * 0.04,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onEmojiTap,
            icon: Icon(Icons.emoji_emotions_outlined, color: IconLight),
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: "Type a message",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: onAttachmentTap,
            icon: Icon(Icons.attach_file, color: IconLight),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: messageController, // Listen to the text input
            builder: (context, value, child) {
              return value.text.isEmpty
                  ? IconButton(
                    onPressed: onMicTap, // Start recording audio
                    icon: Icon(Icons.mic, color: IconLight),
                  )
                  : IconButton(
                    onPressed: onSend, // Send the text message
                    icon: Icon(Icons.send, color: IconLight),
                  );
            },
          ),
        ],
      ),
    );
  }
}
