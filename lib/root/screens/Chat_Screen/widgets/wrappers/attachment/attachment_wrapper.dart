import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/attachment_board.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/attachment/overlay_controller.dart';

/// Combines the behavior of EmergingOverlay + EmergingCircle into one widget.
/// Uses a true Flutter OverlayEntry, so the overlay appears above the entire UI.
///
class AttachmentWrapper extends ConsumerStatefulWidget {
  /// The base widget (usually the BottomMessageBar).
  final Widget child;

  /// Widget to be overlayed
  final Widget? overlay;

  /// Vertical offset from bottom for the overlay.
  final double bottomOffset;

  /// Maximum circular reveal radius.
  final double maxRadius;

  /// Animation duration for the circular reveal.
  final Duration animationDuration;

  /// Where the circular animation starts (alignment in -1..1 range).
  final Alignment circleAlignment;

  const AttachmentWrapper({
    super.key,
    required this.child,
    this.bottomOffset = 80,
    this.maxRadius = 500,
    this.animationDuration = const Duration(milliseconds: 400),
    this.circleAlignment = const Alignment(0.7, 1.0),
    this.overlay,
  });

  @override
  ConsumerState<AttachmentWrapper> createState() => _AttachmentWrapperState();
}

class _AttachmentWrapperState extends ConsumerState<AttachmentWrapper> {
  OverlayEntry? _overlayEntry;
  bool _listenerAttached = false;

  /// Inserts a new overlay entry with the circular animation.
  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = context.screenWidth;
        return Positioned(
          bottom: widget.bottomOffset,
          left: 0,
          right: 0,
          child: Consumer(
            builder: (context, ref, _) {
              final isOpen = ref.watch(overlayControllerProvider);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: isOpen ? (screenWidth * 1.2) : 0,
                  ),
                  duration: widget.animationDuration,
                  curve: Curves.easeInOutQuint,
                  builder: (context, radius, child) {
                    return ClipPath(
                      clipper: _CircularRevealClipper(
                        radius,
                        alignment: widget.circleAlignment,
                      ),
                      child: child,
                    );
                  },
                  child: widget.overlay ?? AttachmentBoard(isOpen: isOpen), /// Attachment Board actual
                ),
              );
            },
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  /// Removes the overlay entry after the animation completes.
  Future<void> _removeOverlay() async {
    await Future.delayed(widget.animationDuration);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_listenerAttached) {
      _listenerAttached = true;

      // Listen for overlay open/close state changes.
      ref.listen<bool>(overlayControllerProvider, (prev, next) async {
        if (next && _overlayEntry == null) {
          _showOverlay(context);
        } else if (!next && _overlayEntry != null) {
          await _removeOverlay();
        }
      });
    }

    // Return the main child (e.g. BottomMessageBar)
    return widget.child;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}

/// Handles the circular reveal clipping effect.
class _CircularRevealClipper extends CustomClipper<Path> {
  final double radius;
  final Alignment alignment;

  _CircularRevealClipper(this.radius, {this.alignment = Alignment.center});

  @override
  Path getClip(Size size) {
    final center = Offset(
      size.width * (alignment.x + 1) / 2,
      size.height * (alignment.y + 1) / 2,
    );

    final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.alignment != alignment;
}
