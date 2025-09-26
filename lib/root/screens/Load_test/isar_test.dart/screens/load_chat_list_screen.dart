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
import 'package:notesapp/root/screens/Homescreen/components/chat_tile_og.dart';
import 'package:notesapp/root/screens/Load_test/isar_test.dart/note_item.dart';
import 'package:notesapp/root/screens/Load_test/isar_test.dart/screens/test_chat_screen.dart';
import 'package:notesapp/root/screens/Load_test/widgets/pulldown_wrapper.dart';
import 'package:path_provider/path_provider.dart';

class LoadChatListScreen extends ConsumerStatefulWidget {
  const LoadChatListScreen({super.key});

  @override
  ConsumerState<LoadChatListScreen> createState() => _LoadTestScreenState();
}

class _LoadTestScreenState extends ConsumerState<LoadChatListScreen> {
  bool showEmojis = false;
  TextEditingController controller = TextEditingController();
  FocusNode textFieldFocusNode = FocusNode();
  double keyboardHeight = 250; // fallback height if keyboard size not known

  @override
  void initState() {
    super.initState();

    // Listen to focus changes
    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus && showEmojis) {
        setState(() {
          showEmojis = false; // hide emoji picker if keyboard opens
        });
      }
    });

    // Listen to keyboard appearance
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(onMetricsChanged: _onMetricsChanged),
    );
  }

  void _onMetricsChanged() {
    final newBottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (newBottomInset > 0) {
      keyboardHeight = newBottomInset;
      if (showEmojis) {
        setState(() => showEmojis = false);
      }
    }
  }

  void toggleEmojiPicker() {
    if (showEmojis) {
      // Hide emoji picker → open keyboard
      setState(() => showEmojis = false);
      Future.delayed(
        const Duration(milliseconds: 100),
        () => textFieldFocusNode.requestFocus(),
      );
    } else {
      // Hide keyboard → show emoji picker
      textFieldFocusNode.unfocus();
      Future.delayed(
        const Duration(milliseconds: 100),
        () => setState(() => showEmojis = true),
      );
    }
  }

  @override
  void dispose() {
    textFieldFocusNode.dispose();
    controller.dispose();
    WidgetsBinding.instance.removeObserver(
      LifecycleEventHandler(onMetricsChanged: _onMetricsChanged),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emoji Test"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Text input bar
          TextField(
            controller: controller,
            focusNode: textFieldFocusNode,
            onTap: () {
              if (showEmojis) setState(() => showEmojis = false);
            },
          ),
      
          // Emoji picker
          AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            offset: Offset(0, showEmojis ? 0 : 1),
            child: EmojiPicker(
              textEditingController: controller,
              config: Config(
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: Colors.blueGrey,
                ),
                skinToneConfig: SkinToneConfig(
                  dialogBackgroundColor: Colors.blueGrey,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: Colors.blueGrey,
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: Colors.blueGrey,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: Colors.blueGrey,
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: toggleEmojiPicker,
        child: const Icon(Icons.emoji_emotions_outlined),
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
