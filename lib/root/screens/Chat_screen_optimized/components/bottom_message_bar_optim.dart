import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_3.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/bottom_message_bar.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/components/emoji_board_optim.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/notifier/chat_state_notifier.dart';

class BottomMessageBarOptimized extends ConsumerWidget {
  const BottomMessageBarOptimized({super.key});

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
