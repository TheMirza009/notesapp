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

class _ImageMessageViewState extends State<ImageMessageView> {
  bool _imageLoaded = false;
  Uint8List? _blurBytes; // ✅ Store decoded blur directly

  @override
  void initState() {
    super.initState();
    _loadBlurHash();
  }

  /// ✅ Load blurhash from cache (should be instant if pre-decoded)
  Future<void> _loadBlurHash() async {
    final media = widget.message.media.value;
    if (media?.blurHash == null) return;

    // Should hit cache immediately if batch-decoded
    final bytes = await BlurHashService.getDecoded(media!.blurHash!);
    
    if (bytes != null && mounted) {
      setState(() => _blurBytes = bytes);
    } else {
      // Fallback: decode now (shouldn't happen if hydration works)
      final decoded = await BlurHashService.decodeBlurHash(
        media.blurHash!,
        media.aspectRatio ?? 1.0,
      );
      if (decoded != null && mounted) {
        setState(() => _blurBytes = decoded);
      }
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
    final aspectRatio = media.aspectRatio ?? 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: maxWidth),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ✅ Layer 1: BlurHash (should appear instantly)
              if (_blurBytes != null)
                Image.memory(
                  _blurBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
              else
                Container(color: Colors.transparent ),// Colors.grey[300]),

              // ✅ Layer 2: Actual image (fades in)
              AnimatedOpacity(
                opacity: _imageLoaded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Hero(
                  tag: widget.message.media.value?.path ?? widget.message.isarId, // Unique tag,
                  child: ExtendedImage.file(
                    file,
                    fit: BoxFit.cover,
                    cacheHeight: maxHeight ~/ 2, // max(1, maxHeight.toInt()),
                    cacheWidth: maxWidth ~/ 2, // max(1, maxWidth.toInt()),
                    clearMemoryCacheIfFailed: true,
                    gaplessPlayback: true,
                    cacheRawData: true,
                    clearMemoryCacheWhenDispose: false,
                    compressionRatio: 0.5,
                    loadStateChanged: (state) {
                      if (state.extendedImageLoadState == LoadState.completed &&
                          !_imageLoaded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _imageLoaded = true);
                        });
                      }
                      return null;
                    },
                  ),
                ),
              ),

              // ✅ Layer 3: Timestamp
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: Container(
                  height: 50,
                  alignment: Alignment.bottomRight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withAlpha(0), Colors.black.withAlpha(255)],
                    ),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    DateFormat.jm().format(widget.message.time),
                    style: const TextStyle(fontSize: 12, color: ThemeConstants.subtitleLight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrokenImage() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        children: [
          const Expanded(child: Center(child: Icon(Icons.broken_image))),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              DateFormat.jm().format(widget.message.time),
              style: const TextStyle(fontSize: 12, color: ThemeConstants.subtitleLight),
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