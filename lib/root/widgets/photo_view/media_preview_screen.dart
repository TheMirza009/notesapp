import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/video_handler.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/widgets/video_view/seek_indicators.dart';
import 'package:notesapp/root/widgets/video_view/video_gallery_player.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewScreen extends StatefulWidget {
  final Media media;
  final VoidCallback? onSend;
  final VoidCallback? onCancelled;
  final Function(Media image)? onCropped;

  const MediaPreviewScreen({
    super.key,
    required this.media,
    this.onSend,
    this.onCancelled,
    this.onCropped,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  bool showOverlay = true;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.media.isVideo) {
        Future.delayed(Duration(milliseconds: 900), () => toggleOverlay());
      }
    });
  }

  void toggleOverlay() {
    setState(() => showOverlay = !showOverlay);
  }

  void _onVideoCompleted() {
    if (mounted) {
      setState(() => showOverlay = true);

      // Auto-pause when video completes
      final videoController = VideoHandler.controllers[widget.media.path!];
      videoController?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.black,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: showOverlay ? 1.0 : 0.0,
          child: AppBar(
            backgroundColor: Colors.black26,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                VideoHandler.disposeController(widget.media.path!);
                widget.onCancelled?.call(); // This will trigger the modal's pop
              },
            ),
            title: Text(
              widget.media.isVideo ? 'Video Preview' : 'Image Preview',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              if (widget.media.isImage && widget.onCropped != null)
                TextButton(
                  onPressed: () => widget.onCropped!(widget.media),
                  child: const Text(
                    'CROP',
                    style: TextStyle(color: ThemeConstants.sinisterSeedHighlight),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: toggleOverlay,
          child: PhotoViewGallery.builder(
            itemCount: 1,
            builder: (context, index) {
              if (widget.media.isVideo) {
                final videoController = VideoHandler.controllers[widget.media.path!];
                return PhotoViewGalleryPageOptions.customChild(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video player without controls
                      VideoGalleryPlayer(
                        media: widget.media,
                        directPlay: true, // Only autoplay initial video
                        onVideoCompleted: _onVideoCompleted,
                        onControllerInitialized: () => setState(() {}),
                      ),
                      // Video controls managed by GalleryViewWrapper
                      // if (showOverlay)
                        Positioned.fill(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            color: showOverlay ? Colors.black38 : Colors.transparent,
                            child: Center(
                              child: _buildVideoControls(widget.media),
                            ),
                          ),
                        ),

                       if (videoController != null && videoController.isInitialized)
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SeekIndicator(
                onTap: toggleOverlay,
                onDoubleTap: () {
                  if (videoController.isInitialized) {
                    videoController.seekTo(videoController.position - Duration(seconds: 5));
                  }
                },
              ),
              SeekIndicator(
                forward: true,
                onTap: toggleOverlay,
                onDoubleTap: () {
                  if (videoController.isInitialized) {
                    videoController.seekTo(videoController.position + Duration(seconds: 5));
                  }
                },
              ),
            ],
          ),
      ],
    ),
    minScale: PhotoViewComputedScale.contained,
    maxScale: PhotoViewComputedScale.contained,
  );
}
            
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(widget.media.path!)),
                minScale: PhotoViewComputedScale.contained * 0.9,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                initialScale: PhotoViewComputedScale.contained,
              );
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: showOverlay ? 1.0 : 0.0,
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.media.name ??
                      (widget.media.isImage ? "Photo" : "Video"),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 16),
              Material(
                color: ThemeConstants.sinisterSeed,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                elevation: 3,
                child: InkWell(
                  onTap: () {
                    VideoHandler.disposeController(widget.media.path!);
                    widget.onSend?.call();
                    },
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


Widget _buildVideoControls(Media media) {
  // Get the video controller from cache
  final videoController = VideoHandler.controllers[media.path!];
  
  if (videoController == null || !videoController.isInitialized) {
    return const CircularProgressIndicator(color: Colors.white);
  }

  return AnimatedOpacity(
    duration: const Duration(milliseconds: 300),
    opacity: showOverlay ? 1.0 : 0.0,
    child: AspectRatio(
      aspectRatio: media.aspectRatio ?? (9/16),
      child: SafeArea(
        top: false,
        bottom: (media.aspectRatio ?? 9/16) >= 1.0 ? false : true,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            IgnorePointer(
                  ignoring: !showOverlay,
                  child: IconButton(
                    onPressed: () {
                      videoController.togglePlayPause();
                      setState(() {});
                    },
                    icon: Icon(
                      videoController.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
            // Timeline/progress indicator with bottom padding for navbar
            if (videoController.duration != Duration.zero)
              IgnorePointer(
                ignoring: !showOverlay,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 0), // Respect bottom navbar height
                  child: _buildVideoProgressIndicator(videoController),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

// Separate progress indicator with ValueListenableBuilder for real-time updates
Widget _buildVideoProgressIndicator(VideoHandler videoController) {
  return ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: videoController.controller,
    builder: (context, value, child) {
      final isCompleted = value.position == value.duration;
      
      // Auto-pause when video completes
      if (isCompleted && value.isPlaying) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          videoController.pause();
        });
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              VideoHandler.formatDuration(value.position),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: value.position.inMilliseconds.toDouble(),
                  min: 0,
                  max: value.duration.inMilliseconds.toDouble(),
                  onChanged: (newValue) {
                    videoController.seekTo(Duration(milliseconds: newValue.toInt()));
                  },
                  onChangeEnd: (newValue) {
                    videoController.seekTo(Duration(milliseconds: newValue.toInt()));
                  },
                ),
              ),
            ),
            Text(
              VideoHandler.formatDuration(value.duration),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      );
    },
  );
  }


}