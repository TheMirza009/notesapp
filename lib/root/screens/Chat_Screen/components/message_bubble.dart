import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message; // Accepting Message object
  final void Function()? onTap;
  final void Function()? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Determine whether the message is a sender
    bool isSender = message.isSender;
    final double screenWidth = MediaQuery.sizeOf(context).width;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.90),
            margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenWidth * 0.02,
            ),
            decoration: BoxDecoration(
              color: isSender ? ( context.isLight ? ThemeConstants.senderBlue : ThemeConstants.senderBlueDark) : (context.isLight ? ThemeConstants.hometoolbarLight3 : ThemeConstants.darkIconBorder), // Color
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25), // Shadow color
                  spreadRadius: 0, // No spread
                  blurRadius: 1.5, // Minimal blur
                  offset: Offset(0, 2.5), // Slight offset for the shadow
                ),
              ],
            ),
            child: IntrinsicWidth(
              // This makes the container width flexible
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text wrapped in a Row with Flexible
                  // Render only if the message type is text
                  buildMediaContent(),
          
                  SizedBox(
                    height: screenWidth * 0.01,
                  ), // Space between text and time
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      "${message.time.hour.toString()}:${message.time.minute.toString()}", // Get time from message
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeConstants.subtitleLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to render the correct content based on message type
  Widget buildMediaContent() {
    switch (message.type) {
      case Mediatype.text:
        return _buildTextMessage();
      case Mediatype.image:
        return _buildImageMessage();
      case Mediatype.video:
        return _buildVideoMessage();
      case Mediatype.audio:
        return _buildAudioMessage();
      case Mediatype.document:
        return _buildDocumentMessage();
      default:
        return SizedBox.shrink(); // In case of unsupported type
    }
  }

  // Render text message
  Widget _buildTextMessage() {
    return Row(
      mainAxisSize:  MainAxisSize.min, // Ensures the row sizes itself to fit the text
      children: [
        Flexible(
          child: Text(
            message.text, // Get text from message
            style: TextStyle(fontSize: ThemeConstants.screenWidth * 0.04),
            softWrap: true, // Ensures text wraps to the next line if too long
          ),
        ),
      ],
    );
  }

  // Render image message (example)
  Widget _buildImageMessage() {
    return Row(
      children: [
        // Add your image rendering logic here
        // Image.network(
        //   message.content?.url ?? '', // Assuming content has a URL for images
        //   width: 100, // Example size
        //   height: 100, // Example size
        // ),
      ],
    );
  }

  // Render video message (example)
  Widget _buildVideoMessage() {
    return Row(
      children: [
        // Add your video rendering logic here
        Icon(Icons.video_call), // Placeholder for video
      ],
    );
  }

  // Render audio message (example)
  Widget _buildAudioMessage() {
    return Row(
      children: [
        // Add your audio rendering logic here
        Icon(Icons.music_note), // Placeholder for audio
      ],
    );
  }

  // Render document message (example)
  Widget _buildDocumentMessage() {
    return Row(
      children: [
        // Add your document rendering logic here
        Icon(Icons.insert_drive_file), // Placeholder for document
      ],
    );
  }
}

class ChatBubbleClipper extends CustomClipper<Path> {
  final bool isSender;
  ChatBubbleClipper({required this.isSender});

  @override
  Path getClip(Size size) {
    const radius = 12.0;
    final path = Path();

    if (isSender) {
      // bubble with tail on right
      path.moveTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
      path.lineTo(radius + 10, size.height);
      path.quadraticBezierTo(radius, size.height, radius, size.height - 10);
      path.lineTo(radius, radius);
      path.close();

      // Tail
      path.moveTo(size.width - 10, size.height - 20);
      path.lineTo(size.width, size.height - 10);
      path.lineTo(size.width - 10, size.height - 5);
      path.close();
    } else {
      // bubble with tail on left
      path.moveTo(10, size.height - 20);
      path.lineTo(0, size.height - 10);
      path.lineTo(10, size.height - 5);
      path.close();

      path.moveTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}