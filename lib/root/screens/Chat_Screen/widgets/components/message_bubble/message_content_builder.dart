import 'dart:io';
import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/widgets/voice_message/components/voice_controller.dart';
import 'package:notesapp/root/widgets/voice_message/components/voice_message_view.dart';
import 'package:typeset/typeset.dart';

class MessageContentBuilder extends StatelessWidget {
  final Message message;

  const MessageContentBuilder({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final media = message.media.value;
    if (media == null || media.type == Mediatype.text) {
      return _buildTextWithTimestamp(context);
    }

    switch (media.type) {
      case Mediatype.text:
        return _buildTextWithTimestamp(context);
      case Mediatype.image:
        return ImageMessageView(message: message);
      case Mediatype.video:
        return _buildVideoMessage();
      case Mediatype.audio:
        return AudioMessageView(message: message);
      case Mediatype.document:
        return DocumentMessageView(message: message);
      default:
        return const SizedBox.shrink();
    }
  }

  /// TEXT MESSAGE + timestamp
  Widget _buildTextWithTimestamp(BuildContext context) {
    // Safe isLight check: navigatorKey context may be null in some edge cases (tests, background)
    final isLight = navigatorKey.currentContext?.isLight ?? true;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: TypeSet(
                  message.text,
                  style: const TextStyle(fontSize: 20),
                  softWrap: true,
                  monospaceStyle: TextStyle(
                    fontFamily: "Consolas",
                    backgroundColor: ThemeConstants.iconColorNeutral.withValues(
                      alpha: isLight ? 0.2 : 0.5,
                    ),
                  ),
                  linkRecognizerBuilder: (linkText, url) {
                    return TapGestureRecognizer()
                      ..onTap = () {
                        debugPrint('URL: $url and Text: $linkText');
                      };
                  },
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

  Widget _buildVideoMessage() => const Icon(Icons.video_call);
}

//
// ----------------------------- IMAGE MESSAGE -----------------------------
//
class ImageMessageView extends StatelessWidget {
  final Message message;
  const ImageMessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final media = message.media.value;

    if (media == null || media.path == null) {
      return const SizedBox(
        width: 100,
        height: 100,
        child: Center(child: Icon(Icons.broken_image)),
      );
    }

    final file = File(media.path!);

    // If file doesn't exist, show broken image placeholder
    if (!file.existsSync()) {
      return SizedBox(
        width: 100,
        height: 100,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: const Center(
                child: Icon(Icons.broken_image),
              ),
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

    final ext = (media.extension ?? "").toLowerCase();
    if (ext == "gif") {
      return GifMessageView(message: message);
    }

    final maxHeight = ThemeConstants.screenHeight * 0.5;
    final maxWidth = ThemeConstants.screenWidth * 0.7;
    final aspectRatio = (media.aspectRatio != null && media.aspectRatio! > 0) ? media.aspectRatio! : 1.0;

    // Ensure cache ints are at least 1
    final cacheH = max(1, maxHeight.toInt());
    final cacheW = max(1, maxWidth.toInt());

    return RepaintBoundary(
      child: ClipRRect(
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
                ExtendedImage.file(
                  file,
                  fit: BoxFit.cover,
                  cacheHeight: cacheH, // downsample at decode
                  cacheWidth: cacheW, // downsample at decode
                  clearMemoryCacheIfFailed: true,
                  gaplessPlayback: true,
                  cacheRawData: true, // memory + disk caching
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
      ),
    );
  }
}

//
// ----------------------------- GIF MESSAGE -----------------------------
//
class GifMessageView extends StatelessWidget {
  final Message message;
  const GifMessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final media = message.media.value;
    if (media == null || media.path == null) return const SizedBox();

    final file = File(media.path!);
    if (!file.existsSync()) return const SizedBox();

    return RepaintBoundary(
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                file,
                fit: BoxFit.contain,
                gaplessPlayback: true, // keeps playing
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "GIF",
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeConstants.subtitleLight,
                  ),
                ),
                Text(
                  DateFormat.jm().format(message.time),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ThemeConstants.subtitleLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//
// ----------------------------- AUDIO MESSAGE -----------------------------
//
class AudioMessageView extends StatelessWidget {
  final Message message;
  const AudioMessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final media = message.media.value;
    if (media == null || media.path == null) {
      return const SizedBox.shrink();
    }

    final fileExists = File(media.path!).existsSync();
    if (!fileExists) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RepaintBoundary(
          child: VoiceMessageView(
            audioSrc: media!.path!,
            isFile: true,
            innerPadding: 0,
            backgroundColor: Colors.transparent,
            circlesColor: ThemeConstants.sinisterSeed,
            activeWaveColor: ThemeConstants.sinisterSeed,
            inactiveWaveColor: ThemeConstants.iconColorNeutral,
            showDuration: true,
            showSentTime: true,
            sentTime: message.time,
          ),
        ),
      ],
    );
  }
}

//
// ----------------------------- DOCUMENT MESSAGE -----------------------------
//
class DocumentMessageView extends StatefulWidget {
  final Message message;
  const DocumentMessageView({super.key, required this.message});

  @override
  State<DocumentMessageView> createState() => _DocumentMessageViewState();
}

class _DocumentMessageViewState extends State<DocumentMessageView> {
  // Cache futures per path so we don't re-trigger IO on every rebuild.
  final Map<String, Future<String>> _sizeFutureCache = {};

  Future<String> _getFileSize(String path) {
    return _sizeFutureCache.putIfAbsent(path, () async {
      try {
        // Utils.getFileSize returns Future<String> in your codebase.
        return await Utils.getFileSize(path);
      } catch (e, st) {
        debugPrint('Error getting file size for $path: $e\n$st');
        return 'Size unknown';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.message.media.value;
    final path = media?.path;

    const TextStyle subStyle = TextStyle(
      color: ThemeConstants.iconColorNeutral,
      fontSize: 13,
    );

    return RepaintBoundary(
      child: IntrinsicWidth(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0x0F000000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media?.name ?? "Unknown file",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (path != null)
                                  FutureBuilder<String>(
                                    future: _getFileSize(path),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Text('Loading size...', style: subStyle);
                                      } else if (snapshot.hasError) {
                                        return const Text('Size unknown', style: subStyle);
                                      } else {
                                        final data = snapshot.data ?? 'Size unknown';
                                        return Text(data, style: subStyle);
                                      }
                                    },
                                  ),
                                Text(
                                  (media?.extension ?? "").toUpperCase(),
                                  style: subStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10)
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  DateFormat.jm().format(widget.message.time),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ThemeConstants.subtitleLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
