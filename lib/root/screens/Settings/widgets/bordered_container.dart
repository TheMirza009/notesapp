import 'package:flutter/material.dart';

class BorderedContainer extends StatelessWidget {
  final Widget child;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final Color? color;
  final Color? borderColor;
  final double? height;
  final double? width;
  final double? borderRadius;
  final double? borderThickness;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? margins;
  final Decoration? decoration;
  const BorderedContainer({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.borderRadius = 15,
    this.borderThickness,
    this.contentPadding,
    this.margins, this.height, this.width,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margins ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius ?? 15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius ?? 15),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Ink(
            height: height,
            width: width,
            padding: contentPadding,
            decoration: decoration ?? ShapeDecoration(
              color: color,
              shape:  RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius ?? 15),
                side: BorderSide(
                  color: borderColor ?? Theme.of(context).dividerColor,
                  width: borderThickness ?? 1.5,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
