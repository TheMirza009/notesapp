import 'dart:convert';

extension StringCaseX on String {
  String toSentenceCase() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();

  /// Safely decode this string into a List<String> for thread messages
  List<String> safeDecode() {
    if (trim().isEmpty) {
      return ["_Start typing your first thread_"];
    }

    try {
      final decoded = jsonDecode(this);

      if (decoded is List && decoded.isNotEmpty) {
        // Map all elements to string form
        return decoded.map((e) => e.toString()).toList();
      } else {
        // Handle case like []
        return ["_Start typing your first thread_"];
      }
    } catch (_) {
      // Gracefully recover from invalid JSON
      return ["_Start typing your first thread_"];
    }
  }

  /// Method to parse Array of Strings to single Human-readable text
  String formatThread() {
    final threads = safeDecode();
    return threads
        .asMap()
        .entries
        .map((entry) => '${entry.value}\n${entry.key + 1}/${threads.length}')
        .join('\n\n|\n\n');
  }

  int getThreadLength() {
    final threads = safeDecode();
    return threads.length;
  }
}
