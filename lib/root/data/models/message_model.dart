import 'package:notesapp/root/data/models/media_model.dart';
import 'package:uuid/uuid.dart';


class Message {
  final String id;
  final String text;      // Text message (empty if media-only)
  final DateTime time;    // Timestamp
  final bool isSender;    // Whether current user sent it
  final bool isSelected;
  final Media? media;     // Media attached (null for text-only)

  static final Uuid _uuid = Uuid();

  Message({
    String? id,
    required this.text,
    required this.time,
    this.isSender = true,
    this.isSelected = false,
    this.media,
  }) : id = id ?? _uuid.v7();

  /// Creates a copy with optional overrides
  Message copyWith({
    String? id,
    String? text,
    DateTime? time,
    bool? isSender,
    bool? isSelected,
    Media? media,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      time: time ?? this.time,
      isSender: isSender ?? this.isSender,
      isSelected: isSelected ?? this.isSelected,
      media: media ?? this.media,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, isSender: $isSender, time: $time, text: "$text", media: $media)';
  }
}