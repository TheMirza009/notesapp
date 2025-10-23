import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:extended_image/extended_image.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/blurhash_service.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class ImageMessageView extends StatefulWidget {
  final Message message;
  const ImageMessageView({super.key, required this.message});

  @override
  State<ImageMessageView> createState() => _ImageMessageViewState();
}

class _ImageMessageViewState extends State<ImageMessageView> with SingleTickerProviderStateMixin {
  bool _isGenerating = false;
  bool _imageLoaded = false;
  Future<Uint8List?>? _decodedBlurFuture;

  @override
  void initState() {
    super.initState();
    final media = widget.message.media.value;
    if (media?.blurHash != null && _decodedBlurFuture == null) {
       _decodedBlurFuture =
          BlurHashService.decodeBlurHash(media!.blurHash!, media.aspectRatio ?? 1.0);
    } else {
      // Start generating blurhash if missing
      _generateAndSaveBlurHash(media);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.message.media.value;
    if (media == null || media.path == null) return _buildBrokenImage();

    final file = File(media.path!);
    if (!file.existsSync()) return _buildBrokenImage();

    final maxHeight = ThemeConstants.screenHeight * 0.5;
    final maxWidth = ThemeConstants.screenWidth * 0.7;
    final aspectRatio = (media.aspectRatio != null && media.aspectRatio! > 0)
        ? media.aspectRatio!
        : 1.0;

    final cacheH = max(1, maxHeight.toInt());
    final cacheW = max(1, maxWidth.toInt());

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              // ✅ Layer 1: BlurHash or fallback background
              if (media.blurHash != null)
                FutureBuilder<Uint8List?>(
                  future: _decodedBlurFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SizedBox.expand(
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      );
                    }
                    return _buildPlaceholder();
                  },
                )
              else
                _buildPlaceholder(),

              // ✅ Layer 2: Actual image (fades in)
              AnimatedOpacity(
                opacity: _imageLoaded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: ExtendedImage.file(
                  file,
                  fit: BoxFit.cover,
                  cacheHeight: cacheH,
                  cacheWidth: cacheW,
                  clearMemoryCacheIfFailed: true,
                  gaplessPlayback: true,
                  cacheRawData: true,
                  clearMemoryCacheWhenDispose: false,
                  compressionRatio: 0.5,
                  loadStateChanged: (state) {
                    if (state.extendedImageLoadState == LoadState.completed &&
                        !_imageLoaded) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _imageLoaded = true);
                        }
                      });
                    }
                    return null; // use default rendering
                  },
                ),
              ),

              // ✅ Layer 3: Timestamp overlay
              Container(
                height: 50,
                alignment: Alignment.bottomRight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(0),
                      Colors.black.withAlpha(255),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  DateFormat.jm().format(widget.message.time),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ThemeConstants.subtitleLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🧠 Generate and save blurHash if missing
  Future<void> _generateAndSaveBlurHash(Media? media) async {
    if (media == null || media.path == null || _isGenerating) return;
    _isGenerating = true;

    final hash = await BlurHashService.generateAndPersist(media);
    if (hash != null && mounted) {
      setState(() {
        _decodedBlurFuture = _decodeBlurHash(hash, media.aspectRatio ?? 1.0);
      });
    }
  }

/// 🎨 Decode blurhash → Uint8List (renderable image)
/// 🎨 Decode blurhash → Uint8List (renderable PNG image)
Future<Uint8List?> _decodeBlurHash(String hash, double aspectRatio) async {
  try {
    const width = 32;
    final height = max(1, (width / aspectRatio).round());

    // Decode → get BlurHash object
    final blurHashObj = BlurHash.decode(hash);

    // Convert BlurHash → Image (raw pixels)
    final image = blurHashObj.toImage(width, height);

    // Encode as PNG so Flutter can display it
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    return pngBytes;
  } catch (e) {
    debugPrint("⚠️ Blurhash decode failed: $e");
    return null;
  }
}

  /// 🩶 Fallback light gray placeholder
  Widget _buildPlaceholder() {
    return Container(color: Colors.transparent); // Colors.grey[300]);
  }

  Widget _buildBrokenImage() {
    return SizedBox(
        width: 100,
        height: 100,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: const Center(
                child: Icon(Icons.broken_image),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat.jm().format(widget.message.time),
                style: const TextStyle(
                  fontSize: 12,
                  color: ThemeConstants.subtitleLight,
                ),
              ),
            ),
          ],
        ),
      );
  }
}

// class ImageMessageView extends StatelessWidget {
//   final Message message;
//   const ImageMessageView({super.key, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     final media = message.media.value;

//     if (media == null || media.path == null) {
//       return const SizedBox(
//         width: 100,
//         height: 100,
//         child: Center(child: Icon(Icons.broken_image)),
//       );
//     }

//     final file = File(media.path!);

//     // If file doesn't exist, show broken image placeholder
//     if (!file.existsSync()) {
//       return SizedBox(
//         width: 100,
//         height: 100,
//         child: Column(
//           mainAxisSize: MainAxisSize.max,
//           children: [
//             Expanded(
//               child: const Center(
//                 child: Icon(Icons.broken_image),
//               ),
//             ),
//             Align(
//               alignment: Alignment.bottomRight,
//               child: Text(
//                 DateFormat.jm().format(message.time),
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: ThemeConstants.subtitleLight,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     final ext = (media.extension ?? "").toLowerCase();
//     if (ext == "gif") {
//       return GifMessageView(message: message);
//     }

//     final maxHeight = ThemeConstants.screenHeight * 0.5;
//     final maxWidth = ThemeConstants.screenWidth * 0.7;
//     final aspectRatio = (media.aspectRatio != null && media.aspectRatio! > 0) ? media.aspectRatio! : 1.0;

//     // Ensure cache ints are at least 1
//     final cacheH = max(1, maxHeight.toInt());
//     final cacheW = max(1, maxWidth.toInt());

//     return RepaintBoundary(
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(6),
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             maxHeight: maxHeight,
//             maxWidth: maxWidth,
//           ),
//           child: AspectRatio(
//             aspectRatio: aspectRatio,
//             child: Stack(
//               alignment: Alignment.bottomRight,
//               children: [
//                 ExtendedImage.file(
//                   file,
//                   fit: BoxFit.cover,
//                   cacheHeight: cacheH, // downsample at decode
//                   cacheWidth: cacheW, // downsample at decode
//                   clearMemoryCacheIfFailed: true,
//                   gaplessPlayback: true,
//                   cacheRawData: true, // memory + disk caching
//                   clearMemoryCacheWhenDispose: false,
//                   compressionRatio: 0.5,
//                 ),
//                 Container(
//                   height: 50,
//                   alignment: Alignment.bottomRight,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Colors.black.withAlpha(0),
//                         Colors.black.withAlpha(255),
//                       ],
//                     ),
//                   ),
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     DateFormat.jm().format(message.time),
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: ThemeConstants.subtitleLight,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }