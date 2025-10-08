import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';


class ThemeNotifier extends StateNotifier<ThemeData> {
  ThemeNotifier() : super(_initialTheme);

  /// isDark bool
  bool get isDark => state.brightness == Brightness.dark;

  /// Function to get Device default theme
  static ThemeData get _initialTheme {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark ? _darkTheme : _lightTheme;
  }

  /// Light theme definition
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: ThemeConstants.textLight,
    ),
    dividerColor: ThemeConstants.homeDividerLight,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: ThemeConstants.lightseedColor,
    ),
  );

  /// Light theme definition
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: ThemeConstants.textDark2,
    ),
    dividerColor: ThemeConstants.darkAppbar,
     colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: ThemeConstants.sinisterSeed,
    ),
  );

  /// Theme Toggle
  void toggleTheme() {
    if (state.brightness == Brightness.light) {
      state = _darkTheme;
    } else {
      state = _lightTheme;
    }
  }

  void setDarkTheme() {
    state = _darkTheme;
  }

  void setLightTheme() {
    state = _lightTheme;
  }

  void setSystemDefaultTheme() {
    state = _initialTheme;
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) => ThemeNotifier());
