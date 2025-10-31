import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/old_notifiers/chat_state_notifier_o.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/old_notifiers/chat_screen_notifier_3.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/attachment/overlay_controller.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/overlays/overlay_handler.dart';
import 'package:notesapp/root/screens/Settings/widgets/bordered_container.dart';
import 'package:notesapp/root/screens/Camera/camera_screen.dart';

/// ===============================================================
///  ATTACHMENT BOARD (theme-aware + grid-like layout preserved)
/// ===============================================================
class AttachmentBoard extends ConsumerWidget {
  
  // Animation watcher bool
  final bool isOpen;

  /// OnTap callbacks
  final VoidCallback? onDocumentsPressed;
  final VoidCallback? onGalleryPressed;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onAudioPressed;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onContactPressed;
  final VoidCallback? onChartPressed;
  final VoidCallback? onThreadPressed;
  final VoidCallback? onScanPressed;

  const AttachmentBoard({
    super.key,
    required this.isOpen,
    this.onDocumentsPressed,
    this.onGalleryPressed,
    this.onCameraPressed,
    this.onAudioPressed,
    this.onLocationPressed,
    this.onContactPressed,
    this.onChartPressed,
    this.onThreadPressed,
    this.onScanPressed, 
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double iconSize = 22;
    const double rowSpacing = 35;
    final notifier = ref.read(chatStateController.notifier);

    return BorderedContainer(
      margins: const EdgeInsets.only(top: 15),
      color: isDark ? const Color(0xFF0F181F) : const Color(0xFFEFEFEF),
      borderColor: isDark
          ? ThemeConstants.darkIconbackground
          : ThemeConstants.attachmentLightBG,
      width: context.screenWidth,
      height: 250, // 350,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: [
          AttachmentRow(
            spacing: rowSpacing,
            open: isOpen,
            tiles: [
              AttachmentItem(
                widget: Icon(Icons.music_note, color: Colors.deepOrange, size: iconSize),
                title: "Audio",
                onPressed: onAudioPressed ?? () async => await notifier.pickAudio(),
              ),
              AttachmentItem(
                widget: Icon(Icons.photo, color: Color(0xFFF43665), size: iconSize),
                title: "Gallery",
                onPressed: onGalleryPressed ?? () async => await notifier.pickImage(),
              ),
              AttachmentItem(
                widget: Icon(Icons.camera, color: Color(0xFFCE6789), size: iconSize),
                title: "Camera",
                onPressed: onCameraPressed ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen())),
                // () async => await notifier.pickImage(isCamera: true)
              ),
            ],
          ),
          AttachmentRow(
            spacing: rowSpacing,
            open: isOpen,
            tiles: [
              AttachmentItem(
                widget: Icon(Icons.edit_document, color: Color(0xFFAD76CE), size: iconSize),
                title: "Document",
                onPressed: onDocumentsPressed ?? () async => await notifier.pickDocument(),
              ),
              AttachmentItem(
                widget: Icon(Icons.list, color: Colors.amber, size: iconSize),
                title: "Thread",
                onPressed: onThreadPressed ?? () => notifier.createThread(),
              ),
              AttachmentItem(
                widget: Icon(Icons.bar_chart, color: Colors.cyan, size: iconSize),
                title: "Chart",
                onPressed: onChartPressed,
              ),
              
            ],
          ),
          // AttachmentRow(
          //   spacing: rowSpacing,
          //   open: isOpen,
          //   tiles: [
          //     AttachmentItem(
          //       widget: Icon(Icons.location_pin, color: Colors.red, size: iconSize),
          //       title: "Location",
          //       onPressed: onLocationPressed,
          //     ),
              
          //     AttachmentItem(
          //       widget: Icon(Icons.person_2_rounded, color: Colors.blueAccent, size: iconSize),
          //       title: "Contact",
          //       onPressed: onContactPressed,
          //     ),
          //     AttachmentItem(
          //       widget: Icon(Icons.scanner, color: Colors.redAccent, size: iconSize),
          //       title: "Scan",
          //       onPressed: onScanPressed,
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

/// ===============================================================
///  Data holder for each tile (flexible widget support)
/// ===============================================================
class AttachmentItem {
  final Widget widget;
  final String title;
  final VoidCallback? onPressed;
  final Color? tileColor;
  final EdgeInsetsGeometry iconPadding;
  final EdgeInsetsGeometry iconMargin;

  const AttachmentItem({
    required this.widget,
    required this.title,
    this.onPressed,
    this.tileColor,
    this.iconPadding = const EdgeInsets.all(16),
    this.iconMargin = const EdgeInsets.all(5),
  });
}

/// ===============================================================
///  AttachmentRow — reversed bounce-in animation, no reverse-out
/// ===============================================================
class AttachmentRow extends StatefulWidget {
  final List<AttachmentItem> tiles;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final bool open;

  const AttachmentRow({
    super.key,
    required this.tiles,
    this.mainAxisAlignment = MainAxisAlignment.spaceAround,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.spacing = 40,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.open = false,
  });

  @override
  State<AttachmentRow> createState() => _AttachmentRowState();
}

class _AttachmentRowState extends State<AttachmentRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.open) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AttachmentRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only animate forward when open becomes true
    if (widget.open && !oldWidget.open) {
      _controller
        ..reset()
        ..forward();
    }

    // Do nothing when closing — we don’t want to animate back
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = widget.tiles;

    return Row(
      spacing: widget.spacing,
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      crossAxisAlignment: widget.crossAxisAlignment,
      textDirection: widget.textDirection,
      verticalDirection: widget.verticalDirection,
      children: tiles.asMap().entries.map((entry) {
        final index = entry.key;
        final reversedIndex = tiles.length - 1 - index;

        // Create staggered intervals per icon
        final start = 0.1 * reversedIndex;
        final end = (start + 0.6).clamp(0.0, 1.0);

        final scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOutQuint),
          ),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: IconTile(
            title: entry.value.title,
            onPressed: entry.value.onPressed,
            tileColor: entry.value.tileColor,
            iconPadding: entry.value.iconPadding,
            iconMargin: entry.value.iconMargin,
            child: entry.value.widget,
          ),
        );
      }).toList(),
    );
  }
}


/// ===============================================================
///  IconTile — same layout, any widget, theme-aware
/// ===============================================================
class IconTile extends ConsumerWidget {
  final Widget child;
  final String title;
  final VoidCallback? onPressed;
  final Color? tileColor;
  final EdgeInsetsGeometry iconPadding;
  final EdgeInsetsGeometry iconMargin;

  const IconTile({
    super.key,
    required this.child,
    required this.title,
    this.onPressed,
    this.tileColor,
    this.iconPadding = const EdgeInsets.all(16),
    this.iconMargin = const EdgeInsets.all(5),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = tileColor ?? (isDark ? ThemeConstants.darkIconBorder : ThemeConstants.attachmentLightBG);
    final borderColor = (isDark ? ThemeConstants.darkIconbackground : ThemeConstants.attachmentBorderLight);

    final borderRadius = BorderRadius.circular(15);

    return Opacity(
      opacity: onPressed == null ? 0.2 : 1.0,
      child: Column(
        children: [
          Container(
            margin: iconMargin,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: context.isLight ? Border.all(color: borderColor, width: 1.5) : null
            ),
            child: Material(
              color: backgroundColor,
              borderRadius: borderRadius,
              child: InkWell(
                onTap: () {
                  onPressed?.call();
                  ref.read(overlayHandlerProvider).closeAttachmentBoard();
                  // ref.read(openingProvider.notifier).state = false;
                },
                borderRadius: borderRadius,
                splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                child: Padding(
                  padding: iconPadding,
                  child: Center(child: child),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}


/// ===============================================================
///  Optional tail clipper (unchanged)
/// ===============================================================
class TailedPoppup extends CustomClipper<Path> {
  const TailedPoppup();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..lineTo(0, h)
      ..lineTo(w, h);
    return path;
  }

  @override
  bool shouldReclip(TailedPoppup oldClipper) => false;
}
