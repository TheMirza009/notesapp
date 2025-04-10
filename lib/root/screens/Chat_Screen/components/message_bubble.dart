import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message; // Accepting Message object

  const MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Determine whether the message is a sender
    bool isSender = message.isSender;
    final double screenWidth = MediaQuery.sizeOf(context).width;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.90),
        margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: isSender ? ThemeConstants.senderBlue : Colors.white, // Color
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
