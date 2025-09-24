import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryViewWrapper extends StatefulWidget {
  const GalleryViewWrapper({
    super.key,
    required this.galleryItems,
    this.initialIndex = 0,
    this.backgroundDecoration,
    this.chatTitle,
  });

  final List<Media> galleryItems;
  final int initialIndex;
  final BoxDecoration? backgroundDecoration;
  final String? chatTitle;

  @override
  State<GalleryViewWrapper> createState() => _GalleryViewWrapperState();
}

class _GalleryViewWrapperState extends State<GalleryViewWrapper> {
  late final PageController _pageController;
  late int currentIndex;
  bool showOverlay = true;
  final Color overlayBase = Colors.black26;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // Or SystemUiMode.manual with desired overlays
    super.dispose();
  }

  toggleOverlay() {
    setState(() {
      showOverlay = !showOverlay;
    });

    // if (showOverlay) {
    //   // Show status bar
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // } else {
    //   // Hide status bar
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // }
  }

  /// Get the time from the first linked message (backlink)
  DateTime? get currentImageTime {
    final media = widget.galleryItems[currentIndex];
    return media.messagesBacklink.isNotEmpty
        ? media.messagesBacklink.first.time
        : null;
  }

  /// Get path for a given index
  String? mediaPath(int index) => widget.galleryItems[index].path;

  /// Get file name
  String get currentFileName {
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
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: showOverlay ? 1.0 : 0.0,
            child: AppBar(
              backgroundColor: overlayBase,
              leading: IconButton(
                onPressed: () {
                  if (showOverlay) Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.chatTitle != null)
                    Text(
                      widget.chatTitle!,
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
            ),
          ),
        ),
        body: GestureDetector(
          onTap: toggleOverlay,// () => setState(() => showOverlay = !showOverlay),
          child: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            itemCount: widget.galleryItems.length,
            pageController: _pageController,
            onPageChanged: (index) => setState(() => currentIndex = index),
            builder: (context, index) {
              final path = mediaPath(index);
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(path!)),
                heroAttributes: PhotoViewHeroAttributes(tag: path),
                minScale: PhotoViewComputedScale.contained * 0.9,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                initialScale: PhotoViewComputedScale.contained,
              );
            },
            loadingBuilder:
                (context, event) => Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      value:
                          event == null
                              ? 0
                              : event.cumulativeBytesLoaded /
                                  (event.expectedTotalBytes ?? 1),
                    ),
                  ),
                ),
            backgroundDecoration:
                widget.backgroundDecoration ??
                const BoxDecoration(color: Colors.black),
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
              child: Text(currentFileName),
            ),
          ),
        ),
      ),
    );
  }
}
