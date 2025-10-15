import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';

class RecordBar extends ConsumerStatefulWidget {
  const RecordBar({super.key});

  @override
  ConsumerState<RecordBar> createState() => _RecordBarState();
}

class _RecordBarState extends ConsumerState<RecordBar>
    with TickerProviderStateMixin {
  // --- Animation Durations (timeline clarity) ---
  static const Duration kCrushDuration = Duration(milliseconds: 350); // Bar crushes into circle
  static const Duration kFadeDuration = Duration(milliseconds: 300);  // Timer fades away
  static const Duration kSlideDuration = Duration(milliseconds: 400); // Slide down out of view
  static const Duration kResetDelay = Duration(milliseconds: 400);    // Reset state for next use

  // --- Animation Curves ---
  static const Curve kCrushCurve = Curves.easeInOutCubic;
  static const Curve kFadeCurve = Curves.easeOut;
  static const Curve kSlideCurve = Curves.easeInOutQuint;

  // --- Internal State ---
  final ValueNotifier<bool> _isCrushed = ValueNotifier(false);
  bool _shouldShow = true;

  @override
  void dispose() {
    _isCrushed.dispose();
    super.dispose();
  }

  Future<void> _onDeletePressed() async {
  final controller = ref.read(chatStateController.notifier);
  controller.cancelAudioRecording();

  // Start crush animation
  _isCrushed.value = true;
  setState(() {}); // ✅ No need for microtask anymore

  // Wait for crush animation
  await Future.delayed(kCrushDuration);

  // Slide down and hide
  if (mounted) setState(() => _shouldShow = false);

  // Reset
  await Future.delayed(kResetDelay);
  if (mounted) _isCrushed.value = false;
}


  @override
  Widget build(BuildContext context) {
    final isRecording =
        ref.watch(chatStateController.select((s) => s.isRecording));

    // Bring bar back when recording starts again
    if (isRecording && !_shouldShow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _shouldShow = true);
      });
    }

    final barColor = context.isLight
        ? ThemeConstants.senderBlue
        : const Color(0xFF29607E);

    return AnimatedSlide(
      duration: kSlideDuration,
      curve: kSlideCurve,
      offset: Offset(0, (isRecording && _shouldShow) ? 0 : 2),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isCrushed,
        builder: (context, crushed, _) {
          return AnimatedContainer(
            duration: kCrushDuration,
            curve: kCrushCurve,
            margin: const EdgeInsets.all(12),
            height: 60,
            width: crushed ? 60 : context.screenWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: barColor,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // --- TIMER (right) ---
                AnimatedOpacity(
                  duration: kFadeDuration,
                  curve: kFadeCurve,
                  opacity: crushed ? 0 : 1,
                  child: AnimatedAlign(
                    duration: kCrushDuration,
                    curve: kCrushCurve,
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      height: 50,
                      width: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.isLight
                            ? const Color(0xFF72AED1)
                            : ThemeConstants.senderBlueDark,
                      ),
                      child: const Text(
                        "00:00",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),

                // --- DELETE BUTTON (left) --- <====== Bottom of the stack so appears on top
                AnimatedAlign(
                  duration: kCrushDuration,
                  curve: kCrushCurve,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 50,
                    width: 50,
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.isLight
                          ? const Color(0xFF72AED1)
                          : ThemeConstants.senderBlueDark,
                    ),
                    child: IconButton(
                      onPressed: _onDeletePressed,
                      icon: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
