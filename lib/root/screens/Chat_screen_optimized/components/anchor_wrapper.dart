import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_3.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/wrappers/anchor_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/notifier/chat_state_notifier.dart';

class AnchorWrapperOptimized extends ConsumerWidget {
  const AnchorWrapperOptimized({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("🔄 Anchor Wrapper rebuilt");

    final notifier = ref.read(chatStateController.notifier);
    final anchorMessage = ref.watch(chatStateController.select((s) => s.anchorMessage));

    if (anchorMessage == null) return const SizedBox.shrink();

    return AnchorWrapper(
      text: anchorMessage.text,
      media: anchorMessage.media.value,
      onClear: () => notifier.clearAnchorMessage(),
    );
  }
}
