import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/screens/Chat_screen/components/anchor_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/components/attachment/attachment_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/components/attachment/overlay_controller.dart';
import 'package:notesapp/root/screens/Chat_screen/components/emerging_overlay.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/attachment_board.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/bottom_message_bar.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/record_bar.dart';

class BottomMessageBarWrapper extends ConsumerWidget {
  const BottomMessageBarWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatStateController.notifier);
    final isRecording = ref.watch(chatStateController.select((s) => s.isRecording));

    return RepaintBoundary(
      child: AttachmentWrapper(
        overlay: AttachmentBoard(
          isOpen: !ref.watch(overlayControllerProvider),
          onGalleryPressed: notifier.pickImage,
          ),
        child: BottomMessageBar(
          focusNode: notifier.keyboardFocusNode,
          keyboardController: notifier.keyboardController,
          onFieldTap: () {
            notifier.hideEmojiPicker();
            ref.read(overlayControllerProvider.notifier).close();
          },
          onEmojiTap: () => notifier.toggleEmojiPicker(),
          onAttachmentTap: () {
            // notifier.pickImage();
            notifier.keyboardFocusNode.unfocus();
            if (isRecording) {
              notifier.cancelAudioRecording();
            }

            // ✅ Only clear anchor if we’re not recording
            if (notifier.state.anchorMessage != null && !isRecording) {
              notifier.clearAnchorMessage();
            }

            ref.read(overlayControllerProvider.notifier).toggle();
            // final state = ref.read(openingProvider.notifier);
            // state.state = !state.state; // <======= Called here
          },
          onMicTap: () async {
            if (isRecording) {
              notifier.stopAudioRecording();
              await _hideRecordBar();
              print("🎙️Recording stopped");
            } else {
              if (ref.read(overlayControllerProvider.notifier).state == true) {
                ref.read(overlayControllerProvider.notifier).close();
              }
              notifier.startAudioRecording();
              _showRecordBar(context, ref);
              print("🎙️Recordting started");
            }
          },
          onSend: notifier.sendMessage,
          onImagePasted: (bytes) => notifier.pickImage(imageBytes: bytes),
        ),
      ),
    );
  }
}

OverlayEntry? recordOverlay;

void _showRecordBar(BuildContext context, WidgetRef ref) {
  if (recordOverlay != null) return; // ✅ Prevent duplicates

  final theme = Theme.of(context);
  final overlay = Overlay.of(context, rootOverlay: true);

  recordOverlay = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      right: 0,
      bottom: 65, // attaches directly above BottomMessageBar
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: theme,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRect( // ✅ masks any overflow during animation
              child: SizedBox(
                height: 100, // ✅ zone constraints
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: const RecordBar(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  if (replyOverlay != null) {
    overlay.insert(recordOverlay!, above: replyOverlay);
  } else {
    overlay.insert(recordOverlay!);
  }
}

Future<void> _hideRecordBar() async {
  if (recordOverlay == null) return;

  // ✅ Wait for RecordBar’s internal slide animation
  await Future.delayed(const Duration(milliseconds: 500));

  // ✅ Remove safely after delay
  recordOverlay?.remove();
  recordOverlay = null;
}

