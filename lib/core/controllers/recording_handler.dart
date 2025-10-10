import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class Recorder {
  Recorder._internal();
  static final Recorder _instance = Recorder._internal();
  factory Recorder() => _instance;

  final record = AudioRecorder();
  String? _recordedFile;

  Future<void> startRecording() async {
    if (await record.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      const config = RecordConfig(
        encoder: AudioEncoder.wav, // PCM16
        sampleRate: 44100,
        bitRate: 128000,
      );

      await record.start(config, path: path);
      _recordedFile = path;
    }
  }

  Future<String?> stopRecording() async {
    if (!await record.isRecording()) return null;
    await record.stop();
    final path = _recordedFile;
    _recordedFile = null;
    return path;
  }

  Future<void> cancelRecording() async {
    if (_recordedFile == null) return;
    if (await record.isRecording()) await record.stop();

    final tempFile = File(_recordedFile!);
    if (await tempFile.exists()) await tempFile.delete();

    _recordedFile = null;
  }

  Future<bool> get isRecording async => await record.isRecording();
}
