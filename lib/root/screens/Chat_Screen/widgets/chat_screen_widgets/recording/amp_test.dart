import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:siri_wave/siri_wave.dart';

class MicPage extends StatelessWidget {
  const MicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: const LiveMicSiriWave(),
      ),
    );
  }
}

class LiveMicSiriWave extends StatefulWidget {
  const LiveMicSiriWave({super.key});

  @override
  State<LiveMicSiriWave> createState() => _LiveMicSiriWaveState();
}

class _LiveMicSiriWaveState extends State<LiveMicSiriWave> {
  final AudioRecorder _recorder = AudioRecorder();
  late IOS7SiriWaveformController _waveController;
  final ValueNotifier<double> _amplitude = ValueNotifier(0.0);
  StreamSubscription<Amplitude>? _sub;

  @override
  void initState() {
    super.initState();
    _waveController = IOS7SiriWaveformController(
      amplitude: 0.0,
      color: Colors.greenAccent,
      frequency: 3,
      speed: 0.35,
    );
    _startRecording();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;

    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/mic_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    // Listen to amplitude stream directly
    _sub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 30))
        .listen((amp) {
      double db = amp.current.isNaN ? -45.0 : amp.current;
      if (db > 0) db = -1 * db;

      // Map -45..0 dB → 0..1
      double normalized = (db + 45) / 45;

      // Less sensitive: only loud noises trigger wave
      normalized = (normalized - 0.3).clamp(0.0, 1.0);

      // Smooth amplitude
      _amplitude.value = _amplitude.value * 0.7 + normalized * 0.3;

      // Update SiriWave directly
      _waveController.amplitude = _amplitude.value;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _recorder.stop();
    _amplitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<double>(
          valueListenable: _amplitude,
          builder: (context, value, _) {
            return Text(
              'VOLUME\n${(value * 100).round()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        SiriWaveform.ios7(
          controller: _waveController,
          options: const IOS7SiriWaveformOptions(
            height: 300,
            width: 400,
          ),
        ),
      ],
    );
  }
}
