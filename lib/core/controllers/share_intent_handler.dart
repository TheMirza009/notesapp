import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/extensions/string_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_Forward/chat_forward_screen.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';

/// A centralized handler for processing incoming share intents from other applications.
///
/// This class manages the lifecycle of sharing subscriptions and routes shared content
/// (files, media, or URLs) to the appropriate application flow.
///
/// ### Supported Content Types (per AndroidManifest.xml):
/// - **Text & URLs**: `text/*` (Captures shared plain text and browser links)
/// - **Media**: `image/*`, `video/*`, `audio/*`
/// - **Documents**: PDF, MS Office (Word, Excel, PPT), RTF, OpenDocument (ODT, ODS, ODP)
/// - **Archives**: ZIP, RAR, 7Z, TAR, GZIP, BZIP2
/// - **E-books**: EPUB, MOBI, AZW3
class ShareIntentHandler {
  static StreamSubscription? _mediaSub;
  static bool _initialized = false;
  static bool _handling = false; // ✅ prevents double-handling

  /// Initialize listener for incoming shares
  static void initialize() {
    if (kisDesktop) return;
    if (_initialized) return;
    _initialized = true;

    final intent = ReceiveSharingIntent.instance;

    // Stream for new shares while app is open
    _mediaSub = intent.getMediaStream().listen((files) {
      if (files.isNotEmpty) _handleIncomingFilesSafely(files);
    }, onError: (err) => debugPrint('Media stream error: $err'));

    // Handle share when app is launched
    intent.getInitialMedia().then((files) {
      if (files.isNotEmpty) {
        debugPrint("➡️✅ Received file: ${files.first.path}");
        _handleIncomingFilesSafely(files);
      } else {
        debugPrint("ℹ️ No shared files on startup");
      }
      intent.reset();
    });
  }

  static void dispose() {
    if (!kisDesktop) {
      _mediaSub?.cancel();
      _initialized = false;
    }
  }

  /// Handle shared files with debounce and safe navigation
  static void _handleIncomingFilesSafely(List<SharedMediaFile> files) async {
    if (_handling) return; // ✅ prevent multiple triggers
    _handling = true;

    try {
      final first = files.first;
      if (first.path.isEmpty) return;

      final mediaFile = await _processMediaFile(first.path); // compute(_processMediaFile, first.path);
      if (mediaFile == null) return;

      // ✅ Wait until the UI and Navigator are ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 10));

        final ctx = navigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;

        final message = Message()
          ..id = const Uuid().v7()
          ..text = mediaFile.type == Mediatype.link ? mediaFile.path!.withWrappedLinks : _getTypeString(mediaFile)
          ..time = DateTime.now()
          ..isSender = true
          ..media.value = mediaFile;

        // ✅ Only push if we're not already on the ChatForwardScreen
        if (ModalRoute.of(ctx)?.settings.name != 'chat_forward') {
          Navigator.push(
            ctx,
            CupertinoPageRoute(
              builder: (_) => ChatForwardScreen(message: message, isSend: true),
              settings: const RouteSettings(name: 'chat_forward'),
            ),
          );
        }
      });
    } finally {
      // ✅ Allow future shares after a short delay
      await Future.delayed(const Duration(seconds: 1));
      _handling = false;
    }
  }
}

/// Background media processing
Future<Media?> _processMediaFile(String path) async {
  // BackgroundIsolateBinaryMessenger.ensureInitialized();
  return await MediaHandler.handleReceivedMedia(path);
}

String _getTypeString(Media mediaFile) {
  return mediaFile.isImage
      ? '📷 Image'
      : mediaFile.isAudio
          ? '🎧 Audio'
          : mediaFile.isDocument
              ? '📃 Document'
              : mediaFile.isVideo
                  ? "📽️ Video"
                  : mediaFile.type == Mediatype.link
                      ? '🔗 Link'
                      : '❓ Unknown';
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
                    ..text = mediaFile.type == Mediatype.link ? mediaFile.path!.withWrappedLinks : getTypeString(mediaFile)
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
        : mediaFile.isVideo ? '🎞️ Video'
        : mediaFile.type == Mediatype.link ? '🔗 Link'
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
    debugPrint("Error getting duration: $e");
    return "00:00";
  } finally {
    await player.dispose(); // always dispose to avoid phantom AudioTracks
  }
}