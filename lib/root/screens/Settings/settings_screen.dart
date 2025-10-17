import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/message_bubble.dart';
import 'package:notesapp/root/screens/Settings/notifier/settings_notifier.dart';
import 'package:notesapp/root/screens/Settings/widgets/emerging_circle.dart';
import 'package:notesapp/root/screens/Settings/widgets/rounded_tile.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/theme_switch.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            RoundedTile(
              margins: EdgeInsets.only(bottom: 10),
              leading: Icon(context.isLight ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              title: Text("Theme"),
              onTap: () {
                CustomContextMenu.showMenuAt(
                context,
                position:  Offset(context.screenWidth - 20, 120), // Offset(200, 120),
                menuItems: themeOptions,
                triangleHorizontalOffset: 180,
                onSelected: (val) => handleThemeOptions(ref, val),
              );
              },
            ),
            RoundedTile(
              margins: EdgeInsets.only(bottom: 10),
              leading: Icon(Icons.chat),
              title: Text("Bubble Style"),
              onTap: () {
                CustomContextMenu.showMenuAt(
                context,
                triangleHorizontalOffset: 180,
                position: Offset(context.screenWidth - 20, 190), // Offset(200, 120),
                menuItems: bubbleStyleOptions,
                onSelected: (val) => handleBubbleStyle(ref, val),
              );
              },
            ),
            // EmergingCircle()
          ],
        ),
      ),
    );
  }
}

void handleThemeOptions(WidgetRef ref, String value) {
  switch (value) {
    case 'light':
      ref.read(themeNotifierProvider.notifier).setLightTheme();
      break;
    case 'dark':
      ref.read(themeNotifierProvider.notifier).setDarkTheme();
      break;
    case 'systemDefault':
      ref.read(themeNotifierProvider.notifier).setSystemDefaultTheme();
      break;
    default:
      ref.read(themeNotifierProvider.notifier).setSystemDefaultTheme();
  }
}

void handleBubbleStyle(WidgetRef ref, String value) {
  switch (value) {
    case 'opaque':
      ref.read(settingsController.notifier).setBubbleStyle(BubbleStyle.opaque);
      break;
    case 'glass':
      ref.read(settingsController.notifier).setBubbleStyle(BubbleStyle.glass);
      break;
    default:
      ref.read(settingsController.notifier).setBubbleStyle(BubbleStyle.opaque);
  }
}