import 'package:flutter/material.dart';

/// Extensions for BuildContext for ease
extension ThemeX on BuildContext {
  bool get isLight => Theme.of(this).brightness == Brightness.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
}