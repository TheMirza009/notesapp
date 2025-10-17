import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Forward/chat_forward_screen.dart';

/// Handles incoming share intents (files) from other apps.
class ShareIntentHandler {
  static StreamSubscription? _mediaSub;
  static bool _initialized = false;

  /// Initialize listeners for incoming shares.
  static void initialize() {
    if (_initialized) return; // prevent multiple setups
    _initialized = true;

    final intent = ReceiveSharingIntent.instance;

    debugPrint("📩 Initializing ShareIntentHandler...");

    // Handle files shared while the app is already open
    _mediaSub = intent.getMediaStream().listen(
      (files) {
        if (files.isNotEmpty) {
          debugPrint("📸 Received files while running: ${files.map((f) => f.path).toList()}");
          _openShareScreen(navigatorKey.currentContext!, files);
        }
      },
      onError: (err) => debugPrint('⚠️ Media stream error: $err'),
    );

    // Handle files shared when app is launched from another app
    intent.getInitialMedia().then((files) {
      if (files.isNotEmpty) {
        for (final f in files) {
          debugPrint("✅ Received on launch: ${f.path}");
        }
        _openShareScreen(navigatorKey.currentContext!, files);
      }

      // Mark as handled
      intent.reset();
    });
  }

  /// Cancel subscriptions to avoid memory leaks.
  static void dispose() {
    _mediaSub?.cancel();
    _initialized = false;
  }

  /// Navigate to ShareScreen with the first file.
  static void _openShareScreen(BuildContext context, List<SharedMediaFile> files) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => ShareScreen(files: files)),
      );
    }
  });
}


  /// Example of converting shared files to Message (for forwarding)
  static void _handleSharedFiles(List<SharedMediaFile> files) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || files.isEmpty) return;

    for (final file in files) {
      final message = Message()
        ..id = const Uuid().v7()
        ..text = ''
        ..time = DateTime.now()
        ..isSender = true
        ..media.value = Media.fromFilePath(file.path);

      Navigator.push(
        ctx,
        CupertinoPageRoute(
          builder: (_) => ChatForwardScreen(
            message: message,
            isSend: true,
          ),
        ),
      );
    }
  }
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
            onPressed: () {
              // Example of forwarding the file to ChatForwardScreen
              final message = Message()
                ..id = const Uuid().v7()
                ..text = ''
                ..time = DateTime.now()
                ..isSender = true
                ..media.value = Media.fromFilePath(first.path);

              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (_) => ChatForwardScreen(
                    message: message,
                    isSend: true,
                  ),
                ),
              );
            },
          )
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
              if (first.path.endsWith('.jpg') ||
                  first.path.endsWith('.png') ||
                  first.path.endsWith('.jpeg'))
                Image.file(
                  File(first.path),
                  height: 200,
                  fit: BoxFit.contain,
                )
            ],
          ),
        ),
      ),
    );
  }
}
