import 'package:flutter/material.dart';

class ThemeConstants {
  /// Screen Sizes
  static double screenWidth = 0;
  static double screenHeight = 0;

  /// Homescreen Colors
  static const hometoolbarLight = Color.fromARGB(255, 210, 217, 222);
  static const circleIconBorderLight = Color.fromARGB(255, 135, 150, 160);
  static const circleIconBackgroundLight = Color.fromARGB(255, 164, 182, 191);
  static const circleIconLight = Color.fromARGB(255, 232, 247, 248);
  static const homeSubtitleLight = Color.fromARGB(255, 133, 148, 158);
  static const homeSearchbarLight = Color.fromARGB(255, 206, 218, 219);
  static const homeDividerLight = Color.fromARGB(255, 164, 182, 191);

  static const silverGrey = Color(0xFFD1D8DD);
  static const silverSunlight = Color(0xFFEBE7E0);

  /// Chat screen colors
  static const toolbarLight = Color(0xFFF3F5F8);
  static const senderBlue = Color(0xFFAACBDE);
  static const textLight = Color(0xFF131B24);
  static const subtitleLight = Color(0xFF6D7D87);
  static const iconLight = Color(0xFF54666F);

  /// Chat Bubble padding
  static const bubblePaddingHorizontal = 16.0; // Define horizontal padding
  static const bubblePaddingVertical =
      bubblePaddingHorizontal / 2; // Vertical padding is half

  static const lightBackground = LinearGradient(
    colors: [silverSunlight, silverGrey],
    begin: Alignment(-2.0, -2.5),
    end: Alignment(1.0, 0.5),
  );
}
