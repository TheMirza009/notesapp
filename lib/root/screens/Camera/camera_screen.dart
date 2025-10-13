import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/icon_park_outline.dart';
import 'package:iconify_flutter/icons/icon_park_solid.dart';
import 'package:iconify_flutter/icons/icon_park_twotone.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/camera_handler.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/screens/Camera/camera_grid_overlay.dart';
import 'package:notesapp/root/screens/Camera/camera_mode_selector.dart';
import 'package:notesapp/root/screens/Camera/camera_tool_panel.dart';
import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraHandler _cameraHandler = CameraHandler();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([CameraDescription? description]) async {
    await _cameraHandler.initializeCamera(
      preferredLens: description?.lensDirection ?? CameraLensDirection.back,
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _cameraHandler.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final controller = _cameraHandler.controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraHandler.dispose(); // Proper disposal
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(controller.description);
    }
  }


  Future<void> _capturePhoto() async {
    final Media? media = await _cameraHandler.takePhoto();
    // _cameraHandler.dispose();
    if (media != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GalleryViewWrapper(
            galleryItems: [media], isCamera: true,
            ),
        ),
      );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('✅ Saved: ${media.path}')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.clear, color: Colors.white70,),
        ), // Icon(Icons.arrow_back_ios_new_rounded)),
        title: SizedBox(height: 40, child: CameraModeSelector()),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ValueListenableBuilder(
                valueListenable: _cameraHandler.rebuildNotifier,
                builder: (_, __, ___) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: _cameraHandler.buildPreview(),
                  );
                },
              ),
          // Container(
          //   color: ThemeConstants.darkIconBorder,
          //   height: 600,
          //   width: double.maxFinite,
          // ),
          ValueListenableBuilder(
            valueListenable: _cameraHandler.showGrid,
            builder: (context, value, child) {
              return AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
                opacity: value ? 1.0 : 0,
                child: CameraGridOverlay());
            },
          ),
          CameraSidePanel(cameraHandler: _cameraHandler),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                shape: CircleBorder(),
                backgroundColor: Colors.transparent,
                onPressed: _capturePhoto,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 3, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
