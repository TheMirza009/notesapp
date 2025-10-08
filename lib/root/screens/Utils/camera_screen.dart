import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/controllers/camera_handler.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraHandler _cameraHandler = CameraHandler();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraHandler.initializeCamera();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _cameraHandler.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final Media? media = await _cameraHandler.takePhoto();
    if (media != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryViewWrapper(galleryItems: [media])));
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('✅ Saved: ${media.path}')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _cameraHandler.buildPreview(),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _capturePhoto,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
