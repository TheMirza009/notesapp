import 'package:flutter/material.dart';

class RippleWell extends StatefulWidget {
  final Widget child;
  final Color? materialColor;
  final void Function()? onTap;
  final void Function(Offset position)? onLongPress;
  final BorderRadius? borderRadius;

  /// New parameters
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;

  const RippleWell({
    super.key,
    required this.child,
    this.materialColor,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  _RippleWellState createState() => _RippleWellState();
}

class _RippleWellState extends State<RippleWell> {
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: Material(
        color: widget.materialColor ?? Colors.transparent,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
        child: Ink(
          decoration: widget.decoration,
          child: InkWell(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
            onTapDown: (details) {
              _tapPosition = details.globalPosition;
            },
            onTap: widget.onTap,
            onLongPress: () {
              if (_tapPosition != null && widget.onLongPress != null) {
                widget.onLongPress!(_tapPosition!);
              }
            },
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
