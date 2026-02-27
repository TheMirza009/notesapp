

import 'package:flutter/material.dart';
import 'package:notesapp/core/controllers/video_handler.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:video_player/video_player.dart';


const sample = "D:/Pictures/Redmi September - October 2025/Snapchat/Snapchat-781898565.mp4";
const samplePhone = "/storage/emulated/0/DCIM/Snapchat/Snapchat-932215042.mp4";


class VideoGalleryPlayer extends StatefulWidget {
  final Media media;
  final bool? directPlay;
  final VoidCallback? onVideoCompleted;
  final VoidCallback? onControllerInitialized;
  
  const VideoGalleryPlayer({
    super.key,
    required this.media,
    this.directPlay = false,
    this.onVideoCompleted,
    this.onControllerInitialized,
  });

  @override
  State<VideoGalleryPlayer> createState() => _VideoGalleryPlayerState();
}

class _VideoGalleryPlayerState extends State<VideoGalleryPlayer> {
  VideoHandler? _videoController;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    if (widget.media.path == null) return;
    final controller = await VideoHandler.fromPath(widget.media.path!);
    if (controller != null && mounted) {
      setState(() => _videoController = controller);
      controller.addListener(_handleVideoStateChange);
      widget.onControllerInitialized?.call();
      if (widget.directPlay == true) {
        await controller.play();
      }
    }
  }

  @override
  void dispose() {
    // Don't dispose the controller here - let GalleryViewWrapper handle it
    // The VideoHandler maintains its own cache
    super.dispose();
  }

  void _handleVideoStateChange() {
    if (!mounted) return;
    
    final videoCompleted = _videoController?.value.position == _videoController?.value.duration;
    if (videoCompleted) {
      _videoController?.pause();
      widget.onVideoCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videoController == null || !_videoController!.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return AspectRatio(
      aspectRatio: widget.media.aspectRatio ?? _videoController!.aspectRatio,
      child: VideoPlayer(_videoController!.controller),
    );
  }
}