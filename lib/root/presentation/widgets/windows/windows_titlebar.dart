import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/utils/windows_utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/presentation/screens/Settings/settings_screen.dart';
import 'package:notesapp/root/presentation/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/presentation/widgets/custom_icon_dialogue.dart';
import 'package:notesapp/root/presentation/widgets/windows/titlebar_popup.dart';

class WindowsTitleBar extends StatelessWidget {
  const WindowsTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isWide = context.screenWidth >= 600;
    final double iconSize = isWide ? 45 : 20;

    return SizedBox(
      height: isWide ? WindowsUtils.titlebarHeight : null,
      child: ValueListenableBuilder<Color?>(
        valueListenable: windowsTitleBarColor,
        builder: (context, color, child) {
          final fallbackColor = context.isLight
              ? ThemeConstants.hometoolbarLight
              : const Color(0xFF1d2b36);
          final resolvedColor =
              isWide ? fallbackColor : (color ?? fallbackColor);

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
              // APP ICON
              Padding(
                padding: isWide
                    ? const EdgeInsets.fromLTRB(2, 8, 6, 6)
                    : const EdgeInsets.symmetric(horizontal: 8.0),
                child: Image.asset(
                  'assets/launcher/windows_logo_04.png',
                  width: iconSize,
                  height: iconSize,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.note_alt_outlined,
                    size: iconSize,
                    color: Colors.white70,
                  ),
                ),
              ),

              if (isWide)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    child: const Text(
                      "NotesApp",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // DRAGGABLE AREA
              Expanded(child: MoveWindow()),

              // OVERFLOW MENU — only shown in mid-width range
              // Uses GestureDetector + showMenuAt to avoid the Overlay
              // lookup failure that PopupMenuButton causes when placed
              // inside WindowTitleBarBox (above the MaterialApp overlay).
              if (context.screenWidth >= 600 && context.screenWidth <= 900)
              TitleBarMenuButton(),
              // WINDOW CONTROLS
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