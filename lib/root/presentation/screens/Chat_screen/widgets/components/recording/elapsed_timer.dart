import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/old_notifiers/chat_state_notifier_o.dart';

class ElapsedTimer extends ConsumerStatefulWidget {
  const ElapsedTimer({super.key});

  @override
  ConsumerState<ElapsedTimer> createState() => _RecordingTimerState();
}

class _RecordingTimerState extends ConsumerState<ElapsedTimer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (_startTime != null) {
      final diff = DateTime.now().difference(_startTime!);
      if (mounted) {
        setState(() => _elapsed = diff);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(chatStateController.select((s) => s.isRecording));

    // Start or stop the ticker when recording state changes
    if (isRecording && !_ticker.isActive) {
      _startTime = DateTime.now();
      _ticker.start();
    } else if (!isRecording && _ticker.isActive) {
      _ticker.stop();
      _startTime = null;
      _elapsed = Duration.zero;
    }

    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);

    final formatted = hours > 0
        ? "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"
        : "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Text(
        formatted,
        key: ValueKey(hours > 0), // triggers size change
        style: TextStyle(
          color: Colors.white,
          fontSize: hours > 0 ? 12 : 14,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
