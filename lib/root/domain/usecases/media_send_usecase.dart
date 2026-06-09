import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/utils/constants.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/presentation/widgets/photo_view/multi_image_preview_screen.dart';

class MediaSendUseCase {
  final Ref ref;

  MediaSendUseCase(this.ref);

  // ── Public entry point ─────────────────────────────────────────────────────

  Future<void> pickAndSendImages() async {
    final pickedMediaList = await _previewMultipleImages();
    if (pickedMediaList == null || pickedMediaList.isEmpty) return;

    // Single selection → reuse the single-image preview modal (supports crop).
    if (pickedMediaList.length == 1) {
      await _previewAndSendSingle(pickedMediaList.first);
      return;
    }

    // Multiple → multi-image review modal (no crop).
    final confirmed = await _showMultiPreviewScreen(pickedMediaList);
    if (confirmed == null || confirmed.isEmpty) {
      // User cancelled — nothing written to storage yet, nothing to clean up.
      return;
    }

    // Save to storage only after user confirms.
    final savedMediaList = await _saveImages(confirmed);
    if (savedMediaList.isEmpty) return;

    await _persistAndAttach(savedMediaList);
  }

  /// Single image → existing MediaPreviewModal (crop available), then save + send.
  Future<void> _previewAndSendSingle(Media picked) async {
    final notifier = ref.read(chatStateController.notifier);
    final previewed = await notifier.showPreview(picked);
    if (previewed == null) return; // cancelled — modal cleans up its own file

    final saved = await _saveImages([previewed]);
    if (saved.isEmpty) return;

    await _persistAndAttach(saved);
  }

  // ── Steps ──────────────────────────────────────────────────────────────────

  /// Lightweight multi-pick — temp paths only, no storage write.
  Future<List<Media>?> _previewMultipleImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(
      limit: Constants.maxImagesPerSend,
    );
    if (files.isEmpty) return null;

    return files
        .take(Constants.maxImagesPerSend) // defensive cap
        .map((xfile) => Media.fromFilePath(xfile.path))
        .toList();
  }

  /// Show the multi-image review as a bottom modal (mirrors MediaPreviewModal's
  /// shell). Returns the ordered list the user confirmed, or null if cancelled.
  Future<List<Media>?> _showMultiPreviewScreen(List<Media> mediaList) async {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    return showModalBottomSheet<List<Media>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height -
              (kisDesktop ? 0 : (kToolbarHeight / 1.5)),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: MultiImagePreviewScreen(mediaList: mediaList),
          ),
        );
      },
    );
  }

  /// Save each picked image to Photos storage + decode aspect ratio +
  /// kick off background blurhash. Reuses MediaHandler.saveImage().
  Future<List<Media>> _saveImages(List<Media> pickedList) async {
    final saved = <Media>[];
    for (final media in pickedList) {
      final result = await MediaHandler.saveImage(image: media);
      if (result != null) saved.add(result);
    }
    return saved;
  }

  /// Persist all messages in a SINGLE writeTxn, then reload managed instances.
  /// Rolls back saved files if the transaction throws.
  Future<void> _persistAndAttach(List<Media> savedMediaList) async {
    final chat = ref.read(chatListProvider).selectedChat;
    if (chat == null) return;

    final isar = IsarDatabase.isar;
    final notifier = ref.read(chatStateController.notifier);

    // deleteInitMessage must run before the first attach (owned by notifier).
    await notifier.deleteInitMessage();

    final messages = savedMediaList
        .map((_) => Message()
          ..text = "📷 Photo"
          ..isSender = true
          ..time = DateTime.now())
        .toList();

    List<int> messageIds = [];

    try {
      await isar.writeTxn(() async {
        // Persist all media objects first.
        for (int i = 0; i < savedMediaList.length; i++) {
          await isar.medias.put(savedMediaList[i]);
        }

        // Persist all messages and link their media.
        for (int i = 0; i < messages.length; i++) {
          final id = await isar.messages.put(messages[i]);
          messageIds.add(id);
          messages[i].media.value = savedMediaList[i];
          await messages[i].media.save();
        }

        // Load/create the managed chat once and add all messages.
        Chat? managedChat = await isar.chats.get(chat.isarID);
        if (managedChat == null) {
          await isar.chats.put(chat);
          managedChat = await isar.chats.get(chat.isarID);
        }
        if (managedChat != null) {
          await managedChat.messages.load();
          for (final message in messages) {
            managedChat.messages.add(message);
          }
          await managedChat.messages.save();
          await isar.chats.put(managedChat);
        }
      });
    } catch (e) {
      debugPrint('❌ MediaSendUseCase: writeTxn failed, rolling back saved files: $e');
      // Roll back — delete files that were written to storage before the txn failed.
      for (final media in savedMediaList) {
        await MediaHandler.deleteMedia(media);
      }
      return;
    }

    // Reload managed messages (with media loaded) before handing to notifier.
    final managedMessages = <Message>[];
    for (final id in messageIds) {
      final managed = await isar.messages.get(id);
      if (managed != null) {
        await managed.media.load();
        managedMessages.add(managed);
      }
    }

    if (managedMessages.isNotEmpty) {
      notifier.appendSentMessages(managedMessages);
    }
  }
}

final mediaSendUseCaseProvider = Provider((ref) => MediaSendUseCase(ref));
