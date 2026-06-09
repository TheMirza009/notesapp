import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/core/extensions/message_list_extensions.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/presentation/widgets/photo_view/gallery_view_wrapper.dart';

/// Grid bubble for an album (a message carrying multiple media).
///
/// Layout is a fixed square bounding box divided with flex, so columns yield
/// portrait tiles and rows yield landscape tiles (orientation read from
/// [Media.aspectRatio]):
/// - 2 images: both landscape → stacked; otherwise → side-by-side.
/// - 3 images: feature = first image. Landscape feature → full-width on top
///   with the other two side-by-side below; portrait feature → full-height on
///   the left with the other two stacked on the right (WhatsApp-style).
/// - 4+ images: 2×2 grid, last tile shows a "+N" overflow count.
/// Tapping a tile opens the chat-wide gallery at that image.
class AlbumView extends ConsumerWidget {
  final Message message;
  const AlbumView({super.key, required this.message});

  // ── Control Panel ───────────────────────────────────────────────────────
  static const double _gap = 2.0;          // spacing between tiles
  static const double _maxAlbumSide = 320; // cap so the square stays sane on desktop

  bool _isLandscape(Media m) => (m.aspectRatio ?? 1.0) > 1.0;

  /// Open the chat-wide gallery positioned at [media] (matches the single-image
  /// tap behaviour in MessageListWrapper).
  void _openGallery(BuildContext context, WidgetRef ref, Media media) {
    final allMedia = ref.read(chatStateController).messages.imagesAndVideos;
    final initialIndex = allMedia.indexWhere((m) => m.isarId == media.isarId);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => GalleryViewWrapper(
          galleryItems: allMedia,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
          showOptions: true,
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  /// A single cover-cropped tile; [overflow] adds a "+[extra]" scrim.
  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    List<Media> media,
    int index, {
    bool overflow = false,
    int extra = 0,
  }) {
    final item = media[index];
    return GestureDetector(
      onTap: () => _openGallery(context, ref, item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.path != null)
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
              ),
              child: ExtendedImage.file(
                File(item.path!),
                fit: BoxFit.cover,
                clearMemoryCacheIfFailed: true,
                gaplessPlayback: true,
              ),
            )
          else
            Container(color: Colors.grey.shade800),
          if (overflow)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Text(
                '+$extra',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = message.allMedia;
    final total = media.length;

    final screenW = kisDesktop ? context.screenWidth : ThemeConstants.screenWidth;
    final maxWidth = (screenW > 0 ? screenW : 400) * 0.7;
    final side = maxWidth < _maxAlbumSide ? maxWidth : _maxAlbumSide;

    final Widget layout;
    if (total == 2) {
      // Both landscape → stacked; otherwise (portrait/square/mixed) → side-by-side.
      final stacked = _isLandscape(media[0]) && _isLandscape(media[1]);
      layout = Flex(
        direction: stacked ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(child: _tile(context, ref, media, 0)),
          SizedBox(width: stacked ? 0 : _gap, height: stacked ? _gap : 0),
          Expanded(child: _tile(context, ref, media, 1)),
        ],
      );
    } else if (total == 3) {
      // Feature (first image) orientation picks the split axis.
      final featureLandscape = _isLandscape(media[0]);
      final pair = Flex(
        direction: featureLandscape ? Axis.horizontal : Axis.vertical,
        children: [
          Expanded(child: _tile(context, ref, media, 1)),
          SizedBox(
            width: featureLandscape ? _gap : 0,
            height: featureLandscape ? 0 : _gap,
          ),
          Expanded(child: _tile(context, ref, media, 2)),
        ],
      );
      layout = Flex(
        direction: featureLandscape ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(child: _tile(context, ref, media, 0)),
          SizedBox(
            width: featureLandscape ? 0 : _gap,
            height: featureLandscape ? _gap : 0,
          ),
          Expanded(child: pair),
        ],
      );
    } else {
      // 4+ → 2×2 grid; last shown tile carries the overflow count.
      layout = Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(context, ref, media, 0)),
                const SizedBox(width: _gap),
                Expanded(child: _tile(context, ref, media, 1)),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(context, ref, media, 2)),
                const SizedBox(width: _gap),
                Expanded(
                  child: _tile(context, ref, media, 3,
                      overflow: total > 4, extra: total - 4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: side,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: side, height: side, child: layout),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(
                DateFormat.jm().format(message.time),
                style: const TextStyle(
                  fontSize: 12,
                  color: ThemeConstants.subtitleLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
