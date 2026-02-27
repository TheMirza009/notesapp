import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/components/emoji_board.dart';


class EmojiBoardWrapper extends ConsumerStatefulWidget {
  const EmojiBoardWrapper({super.key});

  @override
  ConsumerState<EmojiBoardWrapper> createState() => _EmojiBoardWrapperState();
}

class _EmojiBoardWrapperState extends ConsumerState<EmojiBoardWrapper> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint("🔄 Emoji board rebuilt");

    final notifier = ref.read(chatStateController.notifier);
    final showEmojis = ref.watch(chatStateController.select((s) => s.showEmojis));

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: showEmojis ? 280 : 0,
          child: EmojiBoard(
            showEmojis: showEmojis,
            textController: notifier.keyboardController,
            keyboardHeight: 280,
          ),
        ),
      ),
    );
  }
}
