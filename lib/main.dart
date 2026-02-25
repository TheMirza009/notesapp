import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/share_intent_handler.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/screens/Chat_screen/chat_screen.dart';
import 'package:notesapp/root/screens/Homescreen/homescreen.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

bool kisWindows = Platform.isWindows;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows window setup
  if (Platform.isWindows) {
    doWhenWindowReady(() {
      const initialSize = Size(400, 800);
      appWindow.minSize = const Size(350, 600);
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.title = "NotesApp";
      appWindow.show();
    });
  }

  // IMPORTANT: Don’t block first frame
  await IsarDatabase.init();

  if (!Platform.isWindows) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const ProviderScope(child: MyApp()));

  // Load heavy data AFTER app starts
  IsarDatabase.loadUserData();
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {

  @override
  void initState() {
    super.initState();

    // Delay platform channel init slightly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShareIntentHandler.initialize();
    });
  }

  @override
  void dispose() {
    ShareIntentHandler.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final themeProvider = ref.watch(themeNotifierProvider);

  if (!Platform.isWindows) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NotesApp',
      theme: themeProvider,
      scaffoldMessengerKey: scaffoldMessengerkey,
      navigatorKey: navigatorKey,
      home: const Homescreen(),
    );
  }

  return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'NotesApp',
  theme: themeProvider,
  scaffoldMessengerKey: scaffoldMessengerkey,
  navigatorKey: navigatorKey,
  home: const Homescreen(),
  builder: kisWindows
      ? (context, child) => Column(
            children: [
              const WindowsTitleBar(),
              Expanded(child: child!),
            ],
          )
      : null,
);
}
}

class WindowsShell extends StatelessWidget {
  const WindowsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          const WindowsTitleBar(), // 32px tall, sits on top
          const Expanded(child: Homescreen()),
        ],
      
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WINDOWS TITLE BAR
// ══════════════════════════════════════════════════════════════════════════════

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