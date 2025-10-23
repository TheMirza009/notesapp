
//
// ----------------------------- DOCUMENT MESSAGE -----------------------------
//
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class DocumentMessageView extends StatefulWidget {
  final Message message;
  const DocumentMessageView({super.key, required this.message});

  @override
  State<DocumentMessageView> createState() => _DocumentMessageViewState();
}

class _DocumentMessageViewState extends State<DocumentMessageView> {
  // Cache futures per path so we don't re-trigger IO on every rebuild.
  final Map<String, Future<String>> _sizeFutureCache = {};

  Future<String> _getFileSize(String path) {
    return _sizeFutureCache.putIfAbsent(path, () async {
      try {
        // Utils.getFileSize returns Future<String> in your codebase.
        return await Utils.getFileSize(path);
      } catch (e, st) {
        debugPrint('Error getting file size for $path: $e\n$st');
        return 'Size unknown';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.message.media.value;
    final path = media?.path;

    const TextStyle subStyle = TextStyle(
      color: ThemeConstants.iconColorNeutral,
      fontSize: 13,
    );

    return RepaintBoundary(
      child: IntrinsicWidth(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0x0F000000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media?.name ?? "Unknown file",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (path != null)
                                  FutureBuilder<String>(
                                    future: _getFileSize(path),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Text('Loading size...', style: subStyle);
                                      } else if (snapshot.hasError) {
                                        return const Text('Size unknown', style: subStyle);
                                      } else {
                                        final data = snapshot.data ?? 'Size unknown';
                                        return Text(data, style: subStyle);
                                      }
                                    },
                                  ),
                                Text(
                                  (media?.extension ?? "").toUpperCase(),
                                  style: subStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10)
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  DateFormat.jm().format(widget.message.time),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ThemeConstants.subtitleLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
