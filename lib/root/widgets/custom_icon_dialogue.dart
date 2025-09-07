import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/emojione_monotone.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';

class CustomAlertDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final String? iconData;
  final Color? iconColor;
  final Widget? option;
  final void Function()? onOkPressed;
  const CustomAlertDialog({super.key, this.title, this.content, this.iconData, this.iconColor, this.onOkPressed, this.option});

  @override
  Widget build(BuildContext context) {
    var seedColor = (context.isLight ? const Color.fromARGB(255, 48, 160, 205) : ThemeConstants.sinisterSeed);
    var backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkAlertBackground;
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width >= 600 ? 300 : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: iconColor?.withOpacity(0.2) ?? seedColor.withOpacity(0.2),
              ),
              child: Iconify(
                iconData ?? (EmojioneMonotone.exclamation_mark),
                size: 15,
                color: iconColor ?? seedColor,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              title ?? "Alert!",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                content ?? "Please select atleast one product before payment.",
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: option == null ? MainAxisAlignment.center : MainAxisAlignment.center, //.end,
              children: [
                TextButton(
                  onPressed: () {
                    onOkPressed?.call();
                    Navigator.pop(context);
                  },
                  child: Text("Close", style: TextStyle(color: option == null ? null : (context.isDark ? ThemeConstants.textDark : ThemeConstants.darkIconbackground)),),
                ),
                if (option != null) option!,
              ],
            )
          ],
        ),
      ),
    );
  }
}