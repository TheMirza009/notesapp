import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';

class CustomContextMenu extends StatelessWidget {
  final Icon icon;
  final List<PopupMenuEntry<String>> menuItems;
  final void Function(String)? onSelected;
  final Color? backgroundColor;

  const CustomContextMenu({
    super.key,
    required this.icon,
    required this.menuItems,
    this.onSelected, /// Does not work without menuItems
    this.backgroundColor,
  });

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: backgroundColor ?? (context.isLight ? lightBG : darkBG), // ThemeConstants.homeSearchbarLight
        icon: icon,
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return menuItems.asMap().entries.expand<PopupMenuEntry<String>>((
            entry,
          ) {
            final index = entry.key;
            final item = entry.value;

            if (index < menuItems.length - 1) {
              return [item, PopupMenuDivider(height: 1, thickness: 1.5, color: dividerColor(),)]; // Return the item followed by a divider
            } else {
              return [item]; // Last item, no divider
            }
          }).toList();
        },
      ),
    );
  }
}
