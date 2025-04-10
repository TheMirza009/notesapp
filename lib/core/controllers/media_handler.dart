import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';

class MediaHandler {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image (cropped and/or saved for profile pictures or optional cropping for general use)
  static Future<Media?> pickImage({
    required BuildContext context,
    bool profilePicture = false,
    bool crop = false,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, // Use ImageSource.camera for camera
    );

    if (pickedFile == null) return null;

    File imageFile = File(pickedFile.path);

    if (profilePicture || crop) {
      imageFile = (await _cropAndSave(imageFile)) ?? imageFile;
    }

    return _toMedia(imageFile);
  }

  /// Pick a video
  static Future<Media?> pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    return _toMedia(File(pickedFile.path));
  }

  /// Pick a document
  static Future<Media?> pickDocument() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, // Supports file picking
    );
    if (pickedFile == null) return null;
    return _toMedia(File(pickedFile.path));
  }

  /// Helper: Crop and save image
  static Future<File?> _cropAndSave(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: ThemeConstants.iconLight,
            toolbarWidgetColor: ThemeConstants.toolbarLight,
            activeControlsWidgetColor:  ThemeConstants.iconLight,
            initAspectRatio: CropAspectRatioPreset.square,
            aspectRatioPresets: [CropAspectRatioPreset.square],
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
    );
    if (croppedFile != null) {
      return await _saveToStorage(File(croppedFile.path), 'profile_picture.jpg');
    }
    return null;
  }

  /// Helper: Save file to app's storage
  static Future<File> _saveToStorage(File file, String fileName) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final newPath = '${appDir.path}/$fileName';
    return file.copy(newPath);
  }

  /// Helper: Convert File to Media instance
  static Media _toMedia(File file) {
    final String name = file.uri.pathSegments.last;
    final String? mimeType = lookupMimeType(file.path);
    final String extension = mimeType?.split('/').last ?? 'unknown';
    return Media(name: name, content: file, extension: extension);
  }
}