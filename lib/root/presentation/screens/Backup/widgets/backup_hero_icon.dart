import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';

class BackupHeroIcon extends StatelessWidget {
  final double? circleSize;
  final double? iconSize;
  final Color? circleColor;
  final String? iconPath;
  final double? iconScale;
  final Widget? child;

  const BackupHeroIcon({
    super.key,
    this.circleSize,
    this.iconSize,
    this.circleColor,
    this.iconPath,
    this.iconScale,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedCircle = circleSize ?? 200;
    final resolvedIcon = iconSize ?? 80;

    return Center(
      child: SizedBox(
        height: resolvedCircle,
        width: resolvedCircle,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: resolvedCircle,
              width: resolvedCircle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor ?? ThemeConstants.darkIconBorder.withAlpha(100),
              ),
            ),
            SizedBox(
              height: resolvedIcon,
              width: resolvedIcon,
              child: child ?? vectorBuild(
                iconPath ?? IconPaths.floppy4,
                scale: iconScale ?? 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}