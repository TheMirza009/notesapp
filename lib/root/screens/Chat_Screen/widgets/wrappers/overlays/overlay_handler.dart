import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/recording/record_bar.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/anchor_wrapper.dart';

final overlayHandlerProvider = Provider<OverlayHandler>((ref) => OverlayHandler(ref));

class OverlayHandler with WidgetsBindingObserver {
  OverlayHandler(this.ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref ref;

  OverlayEntry? _recordOverlay;
  OverlayEntry? _replyOverlay;

  final ValueNotifier<double> _keyboardInset = ValueNotifier(0);

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardInset.dispose();
  }

@override
void didChangeMetrics() {
  final inset = WidgetsBinding.instance.window.viewInsets.bottom /
              WidgetsBinding.instance.window.devicePixelRatio;
  if (_keyboardInset.value != inset) {
    _keyboardInset.value = inset;
  }
}

void updateKeyboardInset() {
  final inset = WidgetsBinding.instance.window.viewInsets.bottom /
              WidgetsBinding.instance.window.devicePixelRatio;
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
                // curve: Curves.easeOut,
                left: 0,
                right: 0,
                bottom: (bottomInset + 70) , //  _keyboardInset.value
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
              final isReplying = anchorMessage != null;
              final isRecording = ref.watch(chatStateController).isRecording;

              // Determine dynamic height
              double targetHeight = 70;
              if (anchorMessage != null && isRecording) {
                // Replace requiresExpansion with your actual condition
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
}
