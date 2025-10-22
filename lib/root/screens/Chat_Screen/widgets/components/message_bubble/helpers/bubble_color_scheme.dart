import 'package:flutter/material.dart';

class BubbleColorScheme {
  final Color senderBubble;
  final Color receiverBubble;
  final Color highlightedSender;
  final Color highlightedReceiver;
  final Color glassSender;
  final Color glassReceiver;
  final Color replyBackground;

  const BubbleColorScheme({
    required this.senderBubble,
    required this.receiverBubble,
    required this.highlightedSender,
    required this.highlightedReceiver,
    required this.glassSender,
    required this.glassReceiver,
    required this.replyBackground,
  });

  /// Example factory for light theme
  factory BubbleColorScheme.light() => const BubbleColorScheme(
        senderBubble: Color(0xFF007AFF),
        receiverBubble: Color(0xFFF1F1F1),
        highlightedSender: Color(0xFFF5FBFF),
        highlightedReceiver: Color(0xFFFFFFFF),
        glassSender: Color.fromARGB(38, 0, 122, 255),
        glassReceiver: Color.fromARGB(38, 255, 255, 255),
        replyBackground: Color(0xFFEBF5FB),
      );

  /// Example factory for dark theme
  factory BubbleColorScheme.dark() => const BubbleColorScheme(
        senderBubble: Color(0xFF004E92),
        receiverBubble: Color(0xFF2C2C2E),
        highlightedSender: Color(0xFF5A9CC0),
        highlightedReceiver: Color(0xFF677F8D),
        glassSender: Color.fromARGB(38, 0, 122, 255),
        glassReceiver: Color.fromARGB(38, 255, 255, 255),
        replyBackground: Color(0xFF2E3A4A),
      );
}
