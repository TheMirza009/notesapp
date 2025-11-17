import 'dart:async';
import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/video_handler.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_base_state.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_Forward/widgets/send_button.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/old_notifiers/chat_state_notifier_o.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/message_list_wrapper.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/video_view/seek_indicators.dart';
import 'package:notesapp/root/widgets/video_view/video_gallery_player.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';

final isProcessing = StateProvider.autoDispose<bool>((ref) => false);

class GalleryViewWrapper extends StatefulWidget {
  const GalleryViewWrapper({
    super.key,
    required this.galleryItems,
    this.initialIndex = 0,
    this.backgroundDecoration,
    this.chatTitle,
    this.isCamera = false,
    this.onSendImage,
    this.showOptions = true,
    this.options,
    this.onOptionSelect,
  });

  final List<Media> galleryItems;
  final int initialIndex;
  final BoxDecoration? backgroundDecoration;
  final String? chatTitle;
  final bool? isCamera;
  final VoidCallback? onSendImage;
  final bool? showOptions;
  final List<PopupMenuEntry<String>>? options;
  final Function(String value)? onOptionSelect;

  @override
  State<GalleryViewWrapper> createState() => _GalleryViewWrapperState();
}

class _GalleryViewWrapperState extends State<GalleryViewWrapper> {
  late final PageController _pageController;
  late int currentIndex;
  bool showOverlay = true;
  final Color overlayBase = Colors.black26;
  
  // Store video controllers for control access
  final Map<String, VideoHandler> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    super.dispose();
    _videoControllers.clear();
    VideoHandler.disposeAll(); // This will clean up all video controllers
  }

  void toggleOverlay() {
    setState(() {
      showOverlay = !showOverlay;
    });
  }

  void _onVideoCompleted() {
    if (mounted) {
      setState(() => showOverlay = true);

      // Auto-pause when video completes
      final currentMedia = widget.galleryItems[currentIndex];
      final videoController = VideoHandler.controllers[currentMedia.path!];
      videoController?.pause();
    }
  }

  // Get video controller for current media
  VideoHandler? _getCurrentVideoController() {
    final currentMedia = widget.galleryItems[currentIndex];
    if (currentMedia.path == null) return null;
    
    // The VideoHandler.fromPath caches controllers, so we can access them
    return _videoControllers[currentMedia.path!];
  }

  // Store video controller when video player initializes
  void _storeVideoController(String path, VideoHandler controller) {
    _videoControllers[path] = controller;
  }

  /// Get the time from the first linked message (backlink)
  DateTime? get currentImageTime {
    final media = widget.galleryItems[currentIndex];
    return media.messagesBacklink.isNotEmpty
        ? media.messagesBacklink.first.time
        : null;
  }

  String? get currentChatTitle {
    final media = widget.galleryItems[currentIndex];
    if (media.messagesBacklink.isEmpty) return null;
    final chat = media.messagesBacklink.first.chat.value;
    return chat?.title;
  }

  /// Get path for a given index
  String? mediaPath(int index) {
    if (index < 0 || index >= widget.galleryItems.length) return null;
    return widget.galleryItems[index].path;
  }

  /// Get file name
  String get currentFileName {
    if (currentIndex < 0 || currentIndex >= widget.galleryItems.length) {
      return "📷 Media";
    }
    
    final path = mediaPath(currentIndex);
    return path != null ? path.split(Platform.pathSeparator).last : "📷 Photo";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: IgnorePointer(
            ignoring: !showOverlay,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: showOverlay ? 1.0 : 0.0,
              child: AppBar(
                backgroundColor: overlayBase,
                leading: IconButton(
                  onPressed: () {
                    if (showOverlay) Navigator.pop(context);
                    if (widget.isCamera == true) {
                      unawaited(MediaHandler.deleteMedia(widget.galleryItems[0]));
                      // Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    widget.isCamera == true 
                    ? Icons.clear_rounded 
                    : Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentChatTitle != null)
                      Text(
                        currentChatTitle!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (currentImageTime != null)
                      Text(
                        TimeFormat.imageTime(currentImageTime!),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                actions:
                    (widget.showOptions == true && widget.isCamera != true)
                        ? [
                          Consumer(
                            builder: (context, ref, child) {
                              return CustomContextMenu(
                                backgroundColor: const Color.fromARGB(255,13,24,30,),
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                menuItems:
                                    widget.options ??
                                    (widget.galleryItems[currentIndex].isVideo ? galleryVideoOptions : galleryOptions),
                                onSelected:
                                    widget.onOptionSelect ??
                                    ((value) => handleGalleryOptions(context, ref, value,
                                      widget.galleryItems[currentIndex],
                                    ))// allImages[initialIndex],
                              );
                            }
                          ),
                        ]
                        : [],
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: toggleOverlay,
          child: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            itemCount: widget.galleryItems.length,
            pageController: _pageController,
            onPageChanged: (index) {
              final currentMedia = widget.galleryItems[currentIndex];
              if (currentMedia.type == Mediatype.video) {
                final currentVideoController = VideoHandler.controllers[currentMedia.path!];
                currentVideoController?.pause();
              }
              setState(() => currentIndex = index);
            },
            builder: (context, index) {
              if (index < 0 || index >= widget.galleryItems.length) {
                return PhotoViewGalleryPageOptions.customChild(
                  child: const Center(child: Text("Media not available")),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.contained,
                );
              }

              final media = widget.galleryItems[index];              
              final path = mediaPath(index);

              if (path == null) {
                return PhotoViewGalleryPageOptions.customChild(
                  child: const Center(child: Icon(Icons.broken_image, size: 50)),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.contained,
                );
              }

              if (media.type == Mediatype.video) {
                final videoController = VideoHandler.controllers[media.path!];
                return PhotoViewGalleryPageOptions.customChild(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video player without controls
                      VideoGalleryPlayer(
                        media: media,
                        directPlay: index == widget.initialIndex, // Only autoplay initial video
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
                              child: _buildVideoControls(media),
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
                imageProvider: ExtendedFileImageProvider(
                  File(path),
                  cacheRawData: true,
                ),
                heroAttributes: PhotoViewHeroAttributes(tag: media.isarId),
                minScale: PhotoViewComputedScale.contained * 0.9,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                initialScale: PhotoViewComputedScale.contained,
              );
            },
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                ),
              ),
            ),
            backgroundDecoration: widget.backgroundDecoration ?? const BoxDecoration(color: Colors.black),
          ),
        ),
        bottomNavigationBar: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: showOverlay ? 1.0 : 0.0,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 70),
            alignment: Alignment.center,
            color: Colors.black26,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: (widget.isCamera ?? false)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currentFileName, style: const TextStyle(color: Colors.white)),
                        Consumer(
                            builder: (context, ref, child) {
                              return Material(
                                color: ThemeConstants.sinisterSeed,
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                elevation: 3,
                                child: InkWell(
                                  onTap:
                                      () async =>
                                          await openPreviewAndRemoveCamera(
                                            context,
                                            widget.galleryItems[0],
                                            ref,
                                          ),
                                  customBorder: const CircleBorder(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child:
                                    ref.watch(isProcessing) == true
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation< Color >(ThemeConstants.textDark2),
                                      ),
                                    )
                                    : Icon(
                                      Icons.send,
                                      color: ThemeConstants.textDark2,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                  : Text(currentFileName, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  // Build video controls that work with the current video
  // Build video controls that work with the current video
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

Future<void> openPreviewAndRemoveCamera(
  BuildContext context,
  Media media,
  WidgetRef ref,
) async {
  // Capture the provider reference BEFORE any navigation
  final chatNotifier = ref.read(chatStateController.notifier);

  // First, generate metadata if needed (BEFORE any popping)
  if (media.isVideo && !media.hasCompleteMetadata && media.path != null) {
    ref.read(isProcessing.notifier).state = true;
    final videoMetadata = await VideoMetadataHandler.generateVideoMetadata(
      media.path!,
    );
    if (videoMetadata != null) {
      media.updateMetadata(
        Media.fromVideoPath(media.path!, metadata: videoMetadata),
      );
    }
  }

  // Remove camera route
  final route = ModalRoute.of(context);
  if (route != null && Navigator.of(context).canPop()) {
    Navigator.of(context).removeRouteBelow(route);
  }

  // Now pop and send the media
  if (Navigator.of(context).canPop()) {
    ref.read(isProcessing.notifier).state = false;
    Navigator.of(context).pop(); // pop back to chat

    // Send the media immediately since metadata is ready
    Future.microtask(() async {
      if (media.isVideo) {
        await chatNotifier.pickVideo(media: media);
      } else {
        await chatNotifier.pickImage(media: media);
      }
    });
  }
}
