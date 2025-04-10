import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';


class DocumentIcon extends StatelessWidget {
  final double size;

  // Constructor to accept size, with a default value
  const DocumentIcon({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ThemeConstants.circleIconBackgroundLight, // Background color
        shape: BoxShape.circle,
        border: Border.all(
          color: ThemeConstants.circleIconBorderLight, // Border color
          width: 3, // Border width
        ),
      ),
      child: Icon(
        CupertinoIcons.doc_text_fill, // Document icon
        color: ThemeConstants.circleIconLight, // Icon color
        size: size * 0.6, // Icon size relative to the container size
      ),
    );
  }
}
