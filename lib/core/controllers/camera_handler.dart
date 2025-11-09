import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/video_handler.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/enums/media_type.dart';

/// Handles camera operations and integrates with MediaHandler for saving.
class CameraHandler {
  CameraController? controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  /// Used to trigger preview rebuilds when controller changes
  final ValueNotifier<int> rebuildNotifier = ValueNotifier(0);
  final ValueNotifier<bool> showGrid = ValueNotifier(false);

  void toggleGrid() {
    showGrid.value = !showGrid.value;
  }

  /// Initialize the camera (front/back optional).
  Future<void> initializeCamera({
    bool enableAudio = false,
    CameraLensDirection preferredLens = CameraLensDirection.back,
  }) async {
    try {
      _cameras ??= await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No available cameras found.');
      }

      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == preferredLens,
        orElse: () => _cameras!.first,
      );

      controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: enableAudio,
      );

      await controller!.initialize();
      _isInitialized = true;
      rebuildNotifier.value++; // Trigger preview rebuild

      debugPrint('📷 Camera initialized: ${camera.lensDirection.name}');
    } catch (e, st) {
      debugPrint('❌ Camera initialization failed: $e\n$st');
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized && controller != null;
  FlashMode get flashMode => controller?.value.flashMode ?? FlashMode.off;

  /// Builds the camera preview widget.
  Widget buildPreview() {
  if (!isInitialized) {
    return const Center(child: CircularProgressIndicator());
  }

  return SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.cover, // fills the parent, crops if needed
      child: SizedBox(
        width: controller!.value.previewSize!.height, // swap if needed
        height: controller!.value.previewSize!.width,
        child: CameraPreview(controller!),
      ),
    ),
  );
}
 
  /// Capture a photo and save it under /Media/Camera/Photos.
  Future<Media?> takePhoto() async {
    if (!isInitialized) throw Exception('Camera not initialized');

    try {
      final XFile xFile = await controller!.takePicture();
      final File capturedFile = File(xFile.path);

      final File savedFile = await MediaHandler.saveToStorage(
        capturedFile,
        'Camera/Photos',
      );

      final bytes = await savedFile.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      final aspectRatio = decoded.width / decoded.height;

      final media = Media.fromFilePath(savedFile.path);
      media.type = Mediatype.image;
      media.aspectRatio = aspectRatio;

      debugPrint('📸 Photo captured and saved: ${savedFile.path}');
      return media;
    } catch (e, st) {
      debugPrint('❌ Failed to capture photo: $e\n$st');
      return null;
    }
  }

  /// Start recording a video and save it later under /Media/Camera/Videos.
  Future<void> startVideoRecording() async {
    if (!isInitialized) throw Exception('Camera not initialized');
    if (controller!.value.isRecordingVideo) return;

    try {
      await controller!.startVideoRecording();
      debugPrint('🎥 Video recording started.');
    } catch (e, st) {
      debugPrint('❌ Failed to start recording: $e\n$st');
    }
  }

  /// Stop video recording and save to /Media/Camera/Videos.
  Future<Media?> stopVideoRecording() async {
  if (!isInitialized) throw Exception('Camera not initialized');
  if (!controller!.value.isRecordingVideo) return null;

  try {
    final XFile videoFile = await controller!.stopVideoRecording();
    final File recordedFile = File(videoFile.path);

    final File savedFile = await MediaHandler.saveToStorage(
      recordedFile,
      'Camera/Videos',
    );

    // Create media with minimal metadata immediately
    final media = Media.fromVideoPath(savedFile.path, metadata: null);
    media.type = Mediatype.video;

    // Generate metadata in background
    unawaited(_generateVideoMetadataInBackground(savedFile.path, media));

    debugPrint('🎬 Video saved: ${savedFile.path}');
    return media;
  } catch (e, st) {
    debugPrint('❌ Failed to stop recording: $e\n$st');
    return null;
  }
}

/// Generate video metadata in background without blocking UI
Future<void> _generateVideoMetadataInBackground(String videoPath, Media media) async {
  try {
    final videoMetadata = await VideoMetadataHandler.generateVideoMetadata(videoPath);
    
    // Update the media object with complete metadata
    if (videoMetadata != null) {
      media.updateMetadata(
        Media.fromVideoPath(videoPath, metadata: videoMetadata),
      );
      
      // Optional: Persist to database in background
      await _persistUpdatedMedia(media);
    }
  } catch (e, st) {
    debugPrint('❌ Background metadata generation failed: $e\n$st');
  }
}

/// Persist updated media metadata to database
Future<void> _persistUpdatedMedia(Media media) async {
  try {
    final isar = IsarDatabase.isar;
    await isar.writeTxn(() async {
      await isar.medias.put(media);
    });
    debugPrint('✅ Video metadata updated in database');
  } catch (e) {
    debugPrint('❌ Failed to persist video metadata: $e');
  }
}

  /// Switches between available cameras (front ↔ back) safely.
  Future<void> switchCamera() async {
  if (controller == null) return;

  final currentLens = controller!.description.lensDirection;
  final cameras = await availableCameras();
  if (cameras.isEmpty) return;

  final newDescription = cameras.firstWhere(
    (cam) => cam.lensDirection != currentLens,
    orElse: () => cameras.first,
  );

  // Save old controller
  final oldController = controller;

  // Dispose old controller first, but wait until fully released
  if (oldController != null && oldController.value.isInitialized) {
    await oldController.dispose();
    await Future.delayed(const Duration(milliseconds: 300)); // Xiaomi/Samsung safe delay
  }

  // Initialize new controller
  final newController = CameraController(
    newDescription,
    ResolutionPreset.high,
    enableAudio: false,
  );

  try {
    await newController.initialize();
    controller = newController;
    _isInitialized = true;
    rebuildNotifier.value++;
    debugPrint('🔁 Switched to ${controller!.description.lensDirection.name}');
  } catch (e, st) {
    debugPrint('❌ Failed to switch camera: $e\n$st');
  }
}



  /// Clean up resources.
  void dispose() {
    controller?.dispose();
    _isInitialized = false;
  }
}
