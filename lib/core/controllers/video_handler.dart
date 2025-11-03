import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img;

class VideoHandler {
  static final Map<String, VideoHandler> _controllers = {};
  
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
    if (_controllers.containsKey(videoPath)) {
      return _controllers[videoPath];
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
      _controllers[videoPath] = wrapper;
      
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
    final controller = _controllers.remove(videoPath);
    controller?._controller.dispose();
    debugPrint('🗑️ Disposed video controller: $videoPath');
  }
  
  /// Dispose all controllers (call when leaving gallery)
  static void disposeAll() {
    for (final controller in _controllers.values) {
      controller._controller.dispose();
    }
    _controllers.clear();
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
class VideoMetadataHandler {
  /// Generate complete video metadata including thumbnail, blurhash, aspect ratio, etc.
  static Future<VideoMetadata?> generateVideoMetadata(String videoPath) async {
    try {
      debugPrint('🎬 Generating video metadata for: $videoPath');
      
      // Get basic file info
      final file = File(videoPath);
      if (!await file.exists()) {
        debugPrint('❌ Video file not found: $videoPath');
        return null;
      }

      final fileSize = await file.length();
      final fileName = file.uri.pathSegments.last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Get video duration and aspect ratio
      final duration = await _getVideoDuration(videoPath);
      final aspectRatio = await _getVideoAspectRatio(videoPath);

      // Generate thumbnail and blurhash
      final thumbnailResult = await _generateThumbnailWithBlurHash(videoPath);
      
      if (thumbnailResult == null) {
        debugPrint('❌ Failed to generate thumbnail for: $videoPath');
        return null;
      }

      // Save thumbnail to Thumbnails subfolder
      final savedThumbnailPath = await MediaHandler.saveThumbnailToStorage(
        thumbnailResult.thumbnailBytes,
        fileName,
      );

      return VideoMetadata(
        videoPath: videoPath,
        thumbnailPath: savedThumbnailPath,
        blurHash: thumbnailResult.blurHash,
        aspectRatio: aspectRatio ?? thumbnailResult.aspectRatio,
        duration: duration ?? Duration.zero,
        fileSize: fileSize,
        fileName: fileName,
        fileExtension: fileExtension,
      );
    } catch (e) {
      debugPrint('❌ Error generating video metadata: $e');
      return null;
    }
  }

  /// Get video duration without keeping controller alive
  static Future<Duration?> _getVideoDuration(String videoPath) async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (e) {
      debugPrint('❌ Error getting video duration: $e');
      return null;
    }
  }

  /// Get video aspect ratio
  static Future<double?> _getVideoAspectRatio(String videoPath) async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      final aspectRatio = controller.value.aspectRatio;
      await controller.dispose();
      return aspectRatio;
    } catch (e) {
      debugPrint('❌ Error getting video aspect ratio: $e');
      return null;
    }
  }

  /// Generate thumbnail and blurhash from video
  static Future<VideoThumbnailData?> _generateThumbnailWithBlurHash(
    String videoPath, {
    int maxWidth = 400,
    int quality = 75,
  }) async {
    try {
      // Generate thumbnail
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        maxWidth: maxWidth,
        quality: quality,
      );

      if (uint8list == null) return null;

      // Decode image to get dimensions and generate blurhash
      final image = img.decodeImage(uint8list);
      if (image == null) return null;

      final aspectRatio = image.width / image.height;

      // Generate blurhash
      final blurHash = BlurHash.encode(
        image,
        numCompX: 4,
        numCompY: 3,
      ).hash;

      return VideoThumbnailData(
        thumbnailBytes: uint8list,
        blurHash: blurHash,
        aspectRatio: aspectRatio,
      );
    } catch (e) {
      debugPrint('❌ Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Save thumbnail to Thumbnails subfolder using your MediaHandler pattern
  static Future<String> _saveThumbnailToStorage(
    Uint8List thumbnailBytes,
    String originalFileName,
  ) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'thumb_${originalFileName.split('.').first}.png';
      final String thumbnailsDirPath = '${appDir.path}/Media/Thumbnails';
      
      // Create Thumbnails directory if it doesn't exist
      final Directory thumbnailsDir = Directory(thumbnailsDirPath);
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      final String thumbnailPath = '$thumbnailsDirPath/$fileName';
      final File thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      debugPrint('✅ Thumbnail saved: $thumbnailPath');
      return thumbnailPath;
    } catch (e) {
      debugPrint('❌ Error saving thumbnail: $e');
      // Fallback to temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.png';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(thumbnailBytes);
      return tempPath;
    }
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