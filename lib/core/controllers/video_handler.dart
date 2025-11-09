import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img;

class VideoHandler {
  static final Map<String, VideoHandler> controllers = {};
  
  final String videoPath;
  final VideoPlayerController _controller;
  
  bool get isInitialized => _controller.value.isInitialized;
  bool get isPlaying => _controller.value.isPlaying;
  Duration get position => _controller.value.position;
  Duration get duration => _controller.value.duration;
  double get aspectRatio => _controller.value.aspectRatio;
  VideoPlayerValue get value => _controller.value;
  
  VideoHandler._(this.videoPath, this._controller);
  
  /// Get or create a controller for a video path
  static Future<VideoHandler?> fromPath(String videoPath) async {
    // Return cached controller if exists
    if (controllers.containsKey(videoPath)) {
      return controllers[videoPath];
    }
    
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        debugPrint('❌ Video file not found: $videoPath');
        return null;
      }
      
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      
      final wrapper = VideoHandler._(videoPath, controller);
      controllers[videoPath] = wrapper;
      
      debugPrint('✅ Video initialized: $videoPath');
      return wrapper;
    } catch (e) {
      debugPrint('❌ Failed to initialize video: $e');
      return null;
    }
  }
  
  /// Play video
  Future<void> play() async {
    await _controller.play();
  }
  
  /// Pause video
  Future<void> pause() async {
    await _controller.pause();
  }
  
  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }
  
  /// Seek to position
  Future<void> seekTo(Duration position) async {
    await _controller.seekTo(position);
  }
  
  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _controller.setVolume(volume.clamp(0.0, 1.0));
  }
  
  /// Mute/unmute
  Future<void> toggleMute() async {
    final currentVolume = _controller.value.volume;
    await setVolume(currentVolume > 0 ? 0.0 : 1.0);
  }
  
  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _controller.setPlaybackSpeed(speed);
  }
  
  /// Add listener for state changes
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }
  
  /// Remove listener
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }
  
  /// Get the underlying VideoPlayerController for direct use in VideoPlayer widget
  VideoPlayerController get controller => _controller;
  
  /// Dispose a specific controller
  static void disposeController(String videoPath) {
    final controller = controllers.remove(videoPath);
    controller?._controller.dispose();
    debugPrint('🗑️ Disposed video controller: $videoPath');
  }
  
  /// Dispose all controllers (call when leaving gallery)
  static void disposeAll() {
    for (final controller in controllers.values) {
      controller._controller.dispose();
    }
    controllers.clear();
    debugPrint('🗑️ Disposed all video controllers');
  }
  
  /// Format duration to MM:SS
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}


/// Handles video metadata extraction and thumbnail generation
/// ⚡ OPTIMIZED: Video metadata handler with parallel processing
class VideoMetadataHandler {
  /// Generate complete video metadata with performance optimizations
  static Future<VideoMetadata?> generateVideoMetadata(String videoPath) async {
    try {
      debugPrint('🎬 Generating video metadata for: $videoPath');
      
      final file = File(videoPath);
      if (!await file.exists()) {
        debugPrint('❌ Video file not found: $videoPath');
        return null;
      }

      final fileSize = await file.length();
      final fileName = file.uri.pathSegments.last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // ⚡ OPTIMIZATION 1: Run video analysis and thumbnail generation in parallel
      final results = await Future.wait([
        _getVideoInfoOptimized(videoPath), // Get duration AND aspect ratio in one go
        _generateThumbnailWithBlurHashOptimized(videoPath), // Generate thumbnail
      ]);

      final videoInfo = results[0] as Map<String, dynamic>?;
      final thumbnailResult = results[1] as VideoThumbnailData?;

      if (thumbnailResult == null) {
        debugPrint('❌ Failed to generate thumbnail for: $videoPath');
        return null;
      }

      // ⚡ OPTIMIZATION 2: Save thumbnail asynchronously
      final savedThumbnailPath = await MediaHandler.saveThumbnailToStorage(
        thumbnailResult.thumbnailBytes,
        fileName,
      );

      return VideoMetadata(
        videoPath: videoPath,
        thumbnailPath: savedThumbnailPath,
        blurHash: thumbnailResult.blurHash,
        aspectRatio: videoInfo?['aspectRatio'] ?? thumbnailResult.aspectRatio,
        duration: videoInfo?['duration'] ?? Duration.zero,
        fileSize: fileSize,
        fileName: fileName,
        fileExtension: fileExtension,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating video metadata: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// ⚡ OPTIMIZED: Get duration AND aspect ratio in a single controller initialization
  static Future<Map<String, dynamic>?> _getVideoInfoOptimized(String videoPath) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      
      final result = {
        'duration': controller.value.duration,
        'aspectRatio': controller.value.aspectRatio,
      };
      
      return result;
    } catch (e) {
      debugPrint('❌ Error getting video info: $e');
      return null;
    } finally {
      // Ensure controller is always disposed
      await controller?.dispose();
    }
  }

  /// ⚡ OPTIMIZED: Generate thumbnail with blurhash using isolate for heavy processing
  static Future<VideoThumbnailData?> _generateThumbnailWithBlurHashOptimized(
    String videoPath, {
    int maxWidth = 400,
    int quality = 75,
  }) async {
    try {
      // Generate thumbnail (already optimized by plugin)
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        maxWidth: maxWidth,
        quality: quality,
      );

      if (uint8list == null) return null;

      // ⚡ OPTIMIZATION 3: Process image and generate blurhash in isolate
      final result = await compute(_processImageInIsolate, uint8list);
      
      return VideoThumbnailData(
        thumbnailBytes: uint8list,
        blurHash: result['blurHash'],
        aspectRatio: result['aspectRatio'],
      );
    } catch (e) {
      debugPrint('❌ Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Isolate function for heavy image processing
  static Map<String, dynamic> _processImageInIsolate(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final aspectRatio = image.width / image.height;
    
    // Generate blurhash (CPU-intensive operation)
    final blurHash = BlurHash.encode(
      image,
      numCompX: 4,
      numCompY: 3,
    ).hash;

    return {
      'blurHash': blurHash,
      'aspectRatio': aspectRatio,
    };
  }

  /// Format duration to HH:MM:SS or MM:SS
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Format file size to human readable string
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Check if video file exists and is accessible
  static Future<bool> validateVideoFile(String videoPath) async {
    try {
      final file = File(videoPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get video file information
  static Future<Map<String, dynamic>?> getVideoFileInfo(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      return {
        'path': videoPath,
        'size': await file.length(),
        'modified': stat.modified,
        'accessed': stat.accessed,
      };
    } catch (e) {
      debugPrint('❌ Error getting video file info: $e');
      return null;
    }
  }
}

/// Complete video metadata container
class VideoMetadata {
  final String videoPath;
  final String thumbnailPath;
  final String blurHash;
  final double aspectRatio;
  final Duration duration;
  final int fileSize;
  final String fileName;
  final String fileExtension;

  const VideoMetadata({
    required this.videoPath,
    required this.thumbnailPath,
    required this.blurHash,
    required this.aspectRatio,
    required this.duration,
    required this.fileSize,
    required this.fileName,
    required this.fileExtension,
  });

  /// Format duration for display
  String get formattedDuration => VideoMetadataHandler.formatDuration(duration);

  /// Format file size for display
  String get formattedFileSize => VideoMetadataHandler.formatFileSize(fileSize);

  /// Check if thumbnail exists
  Future<bool> get thumbnailExists async {
    try {
      final file = File(thumbnailPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Check if video file exists
  Future<bool> get videoExists async {
    return VideoMetadataHandler.validateVideoFile(videoPath);
  }
}

/// Data class for thumbnail generation result (internal use)
class VideoThumbnailData {
  final Uint8List thumbnailBytes;
  final String blurHash;
  final double aspectRatio;

  const VideoThumbnailData({
    required this.thumbnailBytes,
    required this.blurHash,
    required this.aspectRatio,
  });
}