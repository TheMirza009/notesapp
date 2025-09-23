import 'package:notesapp/root/data/models/media_model.dart';

extension MediaX on Media {
  DateTime? get messageTime {
    // backlinks always point to the messages containing this media
    return messagesBacklink.isNotEmpty ? messagesBacklink.first.time : null;
  }
}
