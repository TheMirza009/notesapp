import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/enums/bubble_color.dart';

class BubbleColorScheme {
  final Color senderBubble;
  final Color receiverBubble;
  final Color highlightedSender;
  final Color highlightedReceiver;
  final Color replyBackground;

  const BubbleColorScheme({
    required this.senderBubble,
    required this.receiverBubble,
    required this.highlightedSender,
    required this.highlightedReceiver,
    required this.replyBackground,
  });

  /// Default bubble colors for light theme
  factory BubbleColorScheme.defaultLight() => const BubbleColorScheme(
        senderBubble: ThemeConstants.senderBlue,
        receiverBubble: ThemeConstants.hometoolbarLight3,
        highlightedSender: Color(0xFFF5FBFF),
        highlightedReceiver: Color(0xFFFFFFFF),
        replyBackground: Color(0xFFEBF5FB),
      );

  /// Default bubble colors for dark theme
  factory BubbleColorScheme.defaultDark() => const BubbleColorScheme(
        senderBubble:  ThemeConstants.senderBlueDark,
        receiverBubble: ThemeConstants.darkIconBorder,
        highlightedSender: Color(0xFF5A9CC0),
        highlightedReceiver: Color(0xFF677F8D),
        replyBackground: Color(0xFF2E3A4A),
      );

  /// Default bubble colors for light theme
  factory BubbleColorScheme.redLight() => const BubbleColorScheme(
        senderBubble: Color(0xFFD45353),
        receiverBubble: Color(0xFFEC9A9A),
        highlightedSender: Color(0xFFFF9595),
        highlightedReceiver: Color(0xFFFFFFFF),
        replyBackground: Color(0xFFFFCBCB),
      );

  /// Default bubble colors for dark theme
  factory BubbleColorScheme.redDark() => const BubbleColorScheme(
        senderBubble:  Color(0xFF550021),
        receiverBubble: Color(0xFF422E2E),
        highlightedSender: Color(0xFFC05A63),
        highlightedReceiver: Color(0xFFA36E6E),
        replyBackground: Color(0xFF4A2E2E),
      );

  /// Default bubble colors for light theme
  factory BubbleColorScheme.amberLight() => const BubbleColorScheme(
        senderBubble: Color.fromARGB(255, 255, 194, 28),
        receiverBubble: Color.fromARGB(255, 236, 203, 154),
        highlightedSender: Color.fromARGB(255, 255, 227, 149),
        highlightedReceiver: Color(0xFFFFFFFF),
        replyBackground: Color.fromARGB(255, 255, 232, 203),
      );

  /// Default bubble colors for dark theme
  factory BubbleColorScheme.amberDark() => const BubbleColorScheme(
        senderBubble:  Color.fromARGB(255, 161, 110, 0),
        receiverBubble: Color(0xFF6B5D47),
        highlightedSender: Color.fromARGB(255, 255, 187, 0),
        highlightedReceiver: Color.fromARGB(255, 255, 209, 123),
        replyBackground: Color.fromARGB(255, 136, 102, 57),
      );

  /// Glass bubble colors for light theme
  factory BubbleColorScheme.glassLight() => BubbleColorScheme(
        senderBubble: const Color(0xFF007AFF).withOpacity(0.15), // Colors.blue.withAlpha(0.15)
        receiverBubble: const Color(0xFFFFFFFF).withOpacity(0.15), // Colors.white.withAlpha(0.15)
        highlightedSender: const Color(0xFFF5FBFF).withOpacity(0.25), // Same as opaque but with glass opacity
        highlightedReceiver: const Color(0xFFFFFFFF).withOpacity(0.25), // Same as opaque but with glass opacity
        replyBackground: const Color(0xFFEBF5FB),
      );

  /// Glass bubble colors for dark theme
  factory BubbleColorScheme.glassDark() => BubbleColorScheme(
        senderBubble: const Color(0xFF004E92).withOpacity(0.15), // Colors.blue.withAlpha(0.15)
        receiverBubble: const Color(0xFFFFFFFF).withOpacity(0.15), // Colors.white.withAlpha(0.15)
        highlightedSender: const Color(0xFF5A9CC0).withOpacity(0.25), // Same as opaque but with glass opacity
        highlightedReceiver: const Color(0xFF677F8D).withOpacity(0.25), // Same as opaque but with glass opacity
        replyBackground: const Color(0xFF2E3A4A),
      );

  static BubbleColorScheme getScheme(BuildContext context, BubbleColor color) {
    switch (color) {
      case BubbleColor.seed:
        return context.isLight ? BubbleColorScheme.defaultLight() : BubbleColorScheme.defaultDark();
      case BubbleColor.red:
        return context.isLight ? BubbleColorScheme.redLight() : BubbleColorScheme.redDark();
      case BubbleColor.amber:
        return context.isLight ? BubbleColorScheme.amberLight() : BubbleColorScheme.amberDark();
      default:
        return context.isLight ? BubbleColorScheme.defaultLight() : BubbleColorScheme.defaultDark();
    }
  }

 // ------------------------------------------------------------
  // 🌈 New Factory: From Seed Color (Dynamic Color Generation)
  // ------------------------------------------------------------
  factory BubbleColorScheme.fromSeedColor(Color baseColor, {bool darkMode = false}) {
    final hsl = HSLColor.fromColor(baseColor);

    // Adjust tones based on light/dark mode
    final sender = hsl.withLightness(
      (darkMode ? (hsl.lightness * 0.6) : (hsl.lightness * 0.9)).clamp(0.0, 1.0),
    );

    final receiver = hsl.withLightness(
      (darkMode ? (hsl.lightness * 0.35) : (hsl.lightness * 1.2)).clamp(0.0, 1.0),
    );

    final highlightSender = hsl.withLightness(
      (darkMode ? (hsl.lightness * 0.8) : (hsl.lightness * 1.05)).clamp(0.0, 1.0),
    );

    final highlightReceiver = hsl.withLightness(
      (darkMode ? (hsl.lightness * 0.7) : (hsl.lightness * 1.1)).clamp(0.0, 1.0),
    );

    final replyBg = hsl.withLightness(
      (darkMode ? (hsl.lightness * 0.45) : (hsl.lightness * 1.15)).clamp(0.0, 1.0),
    );

    return BubbleColorScheme(
      senderBubble: sender.toColor(),
      receiverBubble: receiver.toColor(),
      highlightedSender: highlightSender.toColor().withOpacity(0.9),
      highlightedReceiver: highlightReceiver.toColor().withOpacity(0.9),
      replyBackground: replyBg.toColor().withOpacity(0.8),
    );
  }
}