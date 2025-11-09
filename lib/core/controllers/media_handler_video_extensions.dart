import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/video_handler.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:path_provider/path_provider.dart';

class MediaHandlerVideoExtensions extends MediaHandler {
  static final ImagePicker _picker = ImagePicker();

  /// OPTION 1: Wait for full metadata (optimized but still waits)
  static Future<Media?> pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return null;

    // Save video file
    final savedFile = await saveToStorage(File(pickedFile.path), 'Videos');

    // Generate metadata with optimizations (faster but still waits)
    final videoMetadata = await VideoMetadataHandler.generateVideoMetadata(
      savedFile.path,
    );

    return Media.fromVideoPath(savedFile.path, metadata: videoMetadata);
  }

  /// OPTION 2: Return immediately with null metadata, process in background
  static Future<Media?> pickVideoFast({
    Function(VideoMetadata?)? onMetadataReady,
  }) async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return null;

    // Save video file
    final savedFile = await saveToStorage(File(pickedFile.path), 'Videos');

    // Return immediately with null metadata
    final media = Media.fromVideoPath(savedFile.path, metadata: null);

    // Process metadata in background
    VideoMetadataHandler.generateVideoMetadata(savedFile.path).then((metadata) {
      if (metadata != null && onMetadataReady != null) {
        onMetadataReady(metadata);
      }
    }).catchError((e) {
      debugPrint('❌ Background metadata generation failed: $e');
    });

    return media;
  }

  /// OPTION 3: Hybrid - Generate minimal metadata fast, full metadata in background
  static Future<Media?> pickVideoHybrid({
    Function(VideoMetadata?)? onFullMetadataReady,
  }) async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return null;

    // Save video file
    final savedFile = await saveToStorage(File(pickedFile.path), 'Videos');

    // Get minimal info immediately (just file stats, no video processing)
    final file = File(savedFile.path);
    final fileSize = await file.length();
    final fileName = file.uri.pathSegments.last;
    final fileExtension = fileName.split('.').last.toLowerCase();

    // Create media with minimal metadata
    final minimalMetadata = VideoMetadata(
      videoPath: savedFile.path,
      thumbnailPath: '', // Will be updated
      blurHash: '', // Will be updated
      aspectRatio: 16 / 9, // Default
      duration: Duration.zero, // Will be updated
      fileSize: fileSize,
      fileName: fileName,
      fileExtension: fileExtension,
    );

    final media = Media.fromVideoPath(savedFile.path, metadata: minimalMetadata);

    // Generate full metadata in background
    VideoMetadataHandler.generateVideoMetadata(savedFile.path).then((fullMetadata) {
      if (fullMetadata != null && onFullMetadataReady != null) {
        onFullMetadataReady(fullMetadata);
      }
    }).catchError((e) {
      debugPrint('❌ Background metadata generation failed: $e');
    });

    return media;
  }

  static Future<File> saveToStorage(File file, String subfolder) async {
    // Your existing implementation
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${appDir.path}/Media/$subfolder';
    final Directory dir = Directory(dirPath);
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
    final String newPath = '$dirPath/$fileName';
    final File newFile = await file.copy(newPath);
    
    return newFile;
  }

  /// ⚡ OPTIMIZED: Save thumbnail with async I/O
  static Future<String> saveThumbnailToStorage(
    Uint8List thumbnailBytes,
    String originalFileName,
  ) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'thumb_${originalFileName.split('.').first}.png';
      final String thumbnailsDirPath = '${appDir.path}/Media/Thumbnails';
      
      // Create directory if needed
      final Directory thumbnailsDir = Directory(thumbnailsDirPath);
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      final String thumbnailPath = '$thumbnailsDirPath/$fileName';
      final File thumbnailFile = File(thumbnailPath);
      
      // ⚡ Write asynchronously
      await thumbnailFile.writeAsBytes(thumbnailBytes, flush: true);

      debugPrint('✅ Thumbnail saved: $thumbnailPath');
      return thumbnailPath;
    } catch (e) {
      debugPrint('❌ Error saving thumbnail: $e');
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.png';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(thumbnailBytes);
      return tempPath;
    }
  }
}