import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:svg_flutter/svg.dart';


class DocumentIcon extends StatelessWidget {
  final double size;
  final double? borderWidth;
  final EdgeInsets? iconPadding;

  // Constructor to accept size, with a default value
  const DocumentIcon({super.key, 
  this.size = 50,
  this.borderWidth = 3, 
  this.iconPadding,
  });

  @override
  Widget build(BuildContext context) {
    bool isLight = Theme.brightnessOf(context) == Brightness.light;
    Color borderColor = isLight ? ThemeConstants.circleIconBorderLight : ThemeConstants.darkIconBorder;
    Color bgColor = isLight ? ThemeConstants.circleIconBackgroundLight : ThemeConstants.darkIconbackground;
    Color iconColor = isLight ? ThemeConstants.circleIconLight : ThemeConstants.darkIconforeground;
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor, // Background color
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor, // Border color
            width: borderWidth ?? 3, // Border width
          ),
        ),
        child: Padding(
          padding: iconPadding ?? const EdgeInsets.all(5.0),
          child: SvgPicture.string(IconPaths.roundedDoc, color: iconColor),
        )
        // Icon(
        //   CupertinoIcons.doc_text_fill, // Document icon
        //   color: ThemeConstants.circleIconLight, // Icon color
        //   size: size * 0.6, // Icon size relative to the container size
        // ),
      ),
    );
  }
}
