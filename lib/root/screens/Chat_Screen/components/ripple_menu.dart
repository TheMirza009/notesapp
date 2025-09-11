import 'package:flutter/material.dart';

class RippleMenu extends StatefulWidget {
  final Widget child;
  final Color? materialColor;
  final void Function()? onTap;
  final void Function(Offset position)? onLongPress;
  final BorderRadius? borderRadius;

  const RippleMenu({
    super.key,
    required this.child,
    this.materialColor,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
  });

  @override
  _RippleMenuState createState() => _RippleMenuState();
}

class _RippleMenuState extends State<RippleMenu> {
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.materialColor ?? Colors.transparent,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
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
        child: widget.child,
      ),
    );
  }
}
