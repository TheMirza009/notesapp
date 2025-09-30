import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/reply_anchor.dart';

class AnchorWrapper extends ConsumerWidget {
  const AnchorWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("🔄 Anchor Wrapper rebuilt");

    final notifier = ref.read(chatStateController.notifier);
    final anchorMessage = ref.watch(chatStateController.select((s) => s.anchorMessage));

    // if (anchorMessage == null) return const SizedBox.shrink();

    return ReplyAnchor(
      text: anchorMessage?.text,
      media: anchorMessage?.media.value,
      onClear: () => notifier.clearAnchorMessage(),
    );
  }
}
