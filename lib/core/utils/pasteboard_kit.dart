import 'package:pasteboard/pasteboard.dart';

class PasteboardKit {
  static Future<void> readAndWriteFiles() async {
    final paths = ['your_file_path'];
    await Pasteboard.writeFiles(paths);

    final files = await Pasteboard.files();
    print(files);
  }

  static Future<void> readImages() async {
    final imageBytes = await Pasteboard.image;
    print(imageBytes?.length);
  }
}
