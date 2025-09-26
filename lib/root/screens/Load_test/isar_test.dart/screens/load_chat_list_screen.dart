import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_3.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/bottom_message_bar.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/emoji_board.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_tile_og.dart';
import 'package:notesapp/root/screens/Load_test/isar_test.dart/note_item.dart';
import 'package:notesapp/root/screens/Load_test/isar_test.dart/screens/test_chat_screen.dart';
import 'package:notesapp/root/screens/Load_test/widgets/pulldown_wrapper.dart';
import 'package:path_provider/path_provider.dart';

class LoadChatListScreen extends ConsumerWidget {
  const LoadChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatMessagesController.notifier);
    final messages = ref.watch(chatMessagesController);
    return Scaffold(
      appBar: AppBar(
        title: Text("Emoji Test"),
        actions: [
          IconButton(
            icon: Icon(
              context.isLight
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed:
                () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          notifier.hideEmojiPicker();
          notifier.keyboardFocusNode.unfocus();
        },
        child: Container(
          color: const Color.fromARGB(255, 18, 23, 27),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Emoji picker
              BottomMessageBar(
                focusNode: notifier.keyboardFocusNode,
                keyboardController: notifier.keyboardController,
                onFieldTap: notifier.hideEmojiPicker,
                onEmojiTap: notifier.toggleEmojiPicker,
                onAttachmentTap: () => notifier.pickImage(),
                onMicTap: () => debugPrint("notifier.state"),
                onSend: (txt) => notifier.sendMessage(txt),
                onImagePasted:
                    (imageBytes) => notifier.pickImage(imageBytes: imageBytes),
              ),
          
              // if (notifier.showEmojis)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: notifier.showEmojis ? 280 : 0,
                    child: EmojiBoard(
                      showEmojis: notifier.showEmojis,
                      textController: notifier.keyboardController,
                      keyboardHeight: 280,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Utility to listen to keyboard metrics changes
class LifecycleEventHandler extends WidgetsBindingObserver {
  final VoidCallback onMetricsChanged;
  LifecycleEventHandler({required this.onMetricsChanged});

  @override
  void didChangeMetrics() {
    onMetricsChanged();
  }
}
