import 'package:flutter/material.dart';

class Gradients {
  static const silverGrey = Color(0xFFD1D8DD);
  static const silverSunlight = Color(0xFFEBE7E0);
  static const silverSunlight2 = Color.fromARGB(255, 238, 231, 217);

  static const shadowBlue = Color(0xFF11161a);
  static const marianaBlue = Color(0xFF2b3c4c);

  static const lightBackground = LinearGradient(
    colors: [silverSunlight2, silverGrey],
    begin: Alignment(-2.0, -2.5),
    end: Alignment(1.0, 0.5),
  );

  static const darkBackground = LinearGradient(
    colors: [shadowBlue, marianaBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkChatBackground = LinearGradient(
    colors: [Gradients.shadowBlue, Gradients.marianaBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomLeft,
  );

  static const darkAlertBackground = LinearGradient(
    colors: [Color.fromARGB(255, 28, 39, 50), Color.fromARGB(255, 22, 33, 41), Color.fromARGB(255, 30, 46, 61)],
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
  );
}
