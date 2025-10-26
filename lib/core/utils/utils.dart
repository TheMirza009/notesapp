import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/data/enums/bubble_color.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/bubble_color_scheme.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class Utils {

    /// GLOBAL SNACKBAR
  static void showGlobalSnackBar(
  String value,
  Color color, {
  bool? showElevated = false,
  bool useMaterial = true,
}) {
  final messenger = scaffoldMessengerkey.currentState;
  if (messenger == null) return;

  messenger.clearSnackBars();

  if (useMaterial) {
    // ✅ Use Flutter's default Material Snackbar
    final SnackBar snackBar = SnackBar(
      margin: showElevated!
          ? const EdgeInsets.only(bottom: 70, left: 10, right: 10)
          : const EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 10.0),
      showCloseIcon: true,
      content: Text(
        value,
        style: const TextStyle(color: Colors.white),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
      backgroundColor: color,
      dismissDirection: DismissDirection.down,
    );

    messenger.showSnackBar(snackBar);
  } else {
    // ✅ Use simple custom Snackbar (no Material SnackBar)
    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: showElevated! ? 70 : 10,
        left: 15,
        right: 15,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Overlay.of(context).dispose(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    messenger.context.findRenderObject();
    Overlay.of(messenger.context)?.insert(overlay);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlay.mounted) overlay.remove();
    });
  }
}




  /// Copy to clipboard function
  static void copyTextToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Public Address copied to clipboard.")));
    // showCupertinoToast(context, "Public Address copied to clipboard");
    Utils.showGlobalSnackBar(
      "Code copied to clipboard",
      ThemeConstants.iconColorNeutral,
      showElevated: true,
    );
  }

 static Future<void> copyImageFromPath(String? path) async {
  if (path == null || path.isEmpty) {
    debugPrint('⚠️ copyImageFromPath: No image path provided.');
    return;
  }

  try {
    final file = File(path);

    if (!await file.exists()) {
      debugPrint('❌ copyImageFromPath: File not found at $path');
      return;
    }

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      debugPrint('⚠️ copyImageFromPath: Empty image file.');
      return;
    }

    // ✅ Use MediaHandler to write it to a shareable temporary location
    final tempDir = await getApplicationDocumentsDirectory();
    final tempPath = '${tempDir.path}/temp_clipboard_image.png';
    final tempFile = await File(tempPath).writeAsBytes(bytes);

    debugPrint('📄 Copied image to temp path: ${tempFile.path}');

    // ✅ Now copy to clipboard
    await Pasteboard.writeImage(await tempFile.readAsBytes());

    debugPrint('✅ Image copied to clipboard successfully.');
    Utils.showGlobalSnackBar(
      "Image copied to clipboard",
      ThemeConstants.iconColorNeutral,
      showElevated: true,
    );
  } catch (e, st) {
    debugPrint('❌ Failed to copy image to clipboard: $e');
    debugPrint(st.toString());
  }
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

  static bool isAndroidGestureNavigationEnabled(BuildContext context) {
    final value = MediaQuery.of(context).systemGestureInsets.bottom;
    return value < 48.0 && value != 0.0;
  }
  static void smoothNavigate(BuildContext? context, Widget child) {
  final ctx = context ?? navigatorKey.currentContext!;
  Navigator.of(ctx).push(
    PageRouteBuilder(
      opaque: false, // makes the fade more natural
      barrierColor: Colors.black26, // subtle dim background like iOS
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInQuint,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8, // slightly larger, then settles
              end: 1.0,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

static Size getObjectSize({required GlobalKey objectKey}) {
  final RenderBox box = objectKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = box.size;
    return size;
}

static Offset getObjectPosition({required GlobalKey objectKey, double? heightOffset}) {
    final RenderBox box = objectKey.currentContext!.findRenderObject() as RenderBox;
    final Offset globalPosition = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    
    // We want centerRight → x = right edge, y = vertical center
    final Offset position = Offset(
      globalPosition.dx + size.width,
      globalPosition.dy + size.height / (heightOffset ?? 1.5),
    );
    return position;
  }

  static BubbleColorScheme getBubbleColorScheme(
    BuildContext context,
    {BubbleStyle? style,
    BubbleColor? color,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    switch (style) {
      case BubbleStyle.glass:
        return isLight
            ? BubbleColorScheme.glassLight()
            : BubbleColorScheme.glassDark();
      case BubbleStyle.opaque:
        return BubbleColorScheme.getScheme(context, (color ?? BubbleColor.seed));
      default:
        return isLight
            ? BubbleColorScheme.defaultLight()
            : BubbleColorScheme.defaultDark();
    }
  }
}
