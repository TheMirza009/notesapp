import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // uncomment if using compression

class MediaHandler {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image.
  /// - If [isProfilePicture] = true → crop + save to ProfilePictures.
  /// - Else → save to Photos.
  static Future<Media?> pickImage({bool isProfilePicture = false}) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    File file = File(pickedFile.path);

    if (isProfilePicture) {
      final cropped = await _cropImage(file);
      file = cropped ?? file;
      file = await _saveToStorage(file, 'Profile Pictures');
    } else {
      file = await _saveToStorage(file, 'Photos');
    }

    return Media.fromFile(file);
  }

  /// Crop an existing image and save into Photos/Cropped
  static Future<Media?> cropImage(File imageFile) async {
    final File? cropped = await _cropImage(imageFile);
    if (cropped == null) return null;

    final savedFile = await _saveToStorage(cropped, 'Photos/Cropped');
    return Media.fromFile(savedFile);
  }

  /// Pick a video → saved in Media/Videos
  static Future<Media?> pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    final savedFile = await _saveToStorage(File(pickedFile.path), 'Videos');
    return Media.fromFile(savedFile);
  }

  /// Pick a document → saved in Media/Documents
  static Future<Media?> pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final savedFile = await _saveToStorage(file, 'Documents');
    return Media.fromFile(savedFile);
  }

  /// Find and Delete given file based on its storage path
  static Future<void> deleteMedia(Media media) async {
    if (media.content != null && await media.content!.exists()) {
      try {
        await media.content!.delete();
      } catch (e) {
        debugPrint("Failed to delete media file: $e");
      }
    }
  }

  /// ===== Helpers =====

  /// Cropping logic
  static Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: ThemeConstants.iconLight,
          toolbarWidgetColor: ThemeConstants.toolbarLight,
          activeControlsWidgetColor: ThemeConstants.iconLight,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  /// Save file into app storage under Media/<subfolder>/
  static Future<File> _saveToStorage(File file, String subfolder) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory mediaDir = Directory('${appDir.path}/Media/$subfolder');

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final String fileName = file.uri.pathSegments.last;
    final String newPath = '${mediaDir.path}/$fileName';

    return file.copy(newPath);
  }

  /// (Optional) Compress image before saving (stub)
  static Future<File?> _compressImage(File file) async {
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      "${file.parent.path}/compressed_${file.uri.pathSegments.last}",
      quality: 70,
    );

    return result != null ? File(result.path) : null;
  }
}
