import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/widgets/context_menus/triangular_tail.dart';

class CustomContextMenu extends StatelessWidget {
  final Icon? icon; // optional, fallback to default
  final Widget Function(BuildContext context)? iconBuilder; // 🔹 new flexible trigger
  final List<PopupMenuEntry<String>> menuItems;
  final void Function(String)? onSelected;
  final Color? backgroundColor;
  final Offset? offset;

  const CustomContextMenu({
    super.key,
    this.icon,
    this.iconBuilder,
    required this.menuItems,
    this.onSelected,
    this.backgroundColor,
    this.offset,
  }) : assert(icon == null || iconBuilder == null, 'Provide either icon OR iconBuilder, not both.');

  @override
  Widget build(BuildContext context) {
    const lightBG = Color.fromARGB(255, 228, 239, 240);
    const darkBG = Color.fromARGB(255, 34, 52, 65);

    Color dividerColor() {
      if (context.isLight) {
        return ThemeConstants.homeDividerLight.withValues(alpha: 0.3);
      } else {
        return ThemeConstants.homeDividerLight.withValues(alpha: 0.2);
      }
    }

    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: dividerColor(), width: 1.5),
        ),
        popUpAnimationStyle: AnimationStyle(
          curve: Curves.ease,
          duration: const Duration(milliseconds: 300),
        ),
        color: backgroundColor ?? (context.isLight ? lightBG : darkBG),
        offset: offset ?? Offset.zero,

        // 🔹 flexible trigger
        icon: (iconBuilder == null)
            ? (icon ?? const Icon(Icons.more_vert))
            : null,

        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return _buildMenuItems(menuItems, dividerColor());
        },
        child: iconBuilder?.call(context),
      ),
    );
  }

  /// 🔹 Static helper for programmatic usage
  static Future<void> showMenuAt(
    BuildContext context, {
    required Offset position,
    required List<PopupMenuEntry<String>> menuItems,
    void Function(String)? onSelected,
    Color? backgroundColor,
    double? triangleHorizontalOffset,
  }) async {
    const lightBG = Color.fromARGB(255, 228, 239, 240);
    const darkBG = Color.fromARGB(255, 34, 52, 65);

    Color dividerColor() {
      if (context.isLight) {
        return ThemeConstants.homeDividerLight.withValues(alpha: 0.3);
      } else {
        return ThemeConstants.homeDividerLight.withValues(alpha: 0.2);
      }
    }

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: backgroundColor ?? (context.isLight ? lightBG : darkBG),
      shape: TailedRRectBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: dividerColor(), width: 1.5),
        triangleHeight: 8,
        triangleWidth: 14,
        triangleHorizontalOffset: triangleHorizontalOffset ?? 40, // adjust horizontal position
      ),
      items: _buildMenuItems(menuItems, dividerColor()),
    );

    if (selected != null && onSelected != null) {
      onSelected(selected);
    }
  }

  /// 🔹 Shared item builder
  static List<PopupMenuEntry<String>> _buildMenuItems(
    List<PopupMenuEntry<String>> menuItems,
    Color dividerColor,
  ) {
    return menuItems.asMap().entries.expand<PopupMenuEntry<String>>((entry) {
      final index = entry.key;
      final item = entry.value;

      if (index < menuItems.length - 1) {
        return [
          item,
          PopupMenuDivider(
            height: 1,
            thickness: 1.5,
            color: dividerColor,
            indent: 15,
            endIndent: 15,
          ),
        ];
      } else {
        return [item];
      }
    }).toList();
  }
}
