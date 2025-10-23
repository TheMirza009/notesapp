import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/user_provider.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/user_model.dart';
import 'package:notesapp/root/widgets/photo_view/croppyImage.dart';

class CropScreen extends ConsumerStatefulWidget {
  const CropScreen({super.key});

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

      // Step 2: Crop and save the photo
      // final croppedMedia = await MediaHandler.cropAndSavePhoto(
      //   pickedMedia.path!,
      //   isProfilePicture: true,
      // );

      // if (croppedMedia == null) {
      //   debugPrint("❌ Failed to crop image");
      //   _navigateBack();
      //   return;
      // }

      debugPrint("✅ Cropped media: ${pickedMedia.path}");
      setState(() {
        _status = 'Updating profile...';
      });

      // Step 3: Update user profile with the cropped image
      await _updateUserProfile(pickedMedia);

      // Step 4: Precache the new profile image
      _precacheProfileImage(pickedMedia.path);

      debugPrint("🎉 Profile photo updated successfully");
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

  Future<void> _updateUserProfile(Media mediaToUse) async {
    final currentUser = ref.read(userController);
    debugPrint("💳 Current User: ${currentUser.toString()}");
    if (currentUser == null) return;

    // Check if this media already exists in DB by path
    final existingMedia = await IsarDatabase.isar.medias
        .filter()
        .pathEqualTo(mediaToUse.path)
        .findFirst();
    
    final mediaToUseFinal = existingMedia ?? mediaToUse;

    // Persist only if it's new
    if (existingMedia == null) {
      await IsarDatabase.isar.writeTxn(() async {
        await IsarDatabase.isar.medias.put(mediaToUseFinal);
      });
    }

    // Always re-fetch the managed User from Isar
    final managedUser = await IsarDatabase.isar.users.get(currentUser.isarID);
    debugPrint("🗄️ DB says user.photo = ${managedUser?.profilePhotoPath}");

    if (managedUser == null) return;

    // Update user with new profile photo
    await IsarDatabase.isar.writeTxn(() async {
      managedUser.profilePhotoPath = mediaToUseFinal.path;
      await IsarDatabase.isar.users.put(managedUser);
    });

    // Update state in provider
    await ref.read(userController.notifier).updateUser(managedUser);
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
              CircularProgressIndicator(color: Colors.white)
            else
              Icon(Icons.error, color: Colors.white, size: 40),
            SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (!_isProcessing) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateBack,
                child: Text('Go Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}