import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:notesapp/root/widgets/glass_container.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/ripple_menu.dart';

class GlassBubble extends StatelessWidget {
  final String text;
  final DateTime time;
  final bool isSender;

  /// RippleWell props
  final void Function()? onTap;
  final void Function(Offset)? onLongPress;
  final BorderRadius? rippleBorderRadius;
  final Color? rippleColor;

  /// GlassContainer props
  final double blurX;
  final double blurY;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isSender,
    this.onTap,
    this.onLongPress,
    this.rippleBorderRadius,
    this.rippleColor,
    this.blurX = 25,
    this.blurY = 25,
    this.borderRadius = 15,
    this.borderWidth = 1.0,
    this.borderColor = const Color.fromARGB(100, 255, 255, 255),
    this.backgroundColor = const Color.fromRGBO(255, 255, 255, 0.15),
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: !isSender ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(
          left: isSender ? 45.0 : 8,
          right: isSender ? 8 : 45,
          top: 8,
          bottom: 8,
        ),
        child: RippleWell(
          borderRadius: rippleBorderRadius ?? BorderRadius.circular(borderRadius),
          materialColor: rippleColor,
          onTap: onTap,
          onLongPress: onLongPress,
          child: GlassContainer(
            blurX: blurX,
            blurY: blurY,
            borderRadius: borderRadius,
            borderWidth: borderWidth,
            borderColor: borderColor,
            backgroundColor: backgroundColor,
            padding: padding,
            width: width,
            height: height,
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(fontSize: 20),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat.jm().format(time),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
