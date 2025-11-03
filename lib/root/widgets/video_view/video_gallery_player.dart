import 'package:flutter/material.dart';
import 'package:notesapp/core/controllers/video_handler.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:video_player/video_player.dart';


const sample = "D:/Pictures/Redmi September - October 2025/Snapchat/Snapchat-781898565.mp4";
const samplePhone = "/storage/emulated/0/DCIM/Snapchat/Snapchat-932215042.mp4";

class VideoGalleryPlayer extends StatefulWidget {
  final Media media;
  
  const VideoGalleryPlayer({super.key, required this.media});

  @override
  State<VideoGalleryPlayer> createState() => _VideoGalleryPlayerState();
}

class _VideoGalleryPlayerState extends State<VideoGalleryPlayer> {
  VideoHandler? _videoController;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.media.path == null) return;
    final controller = await VideoHandler.fromPath(widget.media.path!);
    if (controller != null && mounted) {
      setState(() => _videoController = controller);
      // Auto-play
      await controller.play();
    }
  }

  @override
  void dispose() {
    // Don't dispose here - let GalleryViewWrapper handle it
    VideoHandler.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoController == null || !_videoController!.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.aspectRatio,
              child: VideoPlayer(_videoController!.controller),
            ),
          ),
          AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            opacity: _showControls ? 1.0 : 0.0,
            child: _buildControls()),
        ],
      ),
    );
  }

  Widget _buildControls() {
    // Your control UI here
    return Container(
      color: Colors.black38,
      child: Center(
        child: IconButton(
          onPressed: () {
            _videoController?.togglePlayPause();
            setState(() {});
          },
          icon: Icon(
            _videoController!.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 64,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}