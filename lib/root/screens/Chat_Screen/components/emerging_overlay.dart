import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Settings/widgets/emerging_circle.dart';
import 'package:notesapp/root/screens/Settings/widgets/attachment_board.dart';

/// Shared provider that controls whether the overlay is open or closed
final openingProvider = StateProvider<bool>((_) => false);

/// Handles showing / hiding the EmergingCircle overlay cleanly.
/// Keeps overlay state isolated from other UI components.
class EmergingOverlay extends ConsumerStatefulWidget {
  final Widget child; // Usually your BottomMessageBar
  final double bottomOffset;
  final double maxRadius;

  const EmergingOverlay({
    super.key,
    required this.child,
    this.bottomOffset = 80,
    this.maxRadius = 500,
  });

  @override
  ConsumerState<EmergingOverlay> createState() => _EmergingOverlayHandlerState();
}

class _EmergingOverlayHandlerState extends ConsumerState<EmergingOverlay> {
  OverlayEntry? _overlayEntry;
  bool _listenerAttached = false; // prevent multiple listeners

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: widget.bottomOffset,
        left: 0,
        right: 0,
        child: Consumer(
          builder: (context, ref, _) {
            final open = ref.watch(openingProvider);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: EmergingCircle(
                open: open,
                maxRadius: context.screenWidth * 1.2 ?? widget.maxRadius,
                child: AttachmentBoard(isOpen: open),
              ),
            );
          },
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  Future<void> _removeOverlay() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {

    // 🧠 Attach listener safely (only once)
    if (!_listenerAttached) {
      _listenerAttached = true;

      ref.listen<bool>(openingProvider, (prev, next) async {
        if (next && _overlayEntry == null) {
          _showOverlay(context);
        } else if (!next && _overlayEntry != null) {
          await _removeOverlay();
        }
      });
    }

    return widget.child;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}
