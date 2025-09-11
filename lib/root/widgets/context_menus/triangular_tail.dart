import 'package:flutter/material.dart';

/// A rounded rectangle with a small triangle on top
class TriangleBorder extends RoundedRectangleBorder {
  final double triangleHeight;
  final double triangleWidth;
  final double triangleOffset;

  const TriangleBorder({
    super.borderRadius,
    super.side,
    this.triangleHeight = 10.0,
    this.triangleWidth = 16.0,
    this.triangleOffset = 20.0,
  });

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final radius = borderRadius.resolve(textDirection);

    final double left = rect.left;
    final double top = rect.top;
    final double right = rect.right;
    final double bottom = rect.bottom;

    final path = Path();

    // Start at top-left corner (after rounding)
    path.moveTo(left + radius.topLeft.x, top);

    // Line to before triangle
    path.lineTo(left + triangleOffset, top);

    // Triangle
    path.lineTo(left + triangleOffset + triangleWidth / 2, top - triangleHeight);
    path.lineTo(left + triangleOffset + triangleWidth, top);

    // Continue along top edge
    path.lineTo(right - radius.topRight.x, top);

    // Top-right corner
    path.quadraticBezierTo(right, top, right, top + radius.topRight.y);

    // Right edge
    path.lineTo(right, bottom - radius.bottomRight.y);
    path.quadraticBezierTo(
        right, bottom, right - radius.bottomRight.x, bottom);

    // Bottom edge
    path.lineTo(left + radius.bottomLeft.x, bottom);
    path.quadraticBezierTo(
        left, bottom, left, bottom - radius.bottomLeft.y);

    // Left edge
    path.lineTo(left, top + radius.topLeft.y);
    path.quadraticBezierTo(left, top, left + radius.topLeft.x, top);

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final path = getOuterPath(rect, textDirection: textDirection);

    // Fill background (menu color will be applied here)
    final fillPaint = Paint()
      ..color = Colors.transparent // actual background is painted by Material
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw border manually
    if (side.style == BorderStyle.solid && side.width > 0) {
      final borderPaint = Paint()
        ..color = side.color
        ..strokeWidth = side.width
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);
    }
  }
}
