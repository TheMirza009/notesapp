import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/presentation/screens/Settings/notifier/settings_notifier.dart';


class ThemeNotifier extends StateNotifier<ThemeData> {
  ThemeNotifier(bool? isLight) : super(_getTheme(isLight));

  static ThemeData _getTheme(bool? isLight) {
    if (isLight == null) {
      return _initialTheme;
    }
    return isLight ? _lightTheme : _darkTheme;
  }

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
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontFamily: 'Poppins'),
      bodyMedium: TextStyle(fontFamily: 'Poppins'),
      bodySmall: TextStyle(fontFamily: 'Poppins'),
      titleLarge: TextStyle(fontFamily: 'Poppins'),
      titleMedium: TextStyle(fontFamily: 'Poppins'),
      titleSmall: TextStyle(fontFamily: 'Poppins'),
    ).apply(
      fontFamily: 'Poppins',
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
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontFamily: 'Poppins'),
      bodyMedium: TextStyle(fontFamily: 'Poppins'),
      bodySmall: TextStyle(fontFamily: 'Poppins'),
      titleLarge: TextStyle(fontFamily: 'Poppins'),
      titleMedium: TextStyle(fontFamily: 'Poppins'),
      titleSmall: TextStyle(fontFamily: 'Poppins'),
    ).apply(fontFamily: 'Poppins', bodyColor: ThemeConstants.textDark2),
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

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  final isLight = ref.watch(settingsController.select((s) => s?.isLightMode));
  return ThemeNotifier(isLight);
});

