import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/extensions/string_extensions.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/enums/media_type.dart';

class ReplyAnchor extends StatelessWidget {
  final String? text;
  final Media? media;
  final VoidCallback? onClear;
  final double maxHeight;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool? isRecording;

  const ReplyAnchor({
    super.key,
    required this.text,
    this.media,
    this.onClear,
    this.maxHeight = 100,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOutQuint,
    this.isRecording = false,
  });

  bool get _isVisible => text != null && text!.isNotEmpty;

  /// Rebuilds: 15-20 single TEXT
  /// Rebuilds: 150 multiple texts
  /// Rebuilds: >200 texts with images

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        _isVisible
            ? (context.isLight
                ? ThemeConstants.senderBlue
                : ThemeConstants.senderBlueDark)
            : Colors.transparent;

    final padding =
        _isVisible
            ? EdgeInsets.only(
              top: 5,
              bottom: ((isRecording ?? false) ? 80 : 5),
              left: 5,
              right: 5,
            )
            : EdgeInsets.zero;

    final bool threadType = media?.type == Mediatype.thread;
    final bool audioType = media?.type == Mediatype.audio;
    final String threadDecode = "🧵 ${text?.safeDecode().length.toString() ?? "thread"} notes";
    return ClipRect(
      child: AnimatedSlide(
        offset: _isVisible ? Offset.zero : const Offset(0, 1.0), // const Offset(0, 1.5),
        duration: animationDuration,
        curve: animationCurve,
        child: AnimatedContainer(
          duration: animationDuration,
          curve: animationCurve,
          margin: EdgeInsets.only(bottom: _isVisible ? 8 : 0, left: 8, right: 8),
          padding: padding,
          constraints: BoxConstraints(
            maxHeight: (isRecording ?? false) ? 175 : 100, // _isVisible ? maxHeight : 0,
            maxWidth: double.infinity,
          ),
          decoration: BoxDecoration(
            borderRadius:
                (isRecording ?? false)
                    ? BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(33),
                      bottomRight: Radius.circular(33),
                    )
                    : BorderRadius.circular(15),
            color: backgroundColor,
          ),
          child: RepaintBoundary(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: context.isLight ? const Color(0x13002D6C) : Colors.black12,
              ),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(width: 5, color: ThemeConstants.sinisterSeed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: (isRecording ?? false) ? MainAxisAlignment.start : MainAxisAlignment.center ,
                        children: [
                          SizedBox(height: 5),
                          Text("replying to", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                          // SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              _buildDisplayText(),
                              softWrap: true,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          SizedBox(height: 5),
                        ],
                      ),
                    ),
                    if (_isVisible && onClear != null)
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          if (media != null) IntrinsicHeight(
                            child: Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
                              height: 60,
                              width: 60,
                              clipBehavior: Clip.antiAlias,
                              child: RepaintBoundary(
                                  child: (media!.isImage || media!.isVideo) ? Image.file(
                                    File(media!.isVideo ? media!.thumbnailPath! : media!.path!),
                                    fit: BoxFit.cover,
                                  ) : SizedBox.shrink(), // (media!.isDocument ? Icon(Icons.insert_drive_file) : (media!.isAudio ? Icon(Icons.audio_file) : SizedBox.shrink())),
                                ),
                              ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: IconButton.filled(
                              color: Colors.white,
                              style: IconButton.styleFrom(backgroundColor: Colors.black12),
                              onPressed: onClear,
                              icon: const Icon(Icons.clear),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildDisplayText() {
    if (media == null) return text ?? '';

    switch (media!.type) {
      case Mediatype.thread:
        final decoded = text?.safeDecode() ?? [];
        final count = decoded.length;
        return "🧵 $count notes";

      case Mediatype.audio:
        final duration = media?.duration ?? "00:00";
        final prefix = (text?.isNotEmpty ?? false) ? text!.characters.first : "🎧 ";
        return "$prefix $duration";

      case Mediatype.document:
        final prefix = (text?.isNotEmpty ?? false) ? text!.characters.first : "📃 ";
        return "$prefix ${media?.extension.toUpperCase() ?? "UNKNOWN"} - ${media?.name ?? "Unknown"}";

      case Mediatype.video:
        final duration = media?.duration ?? "00:00";
        final prefix = (text?.isNotEmpty ?? false) ? text!.characters.first : "📽️ ";
        return "$prefix $duration";

      default:
        return text ?? '';
    }
  }
}
