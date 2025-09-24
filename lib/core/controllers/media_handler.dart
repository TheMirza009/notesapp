import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
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
    // Pick image from gallery
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    File file = File(pickedFile.path);

    // Optional cropping for profile pictures
    if (isProfilePicture && !kisWindows) {
      final croppedFile = await _cropImage(file);
      if (croppedFile != null) file = croppedFile;
    }

    // Save file to storage folder
    final savedFile = await _saveToStorage(file, isProfilePicture ? 'Profile Pictures' : 'Photos');

    // Compute aspect ratio
    final bytes = await savedFile.readAsBytes();
    final decodedImage = await decodeImageFromList(bytes);
    final aspectRatio = decodedImage.width / decodedImage.height;

    // Create Media object with aspect ratio
    final media = Media.fromFilePath(savedFile.path);
    media.aspectRatio = aspectRatio;

    return media;
  }

  static Future<Media> fromImageBytes(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = "pasted_${DateTime.now().millisecondsSinceEpoch}";
    final file = File("${tempDir.path}/$fileName");
    await file.writeAsBytes(bytes);

    final decodedImage = await decodeImageFromList(bytes);
    final aspectRatio = decodedImage.width / decodedImage.height;

    final media = Media();
    media.name = fileName;
    media.path = file.path;
    media.extension = "gif";
    media.type = Mediatype.image;
    media.aspectRatio = aspectRatio;

    return media;
  }

  /// Function to pick Media files instead of images
  static Future<Media?> pickMedia({bool isProfilePicture = false}) async {
    // Pick GIFs or images
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
    );

    if (result == null || result.files.isEmpty) return null;

    File file = File(result.files.single.path!);

    // Optional crop (only for still images, not GIFs)
    if (isProfilePicture &&
        !kisWindows &&
        !file.path.toLowerCase().endsWith('.gif')) {
      final croppedFile = await _cropImage(file);
      if (croppedFile != null) file = croppedFile;
    }

    // Save to storage folder
    final savedFile = await _saveToStorage(
      file,
      isProfilePicture ? 'Profile Pictures' : 'Photos',
    );

    double? aspectRatio;
    if (!savedFile.path.toLowerCase().endsWith('.gif')) {
      // Decode aspect ratio only for still images
      final bytes = await savedFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      aspectRatio = decodedImage.width / decodedImage.height;
    }

    // Create Media object
    final media = Media.fromFilePath(savedFile.path);
    media.aspectRatio = aspectRatio;

    return media;
  }




  /// Pick a video → saved in Media/Videos
  static Future<Media?> pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    final savedFile = await _saveToStorage(File(pickedFile.path), 'Videos');
    return Media.fromFilePath(savedFile.path);
  }

  /// Pick a document → saved in Media/Documents
  static Future<Media?> pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final savedFile = await _saveToStorage(file, 'Documents');
    return Media.fromFilePath(savedFile.path);
  }

  /// Find and delete a media file from storage (if local).
  static Future<void> deleteMedia(Media media) async {
    final filePath = media.path;
    if (filePath == null) return; // Remote link or null, nothing to delete

    final file = File(filePath);
    if (await file.exists()) {
      try {
        await file.delete();
        print("Deleted file: ${media.name}");
      } catch (e) {
        debugPrint("Failed to delete media file at $filePath: $e");
      }
    }
  }


  /// ===== Helpers =====

  /// Cropping logic
  static Future<File?> _cropImage(File imageFile) async {
    final context = navigatorKey.currentContext!;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Chat Photo',
          toolbarColor: context.isLight ? const Color(0xFFF4F8F8) : ThemeConstants.darkAppbar,
          toolbarWidgetColor: context.isLight ? ThemeConstants.textLight : ThemeConstants.toolbarLight,
          activeControlsWidgetColor: ThemeConstants.sinisterSeed,
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
