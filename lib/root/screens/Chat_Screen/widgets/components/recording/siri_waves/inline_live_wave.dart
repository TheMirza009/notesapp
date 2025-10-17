// inline_live_wave.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:notesapp/core/controllers/recording_handler.dart';
import 'package:record/record.dart';

/// Notifier carrying the values the painter needs; when it notifies,
/// CustomPainter.paint will be called (because we pass this as `repaint`).
class WaveRepaintNotifier extends ChangeNotifier {
  double phase = 0.0;      // advances every frame
  double amplitude = 0.0;  // 0..1 scaled amplitude

  void update({required double phase, required double amplitude}) {
    this.phase = phase;
    this.amplitude = amplitude;
    notifyListeners();
  }
}

/// A simple, efficient waveform painter that draws several sine layers.
class WavePainter extends CustomPainter {
  final WaveRepaintNotifier notifier;
  final Color color;
  final int lines;
  final double frequency; // number of waves across width
  final bool joinEnds;    // ✅ new flag

  WavePainter({
    required this.notifier,
    required this.color,
    this.lines = 3,
    this.frequency = 1.5,
    this.joinEnds = false, // default off for backward compatibility
  }) : super(repaint: notifier);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final centerY = size.height / 2;
    final width = size.width;

    for (int i = 0; i < lines; i++) {
      final t = i / (lines - 1 + 0.0001);
      final layerAmplitude = notifier.amplitude * (0.6 + 0.4 * (1 - t));
      final stroke = 1.0 + (2.0 * (1 - t));
      paint
        ..strokeWidth = stroke
        ..color = color.withOpacity(0.25 + 0.75 * (1 - t));

      final path = Path();

      final freq = frequency * (1 + t * 0.5);
      final phaseShift = notifier.phase * (1 + t * 0.8);
      final yScale = centerY * 0.9;

      const int steps = 120;
      for (int s = 0; s <= steps; s++) {
        final x = (s / steps) * width;
        final relativeX = s / steps;
        final angle = (relativeX * freq * 2 * math.pi) + phaseShift;

        // Normal wave y
        double y = centerY + math.sin(angle) * layerAmplitude * yScale;

        // ✅ Force ends flat if joinEnds = true
        if (joinEnds) {
          final edgeBlend = math.sin(relativeX * math.pi); 
          // This makes amplitude 0 at edges (0..1..0 curve)
          y = centerY + math.sin(angle) * layerAmplitude * yScale * edgeBlend;
        }

        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.lines != lines ||
        oldDelegate.frequency != frequency ||
        oldDelegate.joinEnds != joinEnds;
  }
}


/// Inline widget that connects recorder -> smoothing -> ticker -> painter.
class InlineLiveWave extends StatefulWidget {
  const InlineLiveWave({
    super.key,
    this.height = 60,
    this.color,
    this.frequency = 1.6,
    this.fps = 60,
    this.joinEnds = true,
  });

  final double height;
  final Color? color;
  final double frequency;
  final bool? joinEnds;
  final int fps; // target fps for painter updates; lower to save work.

  @override
  State<InlineLiveWave> createState() => _InlineLiveWaveState();
}

class _InlineLiveWaveState extends State<InlineLiveWave>
    with SingleTickerProviderStateMixin {
  final Recorder _recorder = Recorder();
  final WaveRepaintNotifier _notifier = WaveRepaintNotifier();
  late final Ticker _ticker;
  StreamSubscription<Amplitude>? _sub;

  double _currentAmplitude = 0.0; // smoothed amplitude (0..1)
  double _phase = 0.0; // grows with time
  int _lastFrameMs = 0;

  // Simple smoothing params
  static const double _smoothing = 0.65;

  @override
  void initState() {
    super.initState();

    // Listen to amplitude changes from recorder
    _sub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 30)).listen((amp) {
      // record plugin gives dB values (negative), normalize to 0..1
      double db = amp.current.isNaN ? -45.0 : amp.current;
      if (db > 0) db = -db; // ensure negative
      double normalized = (db + 45) / 45; // 0..1
      normalized = ((normalized - 0.05) * 1.5).clamp(0.0, 1.0); // tweak sensitivity

      // smooth the input signal
      _currentAmplitude = _currentAmplitude * _smoothing + normalized * (1 - _smoothing);
    });

    // Ticker drives both phase and notifier updates. We throttle to requested fps.
    final msPerFrame = (1000 / widget.fps).round();
    _ticker = createTicker((elapsed) {
      final nowMs = elapsed.inMilliseconds;
      final deltaMs = math.max(0, nowMs - _lastFrameMs);
      if (deltaMs < msPerFrame) return; // throttle

      _lastFrameMs = nowMs;

      // Advance phase based on elapsed time (tweak speed multiplier)
      final speed = 0.012; // smaller -> slower phase
      _phase += deltaMs * speed;
      // keep phase bounded
      if (_phase > 1e6) _phase %= (2 * math.pi);

      // You can scale amplitude for visuals
      final displayAmp = (_currentAmplitude).clamp(0.0, 1.0);

      // Update the notifier (this triggers painter repaint)
      _notifier.update(phase: _phase, amplitude: displayAmp);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: WavePainter(
          notifier: _notifier,
          joinEnds: widget.joinEnds ?? true,
          color: color,
          lines: 3,
          frequency: widget.frequency,
        ),
      ),
    );
  }
}
