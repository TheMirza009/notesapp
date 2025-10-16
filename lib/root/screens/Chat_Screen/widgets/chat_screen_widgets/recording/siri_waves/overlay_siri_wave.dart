// overlay_live_siri.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:notesapp/core/controllers/recording_handler.dart';
import 'package:record/record.dart';

/// Notifier that tells the painter to repaint (phase + amplitude).
class WaveRepaintNotifier extends ChangeNotifier {
  double phase = 0.0;
  double amplitude = 0.0;

  void update({required double phase, required double amplitude}) {
    this.phase = phase;
    this.amplitude = amplitude;
    notifyListeners();
  }
}

// ----------------------------------------------------------------------------
// Recreated IOS7 painter (kept behavior close to original)
class IOS7SiriWaveformPainter extends CustomPainter {
  final WaveRepaintNotifier notifier;
  final Color color;
  final double frequency;
  final double speed;
  IOS7SiriWaveformPainter({
    required this.notifier,
    required this.color,
    required this.frequency,
    required this.speed,
  }) : super(repaint: notifier);

  static const _amplitudeFactor = .6;
  static const _attenuationFactor = 4;
  static const _curves = <_IOS7SiriWaveformCurve>[
    (attenuation: -2, width: 1.0, opacity: .10),
    (attenuation: -6, width: 1.0, opacity: .20),
    (attenuation: 4, width: 1.0, opacity: .40),
    (attenuation: 2, width: 1.0, opacity: .60),
    (attenuation: 1, width: 1.5, opacity: 1.00),
  ];
  static const _graphX = 2.0;
  static const _pixelDepth = .02;

  double _phase = 0.0;

  num _globalAttenuationFactor(num x) => math.pow(
        _attenuationFactor /
            (_attenuationFactor + math.pow(x, _attenuationFactor)),
        _attenuationFactor,
      );

  double _xPos(double i, Size size) =>
      size.width * ((i + _graphX) / (_graphX * 2));

  double _yPos(double i, double attenuation, double maxHeight) =>
      _amplitudeFactor *
      (_globalAttenuationFactor(i) *
          (maxHeight * notifier.amplitude) *
          (1 / attenuation) *
          math.sin(frequency * i - _phase));

  @override
  void paint(Canvas canvas, Size size) {
    final maxHeight = size.height / 2;

    for (final curve in _curves) {
      final path = Path()..moveTo(0, maxHeight);
      for (var i = -_graphX; i <= _graphX; i += _pixelDepth) {
        final x = _xPos(i, size);
        final y = maxHeight + _yPos(i, curve.attenuation, maxHeight);
        path.lineTo(x, y);
      }

      final paint = Paint()
        ..color = color.withOpacity(curve.opacity)
        ..strokeWidth = curve.width
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawPath(path, paint);
    }

    // advance phase based on notifier.phase (the notifier drives it)
    _phase = notifier.phase;
  }

  @override
  bool shouldRepaint(covariant IOS7SiriWaveformPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.frequency != frequency ||
      oldDelegate.speed != speed;
}

typedef _IOS7SiriWaveformCurve = ({double attenuation, double opacity, double width});

// ----------------------------------------------------------------------------
// The robust overlay-safe widget
class OverlayLiveSiriWave extends StatefulWidget {
  const OverlayLiveSiriWave({
    super.key,
    this.height = 80,
    this.color,
    this.frequency = 2.0,
    this.speed = 0.15,
    this.fps = 60,
  });

  final double height;
  final Color? color;
  final double frequency;
  final double speed;
  final int fps; // target frames per second for the painter updates

  @override
  State<OverlayLiveSiriWave> createState() => _OverlayLiveSiriWaveState();
}

class _OverlayLiveSiriWaveState extends State<OverlayLiveSiriWave>
    with SingleTickerProviderStateMixin {
  final WaveRepaintNotifier _notifier = WaveRepaintNotifier();
  late final Ticker _ticker;
  late final Recorder _recorder;
  StreamSubscription<Amplitude>? _sub;

  double _currentAmp = 0.0;
  double _phase = 0.0;
  int _lastFrameMs = 0;

  // smoothing for amplitude
  static const double _smoothing = 0.7;

  @override
  void initState() {
    super.initState();

    _recorder = Recorder();

    // subscribe to recorder amplitude (dB -> normalized 0..1)
    _sub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 30)).listen((amp) {
      double db = amp.current.isNaN ? -45.0 : amp.current;
      if (db > 0) db = -db;
      double normalized = (db + 45) / 45;
      normalized = ((normalized - 0.05) * 1.5).clamp(0.0, 1.0);
      // smoothing
      _currentAmp = _currentAmp * _smoothing + normalized * (1 - _smoothing);
    });

    // create a ticker to drive the notifier at target fps
    final msPerFrame = (1000 / widget.fps).round();
    _ticker = createTicker((elapsed) {
      final nowMs = elapsed.inMilliseconds;
      final deltaMs = (nowMs - _lastFrameMs).clamp(0, 1000);
      if (deltaMs < msPerFrame) return; // throttle frame rate
      _lastFrameMs = nowMs;

      // advance phase based on delta time and configured speed
      final speed = widget.speed;
      _phase += (deltaMs / 1000.0) * (math.pi * 2) * speed;
      _phase %= (math.pi * 2);

      // push values into notifier -> triggers painter repaint
      _notifier.update(phase: _phase, amplitude: _currentAmp);
    });
    _ticker.start();
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
        painter: IOS7SiriWaveformPainter(
          notifier: _notifier,
          color: color,
          frequency: widget.frequency,
          speed: widget.speed,
        ),
      ),
    );
  }
}
