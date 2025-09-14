import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class MessageContentBuilder extends StatelessWidget {
  final Message message;

  const MessageContentBuilder({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.media.value == null || message.media.value!.type == Mediatype.text) {
      return _buildTextWithTimestamp();
    }

    switch (message.media.value?.type) {
      case Mediatype.text:
        return _buildTextWithTimestamp();
      case Mediatype.image:
        return _buildImageWithOverlay();
      case Mediatype.video:
        return _buildVideoMessage();
      case Mediatype.audio:
        return _buildAudioMessage();
      case Mediatype.document:
        return _buildDocumentMessage();
      default:
        return const SizedBox.shrink();
    }
  }

  /// TEXT MESSAGE + timestamp
  Widget _buildTextWithTimestamp() {
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  message.text,
                  style: const TextStyle(fontSize: 20),
                  softWrap: true,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              DateFormat.jm().format(message.time),
              style: const TextStyle(
                fontSize: 12,
                color: ThemeConstants.subtitleLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// IMAGE MESSAGE + gradient overlay + timestamp
  Widget _buildImageWithOverlay() {
    final media = message.media.value;

    if (media == null || media.path == null) {
      return const SizedBox(
        width: 100,
        height: 100,
        child: Center(child: Icon(Icons.broken_image)),
      );
    }

    final file = File(media.path!);
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
          borderRadius: BorderRadius.circular(6),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: AspectRatio(
              aspectRatio: snapshot.data!,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Image.file(file, fit: BoxFit.cover),
                  Container(
                    height: 50,
                    alignment: Alignment.bottomRight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(0),
                          Colors.black.withAlpha(255),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      DateFormat.jm().format(message.time),
                      style: const TextStyle(
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
      },
    );
}


  Future<double> _getImageAspectRatio(File file) async {
    final image = await decodeImageFromList(file.readAsBytesSync());
    return image.width / image.height;
  }

  Widget _buildVideoMessage() => const Icon(Icons.video_call);
  Widget _buildAudioMessage() => const Icon(Icons.music_note);
  Widget _buildDocumentMessage() => const Icon(Icons.insert_drive_file);
}
