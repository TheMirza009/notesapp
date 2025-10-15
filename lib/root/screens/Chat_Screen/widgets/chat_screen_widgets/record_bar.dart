import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/recording_handler.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/widgets/voice_message/components/voice_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:siri_wave/siri_wave.dart';

class RecordBar extends ConsumerStatefulWidget {
  const RecordBar({super.key});

  @override
  ConsumerState<RecordBar> createState() => _RecordBarState();
}

class _RecordBarState extends ConsumerState<RecordBar> with TickerProviderStateMixin {
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

  // Start crush animation
  _isCrushed.value = true;
  setState(() {}); // ✅ No need for microtask anymore

  // Wait for crush animation
  await Future.delayed(kCrushDuration);

    // Cancel recording AFTER animation completes
  await controller.cancelAudioRecording();

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

                const SiriWaveMic(),

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
class SiriWaveMic extends StatefulWidget {
  const SiriWaveMic({super.key});

  @override
  State<SiriWaveMic> createState() => _SiriWaveMicState();
}

class _SiriWaveMicState extends State<SiriWaveMic> {
  final controller = IOS7SiriWaveformController(
    amplitude: 0.0,
    color: Colors.red,
    frequency: 4,
    speed: 0.15,
  );

  StreamSubscription<Amplitude>? _ampSub;
  double _smoothedAmp = 0.0;

  @override
  void initState() {
    super.initState();

    // listen to amplitude from global recorder
    _ampSub = Recorder()
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((amp) {
      final target = (amp.current / 100).clamp(0.0, 1.0);
      _smoothedAmp = _smoothedAmp * 0.7 + target * 0.3; // smooth it
      controller.amplitude = _smoothedAmp;
    });
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SiriWaveform.ios7(
      controller: controller,
      options: const IOS7SiriWaveformOptions(
        height: 80,
        width: 300,
      ),
    );
  }
}
