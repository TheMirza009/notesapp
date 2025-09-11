import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/ripple_menu.dart';
import 'package:notesapp/root/widgets/custom_context_menu_2.dart';

class MessageBubble extends StatelessWidget {
  final Message message; // Accepting Message object
  final void Function()? onTap;
  final Function(Offset)? onLongPress;
  final void Function()? onDeleteMessage;

  const MessageBubble({
    super.key,
    required this.message,
    this.onTap,
    this.onLongPress,
    this.onDeleteMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Determine whether the message is a sender
    bool isSender = message.isSender;
    final double screenWidth = context.screenWidth;
    Color messageBubbleColor = isSender
          ? (context.isLight ? ThemeConstants.senderBlue : ThemeConstants.senderBlueDark)
          : (context.isLight ? ThemeConstants.hometoolbarLight3 : ThemeConstants.darkIconBorder);

    var verticalPadding = screenWidth * 0.015;
    var messageborderRadius = BorderRadius.circular(10);
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(top: verticalPadding, bottom: verticalPadding, left: isSender ? 40 : 0, right: !isSender ? 40 : 0 ),
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  spreadRadius: 0,
                  blurRadius: 1.5,
                  offset: Offset(0, 2.5),
                ),
              ],
              borderRadius: messageborderRadius,
            ),
            child: RippleMenu(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: messageborderRadius,
              materialColor: messageBubbleColor,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenWidth * 0.02,
                ),
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildMediaContent(),
                      SizedBox(height: screenWidth * 0.01),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          DateFormat.jm().format(message.time),
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
        ),
      ),
    );
  }

  // Helper function to render the correct content based on message type
  Widget buildMediaContent() {
    if (message.media == null || message.media!.type == Mediatype.text) {
      return _buildTextMessage();
    }

    switch (message.media!.type) {
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

  Future<double> _getImageAspectRatio(File file) async {
    final image = await decodeImageFromList(file.readAsBytesSync());
    return image.width / image.height;
  }

  // Render image message (example)
  Widget _buildImageMessage() {
    final file = message.media!.content!;
    final maxHeight = ThemeConstants.screenHeight * 0.5;
    return FutureBuilder<double>(
      future: _getImageAspectRatio(file),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 100,
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: AspectRatio(
              aspectRatio: snapshot.data!,
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
        );
      },
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

class _SpecialChatBubbleOne extends CustomPainter {
  final Color color;
  final Alignment alignment;
  final bool tail;

  _SpecialChatBubbleOne({
    required this.color,
    required this.alignment,
    required this.tail,
  });

  double _radius = 10.0;
  double _x = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (alignment == Alignment.topRight) {
      if (tail) {
        canvas.drawRRect(
            RRect.fromLTRBAndCorners(
              0,
              0,
              size.width - _x,
              size.height,
              bottomLeft: Radius.circular(_radius),
              bottomRight: Radius.circular(_radius),
              topLeft: Radius.circular(_radius),
            ),
            Paint()
              ..color = this.color
              ..style = PaintingStyle.fill);
        var path = new Path();
        path.moveTo(size.width - _x, 0);
        path.lineTo(size.width - _x, 10);
        path.lineTo(size.width, 0);
        canvas.clipPath(path);
        canvas.drawRRect(
            RRect.fromLTRBAndCorners(
              size.width - _x,
              0.0,
              size.width,
              size.height,
              topRight: Radius.circular(3),
            ),
            Paint()
              ..color = this.color
              ..style = PaintingStyle.fill);
      } else {
        canvas.drawRRect(
            RRect.fromLTRBAndCorners(
              0,
              0,
              size.width - _x,
              size.height,
              bottomLeft: Radius.circular(_radius),
              bottomRight: Radius.circular(_radius),
              topLeft: Radius.circular(_radius),
              topRight: Radius.circular(_radius),
            ),
            Paint()
              ..color = this.color
              ..style = PaintingStyle.fill);
      }
    } else {
      if (tail) {
        canvas.drawRRect(
            RRect.fromLTRBAndCorners(
              _x,
              0,
              size.width,
              size.height,
              bottomRight: Radius.circular(_radius),
              topRight: Radius.circular(_radius),
              bottomLeft: Radius.circular(_radius),
            ),
            Paint()
              ..color = this.color
              ..style = PaintingStyle.fill);
        var path = new Path();
        path.moveTo(_x, 0);
        path.lineTo(_x, 10);
        path.lineTo(0, 0);
        canvas.clipPath(path);
        canvas.drawRRect(
            RRect.fromLTRBAndCorners(
              0,
              0.0,
              _x,
              size.height,
              topLeft: Radius.circular(3),
            ),
            Paint()
              ..color = this.color
              ..style = PaintingStyle.fill);
      } else {
        canvas.drawRRect(
            RRect.fromLTRBAndCorners(
              _x,
              0,
              size.width,
              size.height,
              bottomRight: Radius.circular(_radius),
              topRight: Radius.circular(_radius),
              bottomLeft: Radius.circular(_radius),
              topLeft: Radius.circular(_radius),
            ),
            Paint()
              ..color = this.color
              ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
