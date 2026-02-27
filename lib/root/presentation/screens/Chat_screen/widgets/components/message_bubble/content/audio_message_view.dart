
//
// ----------------------------- AUDIO MESSAGE -----------------------------
//
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/presentation/widgets/voice_message/components/voice_message_view.dart';

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
