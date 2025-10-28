import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/bottom_message_bar.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/overlays/overlay_handler.dart';

class BottomMessageBarWrapper extends ConsumerStatefulWidget {
  const BottomMessageBarWrapper({super.key});

  @override
  ConsumerState<BottomMessageBarWrapper> createState() => _BottomMessageBarWrapperState();
}

class _BottomMessageBarWrapperState extends ConsumerState<BottomMessageBarWrapper> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final notifier = ref.read(chatStateController.notifier);
    final isRecording = ref.watch(chatStateController.select((s) => s.isRecording));
    final isEditing = ref.watch(chatStateController.select((s) => s.isEditing));

    final overlayHandler = ref.read(overlayHandlerProvider);
    // overlayHandler.updateKeyboardInset();

    return RepaintBoundary(
      child: BottomMessageBar(
        focusNode: notifier.keyboardFocusNode,
        keyboardController: notifier.keyboardController,
        onFieldTap: () {
          notifier.hideEmojiPicker();
          notifier.scrollToBottomIfLastMessageVisible();
          overlayHandler.closeAttachmentBoard();
        },
        onEmojiTap: () {
          notifier.toggleEmojiPicker();
          overlayHandler.closeAttachmentBoard();
          },
        onAttachmentTap: () {
          // notifier.pickImage();
          notifier.keyboardFocusNode.unfocus();
          if (isRecording) {
            notifier.cancelAudioRecording();
          }
      
          // ✅ Only clear anchor if we’re not recording
          if (notifier.state.anchorMessage != null && !isRecording) {
            notifier.clearAnchorMessage();
          }
      
          if (notifier.state.showEmojis) {
            notifier.hideEmojiPicker();
          }
      
           overlayHandler.toggleAttachmentBoard(context);
          // final state = ref.read(openingProvider.notifier);
          // state.state = !state.state; // <======= Called here
        },
        onMicTap: () async {
          // Navigator.push(context, CupertinoPageRoute(builder: (_) => MicPage()));
          if (isRecording) {
            notifier.stopAudioRecording();
            await overlayHandler.hideRecordBar();
            debugPrint("🎙️Recording stopped");
          } else {
            await overlayHandler.closeAttachmentBoard();
      
            if (notifier.isReplying == true) {
              debugPrint("⬅️ isReplying: $isRecording");
            }
            notifier.closeSearchAndKeyboard();
            notifier.startAudioRecording();
            overlayHandler.showRecordBar(context, ref);
            debugPrint("🎙️Recording started");
          }
        },
        onEdit: (newText) async {
          final Message? heldMessage =  ref.watch(chatStateController).highlightedMessage;
          if (heldMessage != null && isEditing == true) {
            await notifier.editTextMessage(heldMessage, newText);
          }
        },
        onSend: notifier.sendMessage,
        onImagePasted: (bytes) => notifier.pickImage(imageBytes: bytes),
        onSendThread: notifier.saveThread,
      ),
    );
  }
}

// OverlayEntry? recordOverlay;

// void _showRecordBar(BuildContext context, WidgetRef ref) {
//   if (recordOverlay != null) return; // ✅ Prevent duplicates

//   final overlay = Overlay.of(context, rootOverlay: true);

//   recordOverlay = OverlayEntry(
//     builder:
//         (overlayContext) => Consumer(
//           builder: (context, ref, _) {
//             final theme = Theme.of(context);
//             return Positioned(
//               left: 0,
//               right: 0,
//               bottom: 70,
//               child: Material(
//                 type: MaterialType.transparency,
//                 child: Theme(
//                   data: theme,
//                   child: Align(
//                     alignment: Alignment.bottomCenter,
//                     child: ClipRect(
//                       child: SizedBox(height: 85, child: const RecordBar()),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//   );

//   if (replyOverlay != null) {
//     overlay.insert(recordOverlay!, above: replyOverlay);
//   } else {
//     overlay.insert(recordOverlay!);
//   }
// }

// Future<void> _hideRecordBar() async {
//   if (recordOverlay == null) return;

//   // ✅ Wait for RecordBar’s internal slide animation
//   await Future.delayed(const Duration(milliseconds: 500));

//   // ✅ Remove safely after delay
//   recordOverlay?.remove();
//   recordOverlay = null;
// }
