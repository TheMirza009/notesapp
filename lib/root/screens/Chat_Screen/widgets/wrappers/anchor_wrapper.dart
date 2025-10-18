import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/reply_anchor.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/bottom_message_bar_wrapper.dart';

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
      onClear: () {
        notifier.clearAnchorMessage();},
    );
  }
}


// OverlayEntry? replyOverlay;

// /// Reply Anchor
// void showReplyAnchor(BuildContext context) {
//   if (replyOverlay != null) return; // prevent duplicates

//   final theme = Theme.of(context);
//   final overlay = Overlay.of(context, rootOverlay: true);

//   replyOverlay = OverlayEntry(
//     builder: (_) => Positioned(
//       left: 0,
//       right: 0,
//       bottom: 65, // just above BottomMessageBar (same as RecordBar)
//       child: Material(
//         type: MaterialType.transparency,
//         child: Theme(
//           data: theme,
//           child: Align(
//             alignment: Alignment.bottomCenter,
//             child: ClipRect(
//               child: SizedBox(
//                 height: 100,
//                 child: Align(
//                   alignment: Alignment.bottomCenter,
//                   child: AnchorWrapper(), // ✅ uses your ReplyAnchor wrapper
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     ),
//   );

//   if (recordOverlay != null) {
//     overlay.insert(replyOverlay!, above: recordOverlay);
//   } else {
//     overlay.insert(replyOverlay!);
//   }
// }

// Future<void> hideReplyAnchor() async {
//   if (replyOverlay == null) return;

//   // wait for slide animation to finish
//   await Future.delayed(const Duration(milliseconds: 300));

//   replyOverlay?.remove();
//   replyOverlay = null;
// }

