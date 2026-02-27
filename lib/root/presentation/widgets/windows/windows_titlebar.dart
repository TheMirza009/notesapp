
// ══════════════════════════════════════════════════════════════════════════════
// WINDOWS TITLE BAR
// ══════════════════════════════════════════════════════════════════════════════

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';

class WindowsTitleBar extends StatelessWidget {
  const WindowsTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ValueListenableBuilder<Color?>(
  valueListenable: windowsTitleBarColor,
  builder: (context, color, child) {
    final resolvedColor = color ??
        (context.isLight
            ? ThemeConstants.hometoolbarLight
            : const Color(0xFF1d2b36));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(color: resolvedColor),
      child: child!,
    );
  },
        child: WindowTitleBarBox(
          child: Row(
            children: [
              // App Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Image.asset(
                  'assets/launcher/windows_logo_04.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.note_alt_outlined,
                      size: 20,
                      color: Colors.white70,
                    );
                  },
                ),
              ),
              // Draggable area
              Expanded(child: MoveWindow()),
              // Window controls
              const WindowButtons(),
            ],
          ),
        ),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
      iconNormal: Colors.white70,
      iconMouseOver: Colors.white,
      mouseOver: Colors.white.withOpacity(0.1),
      mouseDown: Colors.white.withOpacity(0.2),
    );

    final closeButtonColors = WindowButtonColors(
      iconNormal: Colors.white70,
      iconMouseOver: Colors.white,
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}