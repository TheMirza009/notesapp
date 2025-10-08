import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';

class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IconData themeIcon =  context.isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined;
    return IconButton(
      icon: context.isLight ? Icon(themeIcon) : vectorBuild(IconPaths.sun),
      onPressed: () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
    );
  }
}
