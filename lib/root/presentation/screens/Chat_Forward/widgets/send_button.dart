import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';

class SendButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback? onPressed;

  // Optional customization parameters
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;
  final Duration duration;
  final Curve curve;
  final double scale;

  const SendButton({
    super.key,
    required this.isVisible,
    required this.onPressed,
    this.icon = Icons.send,
    this.backgroundColor,
    this.iconColor,
    this.iconSize = 28,
    this.padding = const EdgeInsets.all(12),
    this.alignment = Alignment.bottomRight,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOutQuint,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveBackground =
        backgroundColor ?? ThemeConstants.sinisterSeedHighlight;
    final Color effectiveIconColor = iconColor ?? ThemeConstants.textDark2;

    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: AnimatedScale(
          scale: isVisible ? scale : 0.0,
          duration: duration,
          curve: curve,
          child: Material(
            color: effectiveBackground,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: 3,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
