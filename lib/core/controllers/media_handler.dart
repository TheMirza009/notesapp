import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:croppy/croppy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:isar_community/isar.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/blurhash_service.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/recording_handler.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/widgets/crop/croppyImage.dart';
import 'package:notesapp/root/widgets/photo_view/croppy_settings_modal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class MediaHandler {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image.
  /// - If [isProfilePicture] = true → crop + save to ProfilePictures.
  /// - Else → save to Photos.
  static Future<Media?> pickImage({
    bool isProfilePicture = false,
    ImageSource? source = ImageSource.gallery,
    bool? useCroppy = false,
    bool? navigateToCrop = false,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source ?? ImageSource.gallery,
    );
    if (pickedFile == null) {
      debugPrint("⚠️ No image picked");
      return null;
    }

    File file = File(pickedFile.path);
    debugPrint("✅ Picked file: ${file.path}");

    if ((useCroppy ?? false) && !kisWindows) {
      final croppedFile = (useCroppy ?? false) ? await _croppyImage(file, navigate: (navigateToCrop ?? false), showCircle: isProfilePicture) : await _cropImage(file); //_croppyImage(file);
      if (croppedFile != null) {
        debugPrint("✂️ Cropped file: ${croppedFile.path}");
        file = croppedFile;
      } else {
        debugPrint("❌ Cropper returned null");
        return null;
      }
    }

    final savedFile = await saveToStorage(
      file,
      isProfilePicture ? 'Profile Pictures' : 'Photos',
    );
    debugPrint("💾 Saved file: ${savedFile.path}");

    // ✅ Generate blurHash in background (don't wait for it)
    unawaited(_generateAndStoreBlurHash(savedFile.path));

    final bytes = await savedFile.readAsBytes();
    final decodedImage = await decodeImageFromList(bytes);
    final aspectRatio = decodedImage.width / decodedImage.height;

    final media = Media.fromFilePath(savedFile.path);
    media.aspectRatio = aspectRatio;

    debugPrint("🎉 Returning media with path: ${media.path}");
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
        debugPrint("Deleted file: ${media.name}");
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
  /// 
  /// Crop existing photo
  static Future<Media?> cropAndSavePhoto(
    String filePath, {
    bool isProfilePicture = true,
    bool navigate = false,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint("❌ cropAndSavePhoto: File not found at $filePath");
        return null;
      }

      debugPrint("✂️ Starting crop for: $filePath");
      final croppedFile = await _croppyImage(file, navigate: navigate, showCircle: isProfilePicture);
      if (croppedFile == null) {
        debugPrint("⚠️ cropAndSavePhoto: Cropper returned null");
        return null;
      }

      debugPrint("✅ Cropped file: ${croppedFile.path}");
      final savedFile = await saveToStorage(
        croppedFile,
        isProfilePicture ? 'Profile Pictures' : 'Photos',
      );

      debugPrint("💾 Saved cropped file: ${savedFile.path}");

      // ✅ Use the same reliable method as pickImage
      final bytes = await savedFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      final aspectRatio = decodedImage.width / decodedImage.height;

      final media = Media.fromFilePath(savedFile.path);
      media.aspectRatio = aspectRatio;

      debugPrint("🎉 Returning cropped media with path: ${media.path}");
      return media;
    } catch (e, st) {
      debugPrint("🔥 cropAndSavePhoto error: $e\n$st");
      return null;
    }
  }

  /// Static helper for compute() to use
  static Future<double?> _getAspectRatio(String path) async {
  final file = File(path);
  final bytes = await file.openRead(16, 24).fold<Uint8List>(
    Uint8List(0),
    (prev, chunk) => Uint8List.fromList([...prev, ...chunk]),
  );
  if (bytes.length < 8) return null;

  // PNG header starts at byte 16 for width, 20 for height
  final width = bytes.buffer.asByteData().getUint32(0);
  final height = bytes.buffer.asByteData().getUint32(4);
  if (width == 0 || height == 0) return null;
  return width / height;
}

  static Future<void> _ensureFileReady(File file) async {
    const maxWait = Duration(seconds: 2);
    const pollInterval = Duration(milliseconds: 50);

    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < maxWait) {
      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) return; // ✅ file ready
      }
      await Future.delayed(pollInterval);
    }
    throw Exception("File never became ready: ${file.path}");
  }



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

  /// ✂️ Improved Croppy-based image cropping with proper storage
  static Future<File?> _croppyImage(File imageFile, {bool navigate = false, bool showCircle = false}) async {
    final ctx = navigatorKey.currentContext!;
    if (ctx == null || !ctx.mounted) return null;
    final result = await cropImageWithCroppy(
      forceCircle: showCircle,
      context: ctx,
      heroTag: "profile-avatar-crop",
      path: imageFile.path,
      settings: showCircle == true ? CropSettings.initial().copyWith(showGestureHandlesOn: [CropShapeType.ellipse],) : CropSettings.initial(),
      useCupertino: true,
    );

    if (result == null) return null;

    try {
      // Convert to byte data
      final byteData = await result.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        debugPrint("❌ Failed to get byte data from cropped image");
        result.image.dispose();
        return null;
      }

      final buffer = byteData.buffer.asUint8List();

      // ✅ Use saveToStorage directly instead of temp directory
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = imageFile.uri.pathSegments.last.split('.').first;
      final tempCroppedFile = File(
        '${(await getTemporaryDirectory()).path}/cropped_${timestamp}.png',
      );

      // Write to temp file first (required for saveToStorage which uses file.copy)
      await tempCroppedFile.writeAsBytes(buffer, flush: true);

      // ✅ Now save to proper storage using your existing method
      final savedCroppedFile = await saveToStorage(
        tempCroppedFile,
        'Cropped Photos', // Or 'Profile Pictures' if it's for profile
      );

      // Clean up temp file
      await tempCroppedFile.delete();

      debugPrint("✅ Cropped image saved to: ${savedCroppedFile.path}");

      result.image.dispose();
      return savedCroppedFile;
    } catch (e, st) {
      debugPrint("🔥 Error in _croppyImage: $e\n$st");
      result.image.dispose();
      return null;
    }
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

  static Future<void> _generateAndStoreBlurHash(String imagePath) async {
    try {
      final blurHash = await BlurHashService.generateBlurHash(imagePath);
      if (blurHash != null) {
        // Update in database
        final isar = IsarDatabase.isar;
        final media =
            await isar.medias.filter().pathEqualTo(imagePath).findFirst();
        if (media != null) {
          await isar.writeTxn(() async {
            media.blurHash = blurHash;
            await isar.medias.put(media);
          });
          debugPrint(
            '✅ BlurHash generated and stored: ${blurHash.substring(0, 20)}...',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error storing blurHash: $e');
    }
  }

  /// (Optional) Compress image before saving (stub)
  // static Future<File?> _compressImage(File file) async {
  //   final XFile? result = await FlutterImageCompress.compressAndGetFile(
  //     file.absolute.path,
  //     "${file.parent.path}/compressed_${file.uri.pathSegments.last}",
  //     quality: 70,
  //   );

  //   return result != null ? File(result.path) : null;
  // }
}

