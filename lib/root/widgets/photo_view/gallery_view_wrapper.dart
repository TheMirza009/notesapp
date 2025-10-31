import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/old_notifiers/chat_state_notifier_o.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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

  String? get currentChatTitle {
  final media = widget.galleryItems[currentIndex];
  if (media.messagesBacklink.isEmpty) return null;
  final chat = media.messagesBacklink.first.chat.value;
  return chat?.title;
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
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
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
                    widget.showOptions == true
                        ? [
                          CustomContextMenu(
                            backgroundColor: const Color.fromARGB(255, 13, 24, 30),
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            menuItems: widget.options ?? galleryOptions,
                            onSelected: widget.onOptionSelect ?? (value) =>  debugPrint(value),
                          ),
                        ]
                        : [],
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
                imageProvider: ExtendedFileImageProvider(File(path!), cacheRawData: true), // FileImage(File(path!)),
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
              child: (widget.isCamera ?? false) ? 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(currentFileName, style: TextStyle(color: Colors.white),),
                          Consumer(
                            builder: (context, ref, child) {
                              return IconButton.filled(
                                onPressed: widget.onSendImage ?? () async => await _openPreviewAndRemoveCamera(context, widget.galleryItems[0], ref),
                                icon: Icon(
                                  Icons.send,
                                  color: ThemeConstants.sinisterSeed,
                                  size: 30,
                                ),
                              );
                            }
                          )
                ],
              )
               : Text(currentFileName, style: TextStyle(color: Colors.white),),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openPreviewAndRemoveCamera(BuildContext context, Media media, WidgetRef ref) async {

  final route = ModalRoute.of(context);
if (route != null && Navigator.of(context).canPop()) {
  Navigator.of(context).removeRouteBelow(route); // remove camera
}

// Pop first, then add the image
if (Navigator.of(context).canPop()) {
  Navigator.of(context).pop(); // pop back to chat
  // Schedule pickImage after popping completes
  Future.microtask(() async {
    await ref.read(chatStateController.notifier).pickImage(media: media);
  });
}


  // Optional: pick image
}
