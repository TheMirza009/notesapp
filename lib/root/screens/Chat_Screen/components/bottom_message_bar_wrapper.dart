import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/screens/Chat_screen/components/attachment/attachment_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/components/attachment/overlay_controller.dart';
import 'package:notesapp/root/screens/Chat_screen/components/emerging_overlay.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/attachment_board.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/bottom_message_bar.dart';

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
            // notifier.closeSearchAndKeyboard();
            ref.read(overlayControllerProvider.notifier).close();
          },
          onEmojiTap: () => notifier.toggleEmojiPicker(),
          onAttachmentTap: () {
            // notifier.pickImage();
            notifier.keyboardFocusNode.unfocus();
            ref.read(overlayControllerProvider.notifier).toggle();
            // final state = ref.read(openingProvider.notifier);
            // state.state = !state.state; // <======= Called here
          },
          onMicTap: () async {
            if (isRecording) {
              notifier.stopAudioRecording();
              print("🎙️Recording stopped");
            } else {
              notifier.startAudioRecording();
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
