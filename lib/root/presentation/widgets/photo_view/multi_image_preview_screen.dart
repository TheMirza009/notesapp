import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MultiImagePreviewScreen extends StatefulWidget {
  final List<Media> mediaList;

  const MultiImagePreviewScreen({super.key, required this.mediaList});

  @override
  State<MultiImagePreviewScreen> createState() => _MultiImagePreviewScreenState();
}

class _MultiImagePreviewScreenState extends State<MultiImagePreviewScreen> {
  late final PageController _pageController;
  late final List<Media> _orderedList;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _orderedList = List<Media>.from(widget.mediaList);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSend() => Navigator.of(context).pop(List<Media>.unmodifiable(_orderedList));

  void _onCancel() => Navigator.of(context).pop(null);

  void _removeImage(int index) {
    setState(() {
      _orderedList.removeAt(index);
      if (_orderedList.isEmpty) {
        Navigator.of(context).pop(null);
        return;
      }
      _currentIndex = _currentIndex.clamp(0, _orderedList.length - 1);
      // Jump the pager to the clamped position without animation to avoid out-of-bounds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = _orderedList.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // FULL-SCREEN PHOTO VIEWER
          Positioned.fill(
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: _pageController,
              itemCount: count,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              builder: (context, index) {
                final media = _orderedList[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: ExtendedFileImageProvider(
                    File(media.path!),
                    cacheRawData: true,
                  ),
                  heroAttributes: PhotoViewHeroAttributes(tag: media.path ?? index),
                  minScale: PhotoViewComputedScale.contained * 0.9,
                  maxScale: PhotoViewComputedScale.covered * 2.0,
                  initialScale: PhotoViewComputedScale.contained,
                );
              },
            ),
          ),

          // APPBAR (translucent overlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              primary: false,
              backgroundColor: Colors.black38,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _onCancel,
              ),
              title: Text(
                '${_currentIndex + 1} of $count',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => _removeImage(_currentIndex),
                ),
              ],
            ),
          ),

          // FILMSTRIP (translucent overlay)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              width: double.infinity,
              color: Colors.black38,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              alignment: Alignment.center,
              child: Center(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: count,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? ThemeConstants.sinisterSeed
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(_orderedList[index].path!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),

      // SEND BAR
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$count ${count == 1 ? "image" : "images"} selected',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Material(
              color: ThemeConstants.sinisterSeed,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              child: InkWell(
                onTap: _onSend,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
