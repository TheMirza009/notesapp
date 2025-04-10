import 'package:flutter/material.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';

class Message {
  final String text;
  final DateTime time;
  final Mediatype type;
  final bool isSender;
  final Media? _content;

  // Constructor
  const Message({
    required this.text,
    required this.time,
    this.type = Mediatype.text,
    this.isSender = true,
    Media? content,
  }) : _content = (type == Mediatype.text) ? null : content;

  // Getter for content that enforces the rule
  Media? get content {
    if (type == Mediatype.text) {
      return null;  // Content is not available for text messages
    }
    return _content; // Return the content for non-text messages
  }
}
