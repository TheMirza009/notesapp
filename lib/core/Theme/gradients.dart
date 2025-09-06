import 'package:flutter/material.dart';

class Gradients {
  static const silverGrey = Color(0xFFD1D8DD);
  static const silverSunlight = Color(0xFFEBE7E0);
  static const silverSunlight2 = Color.fromARGB(255, 238, 231, 217);

  static const lightBackground = LinearGradient(
    colors: [silverSunlight2, silverGrey],
    begin: Alignment(-2.0, -2.5),
    end: Alignment(1.0, 0.5),
  );
}
