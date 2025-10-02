import 'dart:io';
import 'package:extended_image/extended_image.dart';
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
        return RepaintBoundary(child: _buildImageWithOverlay());
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

    // 🔑 Detect GIF by extension
    final ext = (media.extension ?? "").toLowerCase();
    if (ext == "gif") {
      return _buildGifMessage();
    }

    final maxHeight = ThemeConstants.screenHeight * 0.5;
    final maxWidth = ThemeConstants.screenWidth * 0.6;

    // Use stored aspect ratio, fallback to 1 if null
    final aspectRatio = media.aspectRatio ?? 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Image.file(file, fit: BoxFit.cover),
              ExtendedImage.file(
                file,
                fit: BoxFit.cover,
                cacheHeight: maxHeight.toInt(), // 🔑 downsample at decode
                cacheWidth: maxWidth.toInt(), // 🔑 downsample at decode
                clearMemoryCacheIfFailed: true,
                gaplessPlayback: true,
                cacheRawData: true, // 🔥 memory + disk caching
                clearMemoryCacheWhenDispose: false,
                compressionRatio: 0.5,
              ),
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
  }

  Widget _buildGifMessage() {
    final media = message.media.value;
    if (media == null || media.path == null) return const SizedBox();

    return IntrinsicWidth(
      child: Column(
        spacing: 5,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(media.path!),
              fit: BoxFit.contain,
              gaplessPlayback: true, // keeps playing
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("GIF", style: const TextStyle(
                  fontSize: 12,
                  color: ThemeConstants.subtitleLight,
                ),),
              Text(
                DateFormat.jm().format(message.time),
                style: const TextStyle(
                  fontSize: 12,
                  color: ThemeConstants.subtitleLight,
                ),
              ),
            ],
          )
        ],
      ),
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
