import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurX;
  final double blurY;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurX = 6.0,
    this.blurY = 6.0,
    this.borderRadius = 30.0,
    this.borderWidth = 1.0,
    this.borderColor = const Color.fromARGB(100, 255, 255, 255),
    this.backgroundColor = const Color.fromRGBO(255, 255, 255, 0.15),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          // Background blur layer - SINGLE BackdropFilter for entire area
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurX, 
                sigmaY: blurY,
                tileMode: TileMode.clamp,
              ),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Glass content layer
          Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(width: borderWidth, color: borderColor),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}