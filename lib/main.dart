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
import 'package:notesapp/windows_titlebar.dart';

bool kisWindows = Platform.isWindows;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows setup
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
  IsarDatabase.loadUserData();  // Heavy data load AFTER app starts
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
      ? (context, child) {
        return Column(
          children: [const WindowsTitleBar(), Expanded(child: child!)],
        );
      } : null,
    );
  }
}