import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';

class CustomIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final double size;
  final Color backgroundColor;
  final Color? splashColor;
  final EdgeInsets? padding;

  const CustomIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 40,
    this.backgroundColor = Colors.transparent, 
    this.splashColor, 
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: backgroundColor, // background circle color
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashColor: splashColor ?? ThemeConstants.circleIconBorderLight,
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(0),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
