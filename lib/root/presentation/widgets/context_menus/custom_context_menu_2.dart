import 'package:flutter/material.dart';

/// Flexible menu item model
class MenuItem {
  final String? label;
  final IconData? icon;
  final Widget? widget;
  final VoidCallback onTap;

  const MenuItem({
    this.label,
    this.icon,
    this.widget,
    required this.onTap,
  }) : assert(
          (label != null || widget != null),
          "Either `label` or `widget` must be provided",
        );

  /// Shortcut for simple label-only item
  factory MenuItem.text(String label, VoidCallback onTap) {
    return MenuItem(label: label, onTap: onTap);
  }

  /// Shortcut for label + icon
  factory MenuItem.icon(String label, IconData icon, VoidCallback onTap) {
    return MenuItem(label: label, icon: icon, onTap: onTap);
  }

  /// Shortcut for fully custom widget
  factory MenuItem.custom(Widget widget, VoidCallback onTap) {
    return MenuItem(widget: widget, onTap: onTap);
  }
}

class CustomContextMenu2 {
  final Offset position;
  final List<MenuItem> items;
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final double elevation;

  const CustomContextMenu2({
    required this.position,
    required this.items,
    this.backgroundColor,
    this.shape,
    this.elevation = 8.0,
  });

  Future<void> show(BuildContext context) async {
    await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: backgroundColor ?? Theme.of(context).cardColor,
      shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: elevation,
      items: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return PopupMenuItem<int>(
          value: index,
          onTap: item.onTap,
          child: item.widget ??
              Row(
                children: [
                  if (item.icon != null) Icon(item.icon, size: 18),
                  if (item.icon != null) const SizedBox(width: 8),
                  if (item.label != null) Text(item.label!),
                ],
              ),
        );
      }).toList(),
    );
  }
}
