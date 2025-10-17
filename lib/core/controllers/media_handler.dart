import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/recording_handler.dart';
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
  static Future<Media?> pickImage({bool isProfilePicture = false, ImageSource? source = ImageSource.gallery}) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source ?? ImageSource.gallery,
    );
    if (pickedFile == null) {
      print("⚠️ No image picked");
      return null;
    }

    File file = File(pickedFile.path);
    print("✅ Picked file: ${file.path}");

    if (isProfilePicture && !kisWindows) {
      final croppedFile = await _cropImage(file);
      if (croppedFile != null) {
        print("✂️ Cropped file: ${croppedFile.path}");
        file = croppedFile;
      } else {
        print("❌ Cropper returned null");
      }
    }

    final savedFile = await saveToStorage(
      file,
      isProfilePicture ? 'Profile Pictures' : 'Photos',
    );
    print("💾 Saved file: ${savedFile.path}");

    final bytes = await savedFile.readAsBytes();
    final decodedImage = await decodeImageFromList(bytes);
    final aspectRatio = decodedImage.width / decodedImage.height;

    final media = Media.fromFilePath(savedFile.path);
    media.aspectRatio = aspectRatio;

    print("🎉 Returning media with path: ${media.path}");
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
    final savedFile = await saveToStorage(
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
    final savedFile = await saveToStorage(File(pickedFile.path), 'Videos');
    return Media.fromFilePath(savedFile.path);
  }

  /// Pick a document → saved in Media/Documents
  static Future<Media?> pickDocument({FileType? fileType}) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: fileType ?? FileType.any,
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final savedFile = await saveToStorage(file, 'Documents');
    return Media.fromFilePath(savedFile.path);
  }

  /// Pick Audio -> save to Media/Audio
  static Future<Media?> saveAudio(String audioPath) async {
    // final audioPath = await Recorder().stopRecording();
    if (audioPath == null) return null;

    final savedFile = await saveToStorage(File(audioPath), 'Audio');
    return Media.fromFilePath(savedFile.path);
  }

  /// Save recorded Audio
  static Future<Media?> pickAudio() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final savedFile = await saveToStorage(file, 'Audio');
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

  /// Handle a received shared file (from intent or another source).
  /// Saves the file and returns a fully populated [Media] object.
  /// If the file is an image, calculates its aspect ratio.
  static Future<Media?> handleReceivedMedia(
    String filePath, {
    String baseFolder = 'Media',
  }) async {
    if (filePath.isEmpty) return null;

    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint("⚠️ Received file does not exist at path: $filePath");
      return null;
    }

    // Determine subfolder by type (image/video/audio/document) automatically
    final media = Media.fromFilePath(filePath);
    String subfolder;
    switch (media.type) {
      case Mediatype.image:
        subfolder = 'Photos';
        break;
      case Mediatype.video:
        subfolder = 'Videos';
        break;
      case Mediatype.audio:
        subfolder = 'Audio';
        break;
      case Mediatype.document:
      case Mediatype.text:
      case Mediatype.unknown:
      default:
        subfolder = 'Documents';
    }

    // Save file into storage
    final savedFile = await saveToStorage(
      file,
      subfolder,
      baseFolder: baseFolder,
    );
    media.path = savedFile.path;

    // Decode aspect ratio only for still images (not GIFs)
    if (media.type == Mediatype.image &&
        !savedFile.path.toLowerCase().endsWith('.gif')) {
      try {
        final bytes = await savedFile.readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);
        media.aspectRatio = decodedImage.width / decodedImage.height;
      } catch (e) {
        debugPrint("⚠️ Failed to decode image aspect ratio: $e");
      }
    }

    debugPrint("✅ Received file handled: $media");
    return media;
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
  static Future<File> saveToStorage(
    File file,
    String subfolder, {
    String baseFolder = 'Media',
  }) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory targetDir = Directory(
      '${appDir.path}/$baseFolder/$subfolder',
    );

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final String fileName = file.uri.pathSegments.last;
    final String newPath = '${targetDir.path}/$fileName';

    return file.copy(newPath);
  }

  // static Future<File> saveTemporary(
  //   File file, {
  //   String baseFolder = 'Media',
  // }) async {
  //   final Directory appDir = await getApplicationDocumentsDirectory();
  //   final Directory targetDir = Directory(
  //     '${appDir.path}/$baseFolder/temporary',
  //   );

  //   if (!await targetDir.exists()) {
  //     await targetDir.create(recursive: true);
  //   }

  //   final String fileName = file.uri.pathSegments.last;
  //   final String newPath = '${targetDir.path}/$fileName';

  //   return file.copy(newPath);
  // }

  // static Future<String> getTemporaryDirectoryPath() async {
  //   final Directory appDir = await getApplicationDocumentsDirectory();
  //   final Directory targetDir = Directory(
  //     '${appDir.path}/Media/temporary',
  //   );

  //   if (!await targetDir.exists()) {
  //     await targetDir.create(recursive: true);
  //   }
  //   return targetDir.path;
  // }

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
