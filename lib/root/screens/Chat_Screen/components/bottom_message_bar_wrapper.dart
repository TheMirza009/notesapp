import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/bottom_message_bar.dart';

class BottomMessageBarWrapper extends ConsumerWidget {
  const BottomMessageBarWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("🔄 Message bar rebuilt");

    final notifier = ref.read(chatStateController.notifier);

    return RepaintBoundary(
      child: BottomMessageBar(
        focusNode: notifier.keyboardFocusNode,
        keyboardController: notifier.keyboardController,
        onFieldTap: () {notifier.hideEmojiPicker(); print("Field tapped");},
        onEmojiTap: () => notifier.toggleEmojiPicker(),
        onAttachmentTap: () => notifier.pickImage(),
        onMicTap: () => debugPrint("🎤 Mic tapped"),
        onSend: notifier.sendMessage,
        onImagePasted: (bytes) => notifier.pickImage(imageBytes: bytes),
      ),
    );
  }
}
