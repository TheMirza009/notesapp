import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/content/audio_message_view.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/content/document_message_view.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/content/image_message_view.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/content/thread_message/thread_message_view.dart';
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
        return ImageMessageView(message: message, key: ValueKey(message.isarId),);
      case Mediatype.video:
        return _buildVideoMessage();
      case Mediatype.audio:
        return AudioMessageView(message: message, key: ValueKey(message.isarId),);
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

