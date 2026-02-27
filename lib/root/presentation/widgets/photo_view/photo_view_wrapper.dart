import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewWrapper extends StatelessWidget {
  const PhotoViewWrapper({
    super.key,
    required this.imagePath,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
  });

  final String imagePath;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;

  /// Extracts just the file name from the full path
  String get fileName => imagePath.split(Platform.pathSeparator).last;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black12,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
      ),
      body: PhotoView(
        imageProvider: FileImage(File(imagePath)),
        backgroundDecoration: backgroundDecoration,
        initialScale: PhotoViewComputedScale.contained,      // Original size
        minScale: PhotoViewComputedScale.contained * 0.9,    // 70% of original
        maxScale: PhotoViewComputedScale.covered * 2.0,      // Example max zoom
        heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
      ),
      bottomNavigationBar: Container(
        height: 100,
        color: Colors.black12,
        alignment: Alignment.center,
        child: Text(
          fileName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
