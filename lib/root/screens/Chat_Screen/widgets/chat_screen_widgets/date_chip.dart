import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/time_format.dart';

/// Available chip styles
enum DateChipStyle { basic, bordered }

class DateChip extends StatelessWidget {
  final DateTime time;
  final DateChipStyle _style;

  /// Customization options
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Default (basic chip)
  const DateChip(
    this.time, {
    super.key,
    this.color,
    this.borderColor,
    this.borderRadius = 20,
    this.textStyle,
    this.padding = const EdgeInsets.only(bottom: 8.0, top: 20),
    this.margin = EdgeInsets.zero,
  }) : _style = DateChipStyle.basic;

  /// Bordered chip
  const DateChip.bordered(
    this.time, {
    super.key,
    this.color,
    this.borderColor,
    this.borderRadius = 5,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
    this.margin = EdgeInsets.zero,
  }) : _style = DateChipStyle.bordered;

  @override
  Widget build(BuildContext context) {
    final text = TimeFormat.formatChatDateChip(time);

    switch (_style) {
      case DateChipStyle.basic:
        return _buildBasic(text, context);

      case DateChipStyle.bordered:
        return _buildBordered(text, context);
    }
  }

  /// --- Modules ---

  Widget _buildBasic(String text, BuildContext context) {
    var borderColor = context.isLight ? Colors.grey.shade400 : const Color(0xFF4C5D65);
    return Padding(
      padding: padding,
      child: Chip(
        side: BorderSide(color: borderColor),
        label: Text(
          text,
          style: textStyle ?? const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color ?? ( context.isLight ? Colors.grey.shade300 : ThemeConstants.darkIconBorder),
      ),
    );
  }

  Widget _buildBordered(String text, BuildContext context) {
    final defaultBorderColor = context.isLight ? const Color(0xFFB3B0A8) : const Color(0xFF436A81);

    return Padding(
      padding: padding,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          border: Border.all(
            width: 1,
            color: borderColor ?? defaultBorderColor,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Text(
          text,
          style: textStyle ??
              const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
