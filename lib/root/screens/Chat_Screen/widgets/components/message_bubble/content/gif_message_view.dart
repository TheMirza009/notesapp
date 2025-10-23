
//
// ----------------------------- GIF MESSAGE -----------------------------
//
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/message_model.dart';

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
