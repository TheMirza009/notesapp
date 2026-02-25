import 'dart:ui';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/main.dart';

class WindowsUtils {
  static void setTitleBarColor(Color color) {
    if (!kisWindows) return;
    Future.microtask(() => windowsTitleBarColor.value = color);
  }

  static void clearTitleBarColor() {
    if (!kisWindows) return;
    Future.microtask(() => windowsTitleBarColor.value = null);
  }

  static void setTitleBarColorDirect(Color color) {
    if (!kisWindows) return;
    (windowsTitleBarColor.value = color);
  }

  static void clearTitleBarColorDirect() {
    if (!kisWindows) return;
    (windowsTitleBarColor.value = null);
  }
}