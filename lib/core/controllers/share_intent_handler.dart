import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Forward/chat_forward_screen.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class ShareIntentHandler {
  static StreamSubscription? _mediaSub;
  static bool _initialized = false;

  /// Initialize listener for incoming shares
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    final intent = ReceiveSharingIntent.instance;

    // Listen while app is open
    _mediaSub = intent.getMediaStream().listen((files) {
      if (files.isNotEmpty) handleIncomingFiles(files);
    }, onError: (err) => debugPrint('Media stream error: $err'));

    // Handle initial share when app launches
    intent.getInitialMedia().then((files) {
      if (files.isNotEmpty) handleIncomingFiles(files);
      intent.reset();
    });
  }

  static void dispose() {
    _mediaSub?.cancel();
    _initialized = false;
  }

  /// Handle incoming shared files safely and smoothly
  static void handleIncomingFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    final first = files.first;
    if (first.path.isEmpty) return;

    // Offload media processing to a background isolate
    compute(_processMediaFile, first.path).then((mediaFile) {
      if (mediaFile == null) return;

      // Navigation must happen on the main thread after UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;

        final message = Message()
          ..id = const Uuid().v7()
          ..text = getTypeString(mediaFile)
          ..time = DateTime.now()
          ..isSender = true
          ..media.value = mediaFile;

        Navigator.pushReplacement(
          ctx,
          CupertinoPageRoute(
            builder: (_) => ChatForwardScreen(message: message, isSend: true),
          ),
        );
      });
    });
  }
}

/// Top-level function to process a file into a Media object
Future<Media?> _processMediaFile(String path) async {
  // Heavy work: save file, calculate aspect ratio, detect type
  final media = await MediaHandler.handleReceivedMedia(path);
  return media;
}


/// A lightweight preview screen shown when files are shared into the app.
class ShareScreen extends StatelessWidget {
  final List<SharedMediaFile> files;

  const ShareScreen({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    final first = files.first;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shared File"),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () async {
              if (first.path.isEmpty) return;

              // Handle the received file and get a Media object
              final mediaFile = await MediaHandler.handleReceivedMedia(
                first.path,
              );
              if (mediaFile == null) return;

              // Create the message
              final message =
                  Message()
                    ..id = const Uuid().v7()
                    ..text = getTypeString(mediaFile) // or leave empty if you want
                    ..time = DateTime.now()
                    ..isSender = true
                    ..media.value = mediaFile;

              // Navigate to ChatForwardScreen
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder:
                      (_) => ChatForwardScreen(message: message, isSend: true),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "📁 Path:\n${first.path}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                "Type: ${first.type.name}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (Media.fromFilePath(first.path).isImage)
                Image.file(
                  File(first.path),
                  height: 500,
                  fit: BoxFit.contain,
                ),
              if (Media.fromFilePath(first.path).isAudio) 
                Row(
                  children: [
                    Icon(Icons.audio_file), 
                    FutureBuilder<String>(
                      future: getAudioDuration(first.path),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text("Loading...");
                        } else if (snapshot.hasError) {
                          return const Text("Error");
                        } else {
                          return Text(snapshot.data ?? "00:00");
                        }
                      },
                    ),
                  ],
                ),
              if (Media.fromFilePath(first.path).isDocument) 
                Icon(Icons.insert_drive_file)
            ],
          ),
        ),
      ),
    );
  }
}

String getTypeString(Media mediaFile) {
  return switch (true) {
    _ => mediaFile.isImage ? '📷 Image'
        : mediaFile.isAudio ? '🎧 Audio'
        : mediaFile.isDocument ? '📃 Document'
        // : mediaFile.isVideo ? '🎞️ Video'
        : '❓ Unknown',
  };
}

Future<String> getAudioDuration(String filePath) async {
  final player = AudioPlayer();
  try {
    await player.setFilePath(filePath);
    final duration = player.duration ?? Duration.zero;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  } catch (e) {
    print("Error getting duration: $e");
    return "00:00";
  } finally {
    await player.dispose(); // always dispose to avoid phantom AudioTracks
  }
}