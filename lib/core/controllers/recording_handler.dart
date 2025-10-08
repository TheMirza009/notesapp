import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class Recorder {
  final record = AudioRecorder();
  String? recordedFile;

  void startRecording() async {
    if (await record.hasPermission()) {

      // Get OS temporary directory
      final tempDir = await getTemporaryDirectory();

      // Record config handling
      const RecordConfig config = RecordConfig(
        encoder: AudioEncoder.wav, // PCM16
        sampleRate: 44100,
        bitRate: 128000,
      );

      // Path setting
      final String recordingPath = "${tempDir.path}/recording_${DateTime.now()}.mp3"; // add chat title here as well

      await record.start(config, path: recordingPath);
      if (await record.isRecording()) {
        recordedFile = recordingPath;
      }
    }
  }

  Future<String?> stopRecording() async {
    if (!await record.isRecording()) return null;

    await record.stop();
    final path = recordedFile;
    recordedFile = null;
    return path;
  }

  Future<void> cancelRecording() async {
    if (recordedFile == null) return;

    final bool isRecording = await record.isRecording();
    final File tempFile = File(recordedFile!);

    if (isRecording) await record.stop();
    if (await tempFile.exists()) await tempFile.delete();

    recordedFile = null;
  }
}
