import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/controllers/camera_handler.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';

class CameraSidePanel extends StatefulWidget {
  final CameraHandler cameraHandler;
  const CameraSidePanel({super.key, required this.cameraHandler});

  @override
  State<CameraSidePanel> createState() => _CameraSidePanelState();
}

class _CameraSidePanelState extends State<CameraSidePanel>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late final AnimationController _controller;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offset = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // hidden offscreen
      end: Offset.zero, // fully visible
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 👇 Listen to camera updates, so flash button updates dynamically
    widget.cameraHandler.controller?.addListener(_cameraListener);
  }

  void _cameraListener() {
    if (mounted) setState(() {});
  }

  void _togglePanel([bool? show]) {
    final shouldShow = show ?? !_isVisible;
    setState(() => _isVisible = shouldShow);
    shouldShow ? _controller.forward() : _controller.reverse();
  }

  // 🔦 Computed getter for flash state
  bool get flashOn => widget.cameraHandler.flashMode == FlashMode.torch;

  Future<void> _toggleFlash() async {
    final cam = widget.cameraHandler.controller;
    if (cam == null || !widget.cameraHandler.isInitialized) return;

    final newMode = flashOn ? FlashMode.off : FlashMode.torch;
    await cam.setFlashMode(newMode);
    setState(() {}); // reflect new flash mode
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(1, -0.20),
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200 && !_isVisible) {
              _togglePanel(true);
            } else if (details.primaryVelocity! > 200 && _isVisible) {
              _togglePanel(false);
            }
          },
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              // 🧱 Sliding control panel
              SlideTransition(
                position: _offset,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ⚡ Flash toggle
                          IconButton(
                            onPressed: _toggleFlash,
                            icon: Icon(
                              flashOn
                                  ? CupertinoIcons.bolt_slash_fill
                                  : CupertinoIcons.bolt,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 🖼 Aspect ratio (placeholder action)
                          IconButton(
                            onPressed: () {
                              // TODO: hook up to aspect ratio setter
                              debugPrint('Aspect ratio toggle pressed');
                            },
                            icon: const Icon(
                              Icons.aspect_ratio_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 🧭 Grid overlay toggle (placeholder)
                          IconButton(
                            onPressed: () {
                              // TODO: handle grid visibility toggle
                              debugPrint('Grid toggle pressed');
                            },
                            icon: const Icon(
                              Icons.grid_on,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 🔁 Switch camera
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              await widget.cameraHandler.switchCamera();
                            },
                            icon: SizedBox(
                              width: 26,
                              height: 26,
                              child: vectorBuild(
                                IconPaths.cameraSwitch,
                                color: Colors.white,
                                scale: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    // ➡️ Toggle button to close panel
                    IconButton(
                      onPressed: _togglePanel,
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 22),
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),

              // ⬅️ Chevron when hidden
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isVisible ? 0.0 : 1.0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: _isVisible ? const Offset(-0.3, 0) : Offset.zero,
                  curve: Curves.easeOut,
                  child: IconButton(
                    onPressed: _togglePanel,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.cameraHandler.controller?.removeListener(_cameraListener);
    _controller.dispose();
    super.dispose();
  }
}
