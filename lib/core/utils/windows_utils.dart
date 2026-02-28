import 'dart:ui';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/main.dart';

class WindowsUtils {
  static double? titlebarHeight = 40;

  static void setTitleBarColor(Color color) {
    if (!kisDesktop) return;
    Future.microtask(() => windowsTitleBarColor.value = color);
  }

  static void clearTitleBarColor() {
    if (!kisDesktop) return;
    Future.microtask(() => windowsTitleBarColor.value = null);
  }

  static void setTitleBarColorDirect(Color color) {
    if (!kisDesktop) return;
    (windowsTitleBarColor.value = color);
  }

  static void clearTitleBarColorDirect() {
    if (!kisDesktop) return;
    (windowsTitleBarColor.value = null);
  }
}