// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:notesapp/root/screens/Chat_screen/components/anchor_wrapper.dart';
// import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/record_bar.dart';

// OverlayEntry? _bottomOverlay;

// void showBottomOverlay(BuildContext context, WidgetRef ref) {
//   if (_bottomOverlay != null) return;

//   final theme = Theme.of(context);
//   final overlay = Overlay.of(context, rootOverlay: true);

//   _bottomOverlay = OverlayEntry(
//     builder: (_) => Consumer(
//       builder: (context, ref, _) {
//         final state = ref.watch(chatStateController);
//         final showReply = state.anchorMessage != null;
//         final showRecord = state.isRecording;

//         if (!showReply && !showRecord) return const SizedBox.shrink();

//         return Positioned(
//           left: 0,
//           right: 0,
//           bottom: 65,
//           child: Material(
//             type: MaterialType.transparency,
//             child: Theme(
//               data: theme,
//               child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: ClipRect(
//                   child: AnimatedSize(
//                     duration: const Duration(milliseconds: 300),
//                     curve: Curves.easeInOut,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         if (showReply) const AnchorWrapper(),
//                         if (showRecord) const RecordBar(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     ),
//   );

//   overlay.insert(_bottomOverlay!);
// }

// Future<void> maybeRemoveBottomOverlay(WidgetRef ref) async {
//   final state = ref.read(chatStateController);
//   if (!state.isRecording && state.anchorMessage == null) {
//     await Future.delayed(const Duration(milliseconds: 250));
//     _bottomOverlay?.remove();
//     _bottomOverlay = null;
//   }
// }
