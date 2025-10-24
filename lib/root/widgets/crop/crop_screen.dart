import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/user_provider.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/user_model.dart';

class CropScreen extends ConsumerStatefulWidget {
  final bool? isChatPhoto;
  const CropScreen({super.key, this.isChatPhoto = false});

  @override
  ConsumerState<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends ConsumerState<CropScreen> {
  bool _isProcessing = false;
  String _status = 'Selecting image...';

  @override
  void initState() {
    super.initState();
    _startImageFlow();
  }

  Future<void> _startImageFlow() async {
    try {
      setState(() {
        _isProcessing = true;
        _status = 'Selecting image...';
      });

      // Step 1: Pick image
      final pickedMedia = await MediaHandler.pickImage(
        isProfilePicture: true,
        useCroppy: true,
      );

      if (pickedMedia == null) {
        debugPrint("❌ No image selected");
        _navigateBack();
        return;
      }

      debugPrint("📷 Picked media: ${pickedMedia.path}");
      setState(() {
        _status = 'Processing image...';
      });

      // Step 2: Decide what to update
      if (widget.isChatPhoto == true) {
        debugPrint("💬 Updating chat photo...");
        await _updateChatPhoto(pickedMedia);
      } else {
        debugPrint("👤 Updating user profile photo...");
        await _updateUserProfile(pickedMedia);
      }

      // Step 3: Precache new image
      _precacheProfileImage(pickedMedia.path);

      debugPrint("🎉 Image updated successfully");
      _navigateBack();

    } catch (e, stackTrace) {
      debugPrint("🔥 Error in CropScreen: $e\n$stackTrace");
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
      await Future.delayed(const Duration(seconds: 2));
      _navigateBack();
    }
  }

  /// --- USER PROFILE UPDATE FLOW ---
  Future<void> _updateUserProfile(Media mediaToUse) async {
    final currentUser = ref.read(userController);
    if (currentUser == null) return;

    final existingMedia = await IsarDatabase.isar.medias
        .filter()
        .pathEqualTo(mediaToUse.path)
        .findFirst();

    final mediaToUseFinal = existingMedia ?? mediaToUse;

    if (existingMedia == null) {
      await IsarDatabase.isar.writeTxn(() async {
        await IsarDatabase.isar.medias.put(mediaToUseFinal);
      });
    }

    final managedUser = await IsarDatabase.isar.users.get(currentUser.isarID);
    if (managedUser == null) return;

    await IsarDatabase.isar.writeTxn(() async {
      managedUser.profilePhotoPath = mediaToUseFinal.path;
      await IsarDatabase.isar.users.put(managedUser);
    });

    await ref.read(userController.notifier).updateUser(managedUser);
  }

  /// --- CHAT PHOTO UPDATE FLOW ---
  Future<void> _updateChatPhoto(Media mediaToUse) async {
    final chatState = ref.read(chatListProvider);
    final currentChat = chatState.selectedChat; // Assuming you have a selected chat stored

    if (currentChat == null) {
      debugPrint("⚠️ No chat selected, aborting updateChatPhoto");
      return;
    }

    final isar = IsarDatabase.isar;

    // Check if media exists
    final existingMedia = await isar.medias.filter().pathEqualTo(mediaToUse.path).findFirst();
    final mediaToUseFinal = existingMedia ?? mediaToUse;

    // Store if new
    if (existingMedia == null) {
      await isar.writeTxn(() async {
        await isar.medias.put(mediaToUseFinal);
      });
    }

    // Refetch managed chat
    final managedChat = await isar.chats.get(currentChat.isarID);
    if (managedChat == null) return;

    // Update chat photo
    await isar.writeTxn(() async {
      managedChat.chatPhotoPath = mediaToUseFinal.path;
      await isar.chats.put(managedChat);
    });

    // Refresh chat in provider
    ref.read(chatListProvider.notifier).refreshChat(managedChat.isarID);

    // Update state if necessary
    // chatState.setCurrentChat(managedChat);
  }

  void _precacheProfileImage(String? path) {
    if (path == null) return;
    try {
      precacheImage(FileImage(File(path)), context);
    } catch (e) {
      debugPrint('Error precaching profile image: $e');
    }
  }

  void _navigateBack() {
    if (mounted) {
      Navigator.of(context).pop();
    } else {
      final navCtx = navigatorKey.currentContext;
      if (navCtx != null && Navigator.of(navCtx).canPop()) {
        Navigator.of(navCtx).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing)
              const CircularProgressIndicator(color: Colors.white)
            else
              const Icon(Icons.error, color: Colors.white, size: 40),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (!_isProcessing) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateBack,
                child: const Text('Go Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
