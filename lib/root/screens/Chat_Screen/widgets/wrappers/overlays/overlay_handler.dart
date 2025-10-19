
/// Centralized OverlayHandler: now controls RecordBar, ReplyAnchor and AttachmentBoard
/// (circular reveal) without needing a separate overlayControllerProvider.
/// The attachment overlay is toggled using toggleAttachmentBoard / openAttachmentBoard / closeAttachmentBoard
/// and no longer listens to keyboard inset (we unfocus keyboard before opening).
///
/// NOTE: this file replaces previous OverlayHandler that depended on overlayControllerProvider.
library;

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/recording/record_bar.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/anchor_wrapper.dart';

// Attachment dependencies
import 'package:notesapp/root/screens/Chat_screen/widgets/components/attachment_board.dart';

final overlayHandlerProvider = Provider<OverlayHandler>((ref) => OverlayHandler(ref));

class OverlayHandler with WidgetsBindingObserver {
  OverlayHandler(this.ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref ref;

  OverlayEntry? _recordOverlay;
  OverlayEntry? _replyOverlay;

  // Attachment overlay (now fully controlled here)
  OverlayEntry? _attachmentOverlay;
  final ValueNotifier<bool> _isAttachmentOpen = ValueNotifier<bool>(false);

  final ValueNotifier<double> _keyboardInset = ValueNotifier(0);

  // Attachment params (matching previous AttachmentWrapper defaults)
  final double _attachmentBottomOffset = 80;
  final Duration _attachmentAnimationDuration = const Duration(milliseconds: 400);
  final Alignment _attachmentCircleAlignment = const Alignment(0.7, 1.0);

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _recordOverlay?.remove();
    _recordOverlay = null;

    _replyOverlay?.remove();
    _replyOverlay = null;

    _attachmentOverlay?.remove();
    _attachmentOverlay = null;

    _keyboardInset.dispose();
    _isAttachmentOpen.dispose();
  }

  @override
  void didChangeMetrics() {
    final double bottomInsets = WidgetsBinding.instance.window.viewInsets.bottom;
    final double pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final inset = bottomInsets / pixelRatio;
    if (_keyboardInset.value != inset) {
      _keyboardInset.value = inset;
    }
  }

  void updateKeyboardInset() {
    final double bottomInsets = WidgetsBinding.instance.window.viewInsets.bottom;
    final double pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final inset = bottomInsets / pixelRatio;
    if (_keyboardInset.value != inset) {
      _keyboardInset.value = inset;
    }
  }

  BuildContext? _overlayContext;

  // --------------------------------------------------------------------------
  // 🎙️ RECORD BAR
  // --------------------------------------------------------------------------

  void showRecordBar(BuildContext context, WidgetRef ref) {
    updateKeyboardInset();
    if (_recordOverlay != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final theme = Theme.of(context);

    _recordOverlay = OverlayEntry(
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          return ValueListenableBuilder<double>(
            valueListenable: _keyboardInset,
            builder: (context, bottomInset, _) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                left: 0,
                right: 0,
                bottom: (bottomInset + 70),
                child: Material(
                  type: MaterialType.transparency,
                  child: Theme(
                    data: theme,
                    child: const Align(
                      alignment: Alignment.bottomCenter,
                      child: ClipRRect(child: SizedBox(height: 85, child: RecordBar())),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    overlay.insert(_recordOverlay!);
  }

  Future<void> hideRecordBar({bool? instant = false}) async {
    if (_recordOverlay == null) return;
    if (instant == false) await Future.delayed(const Duration(milliseconds: 400));
    _recordOverlay?.remove();
    _recordOverlay = null;
  }

  // --------------------------------------------------------------------------
  // 💬 REPLY ANCHOR
  // --------------------------------------------------------------------------
  void showReplyAnchor(BuildContext context) {
    if (_replyOverlay != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final theme = Theme.of(context);

    _replyOverlay = OverlayEntry(
      builder: (_) {
        return ValueListenableBuilder<double>(
          valueListenable: _keyboardInset,
          builder: (context, bottomInset, _) {
            return Consumer(
              builder: (context, ref, _) {
                final anchorMessage = ref.watch(chatStateController).anchorMessage;
                final isRecording = ref.watch(chatStateController).isRecording;

                // Determine dynamic height (kept for compatibility)
                double targetHeight = 70;
                if (anchorMessage != null && isRecording) {
                  targetHeight = 130;
                }

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  left: 0,
                  right: 0,
                  bottom: bottomInset + (65),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Theme(
                      data: theme,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: const AnchorWrapper(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    overlay.insert(_replyOverlay!);
  }

  Future<void> hideReplyAnchor({bool? instant = false}) async {
    if (_replyOverlay == null) return;
    if (instant == false) await Future.delayed(const Duration(milliseconds: 300));
    _replyOverlay?.remove();
    _replyOverlay = null;
  }

  // --------------------------------------------------------------------------
  // 📎 ATTACHMENT (circular reveal) - centralized here
  // --------------------------------------------------------------------------

  /// Toggles the attachment board: opens it if closed, closes if open.
  /// Use this from your UI instead of using any provider.
  Future<void> toggleAttachmentBoard(BuildContext context) async {
    if (_attachmentOverlay == null) {
      await openAttachmentBoard(context);
    } else {
      await closeAttachmentBoard();
    }
  }

  /// Opens the attachment board overlay. Closes keyboard first (as requested).
  Future<void> openAttachmentBoard(BuildContext context) async {
    if (_attachmentOverlay != null) {
      // If overlay exists but state says closed, flip to open.
      _isAttachmentOpen.value = true;
      return;
    }

    // Close keyboard before showing attachment (user requested this behavior)
    FocusScope.of(context).unfocus();

    _overlayContext = context;
    _createAndInsertAttachmentOverlay(context);

    // set to open (this will drive the TweenAnimationBuilder to expand)
    _isAttachmentOpen.value = true;
  }

  /// Closes the attachment board overlay gracefully (plays animation then removes).
  Future<void> closeAttachmentBoard() async {
    if (_attachmentOverlay == null) return;

    // set to closed (animation will shrink)
    _isAttachmentOpen.value = false;

    // Wait the animation duration then remove the overlay entry.
    await Future.delayed(_attachmentAnimationDuration);
    _attachmentOverlay?.remove();
    _attachmentOverlay = null;
  }

  /// Immediately hide attachment overlay without animation.
  Future<void> hideAttachmentOverlayInstant() async {
    if (_attachmentOverlay == null) return;
    _attachmentOverlay?.remove();
    _attachmentOverlay = null;
    _isAttachmentOpen.value = false;
  }

  void _createAndInsertAttachmentOverlay(BuildContext context) {
    if (_attachmentOverlay != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);

    _attachmentOverlay = OverlayEntry(builder: (context) {
      final screenWidth = context.screenWidth;

      // NOTE: per request, attachment overlay does not listen to keyboard inset.
      // We position it using a fixed bottom offset. Keyboard is expected to be closed.
      return Positioned(
        bottom: _attachmentBottomOffset,
        left: 0,
        right: 0,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isAttachmentOpen,
          builder: (context, isOpen, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: isOpen ? (screenWidth * 1.2) : 0,
                ),
                duration: _attachmentAnimationDuration,
                curve: Curves.easeInOutQuint,
                builder: (context, radius, child) {
                  return ClipPath(
                    clipper: _CircularRevealClipper(
                      radius,
                      alignment: _attachmentCircleAlignment,
                    ),
                    child: child,
                  );
                },
                // Pass the isOpen flag into AttachmentBoard so it can adapt UI if needed.
                child: AttachmentBoard(isOpen: isOpen),
              ),
            );
          },
        ),
      );
    });

    overlay.insert(_attachmentOverlay!);
  }
}

/// Handles the circular reveal clipping effect used by the attachment overlay.
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