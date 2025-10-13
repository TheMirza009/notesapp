import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:share_plus/share_plus.dart';

class Utils {

    /// GLOBAL SNACKBAR
  static void showGlobalSnackBar(String value, Color color, {bool? showElevated = false}) {
    final messenger = scaffoldMessengerkey.currentState;

    if (messenger == null) return;
    // messenger.hideCurrentSnackBar();
    messenger.clearSnackBars();
    final SnackBar snackBar = SnackBar(
      margin: showElevated! ? EdgeInsets.only(bottom: 70, left: 10, right: 10) : EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 10.0),
      showCloseIcon: true,
      content: Text(value, style: const TextStyle(color: Colors.white),),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
      backgroundColor: color,
      dismissDirection: DismissDirection.down,
    );
    messenger.showSnackBar(snackBar);
  }


  /// Copy to clipboard function
  static void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Public Address copied to clipboard.")));
    // showCupertinoToast(context, "Public Address copied to clipboard");
    Utils.showGlobalSnackBar(
      "Code copied to clipboard",
      ThemeConstants.iconColorNeutral,
      showElevated: true,
    );
  }

  /// SHARE TEXT
  static Future<void> shareToApps(XFile file) async {
    // await Share.share(text);
    await Share.shareXFiles([file]);
  }

  static Future<String> getFileSize(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception("File does not exist at path: $filePath");
    }

    int bytes = await file.length();

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(2)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }
}
