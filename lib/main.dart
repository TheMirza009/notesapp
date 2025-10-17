import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/share_intent_handler.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/screens/Homescreen/homescreen.dart';

bool kisWindows = Platform.isWindows;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarDatabase.init();
  await IsarDatabase.loadUserData();
  // Lock orientation in portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
   ProviderScope(
    child: const MyApp()),
  );
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
    WidgetsFlutterBinding.ensureInitialized(); 
    ShareIntentHandler.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ThemeConstants.screenWidth = MediaQuery.sizeOf(context).width;
    ThemeConstants.screenHeight = MediaQuery.sizeOf(context).height;
  }

  @override
  void dispose() {
    ShareIntentHandler.dispose();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = ref.watch(themeNotifierProvider);

    return MaterialApp(
      // showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
      title: 'NotesApp',
      theme: themeProvider,
      scaffoldMessengerKey: scaffoldMessengerkey,
      navigatorKey: navigatorKey,
      home: const Homescreen(),
    );
  }
}
