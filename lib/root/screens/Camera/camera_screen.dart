import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/camera_handler.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/screens/Camera/camera_grid_overlay.dart';
import 'package:notesapp/root/screens/Camera/camera_mode_selector.dart';
import 'package:notesapp/root/screens/Camera/camera_tool_panel.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';
import 'package:notesapp/root/widgets/photo_view/media_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraHandler _cameraHandler = CameraHandler();
  bool _loading = true;
  bool isRecording = false;
  final ValueNotifier<bool> videoMode = ValueNotifier<bool>(false);
  final ValueNotifier<int> currentModeIndex = ValueNotifier<int>(0);
  
  // Pinch to zoom variables
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  double _availableZoom = 1.0;
  
  // Tap to focus variables
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  bool _isFocusing = false;

  // Recording Handler
  final ValueNotifier<Duration> _recordingTimeNotifier = ValueNotifier<Duration>(Duration.zero);
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;

  void _startRecording() {
  _cameraHandler.startVideoRecording();
  setState(() {
    isRecording = true;
    _recordingStartTime = DateTime.now();
  });
  
  // Start recording timer
  _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
    if (_recordingStartTime != null) {
      _recordingTimeNotifier.value = DateTime.now().difference(_recordingStartTime!);
    }
  });
}

void _stopRecording() {
  _recordingTimer?.cancel();
  _recordingTimer = null;
  setState(() {
    isRecording = false;
    _recordingTimeNotifier.value = Duration.zero;
    _recordingStartTime = null;
  });
  _capture();
}

  @override
  void initState() {
    super.initState();
    _initCamera();
    videoMode.addListener(() {
      currentModeIndex.value = videoMode.value ? 1 : 0;
    });
  }

  Future<void> _initCamera([CameraDescription? description]) async {
    await _cameraHandler.initializeCamera(
      preferredLens: description?.lensDirection ?? CameraLensDirection.back,
      enableAudio: true,
    );
    if (mounted) {
      setState(() => _loading = false);
      _getAvailableZoom();
    }
  }

  void _getAvailableZoom() async {
    if (_cameraHandler.controller != null) {
      _availableZoom = await _cameraHandler.controller!.getMaxZoomLevel();
      debugPrint('📷 Available zoom: $_availableZoom');
    }
  }

  // Handle pinch to zoom
  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_cameraHandler.controller == null || !_cameraHandler.isInitialized) return;
    
    final newScale = (_baseScale * details.scale).clamp(1.0, _availableZoom);
    
    setState(() {
      _currentScale = newScale;
    });
    
    _cameraHandler.controller!.setZoomLevel(_currentScale);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _baseScale = _currentScale;
  }

  void _resetZoom() {
    if (_cameraHandler.controller != null && _cameraHandler.isInitialized) {
      setState(() {
        _currentScale = 1.0;
        _baseScale = 1.0;
      });
      _cameraHandler.controller!.setZoomLevel(1.0);
    }
  }

  // Handle tap to focus
  void _handleTapDown(TapDownDetails details) {
    if (_cameraHandler.controller == null || !_cameraHandler.isInitialized) return;
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    
    // Calculate relative position (0.0 to 1.0)
    final double x = localPosition.dx / box.size.width;
    final double y = localPosition.dy / box.size.height;
    
    setState(() {
      _focusPoint = localPosition;
      _showFocusCircle = true;
      _isFocusing = true;
    });
    
    // Set focus and exposure point
    _cameraHandler.controller!.setFocusPoint(Offset(x, y));
    _cameraHandler.controller!.setExposurePoint(Offset(x, y));
    
    // Hide focus circle after 2 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showFocusCircle = false;
          _isFocusing = false;
        });
      }
    });
  }

  // Swipe gesture variables
double _startDX = 0.0;
bool _isSwiping = false;

void _handleHorizontalDragStart(DragStartDetails details) {
  _startDX = details.globalPosition.dx;
  _isSwiping = true;
}

void _handleHorizontalDragUpdate(DragUpdateDetails details) {
  if (!_isSwiping) return;
  
  final double currentDX = details.globalPosition.dx;
  final double delta = currentDX - _startDX;
  
  // You can add visual feedback during swipe if needed
  // For example, change opacity or show a hint
}

void _handleHorizontalDragEnd(DragEndDetails details) {
  if (!_isSwiping) return;
  
  final double screenWidth = MediaQuery.of(context).size.width;
  final double swipeThreshold = screenWidth * 0.15; // 15% of screen width
  
  // Calculate swipe velocity and distance
  final double velocity = details.primaryVelocity ?? 0;
  final bool isFastSwipe = velocity.abs() > 500; // Fast swipe threshold
  
  if (velocity < -swipeThreshold || (velocity < 0 && isFastSwipe)) {
    // Swipe left - switch to Video mode
    _switchToVideoMode();
  } else if (velocity > swipeThreshold || (velocity > 0 && isFastSwipe)) {
    // Swipe right - switch to Photo mode
    _switchToPhotoMode();
  }
  
  _isSwiping = false;
}

void _switchToVideoMode() {
    if (videoMode.value == false) {
      videoMode.value = true;
      currentModeIndex.value = 1;
      debugPrint('📹 Switched to Video mode');
    }
  }

  void _switchToPhotoMode() {
    if (videoMode.value == true) {
      videoMode.value = false;
      currentModeIndex.value = 0;
      debugPrint('📸 Switched to Photo mode');
    }
  }
  
  // Update your existing mode change handler
  void _handleModeChange(int index) {
    if (index == 1) {
      videoMode.value = true;
      currentModeIndex.value = 1;
    } else {
      videoMode.value = false;
      currentModeIndex.value = 0;
    }
  }

  @override
void dispose() {
  _recordingTimer?.cancel();
  _recordingTimeNotifier.dispose();
  _cameraHandler.dispose();
  super.dispose();
}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final controller = _cameraHandler.controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraHandler.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(controller.description);
    }
  }

  Future<void> _capture() async {
  final Media? media = videoMode.value == false 
    ? await _cameraHandler.takePhoto() 
    : await _cameraHandler.stopVideoRecording();
    
  if (media != null && mounted) {
    Media currentMedia = media;
    Media? croppedMedia;
    
    // Start auto-dispose timer (15 seconds)
    Timer? disposeTimer;
    disposeTimer = Timer(Duration(seconds: 15), () {
      if (mounted) {
        _cameraHandler.dispose();
        debugPrint('📷 Camera disposed after 15 seconds in preview');
      }
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Consumer(
                builder: (context, ref, child) {
                  return MediaPreviewScreen(
                    fromCamera: true,
                    media: currentMedia,
                    onCancelled: () {
                      disposeTimer?.cancel();
                      // Clean up cropped media if user cancels after cropping
                      if (croppedMedia != null && croppedMedia != media) {
                        MediaHandler.deleteMedia(croppedMedia!);
                      }
                      Navigator.pop(context);
                    },
                    onSend: () {
                      disposeTimer?.cancel();
                      openPreviewAndRemoveCamera(context, currentMedia, ref);
                    },
                    onCropped: (imageToCrop) async {
                      // Dispose camera immediately when cropping starts
                      _cameraHandler.dispose();
                      disposeTimer?.cancel();
                      
                      final newMedia = await MediaHandler.cropAndSavePhoto(
                        imageToCrop.path!,
                        isProfilePicture: false,
                      );
                      if (newMedia != null) {
                        croppedMedia = newMedia;
                        setState(() {
                          currentMedia = newMedia;
                        });
                      }
                    },
                  );
                }
              );
            },
          );
        }
      ),
    ).then((_) {
      // Clean up timer when screen is popped
      disposeTimer?.cancel();
      _reinitializeCamera();
    });
  }
}

Future<void> _reinitializeCamera() async {
  if (mounted && !_cameraHandler.isInitialized) {
    try {
      await _cameraHandler.initializeCamera(
        enableAudio: true, 
        preferredLens: CameraLensDirection.back
      );
      debugPrint('📷 Camera re-initialized after preview');
    } catch (e) {
      debugPrint('❌ Failed to re-initialize camera: $e');
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      /// APPBAR SECTION
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.clear, color: Colors.white70,),
        ),

        // Mode selection
        title: ValueListenableBuilder<int>(
  valueListenable: currentModeIndex,
  builder: (context, modeIndex, child) {
    return SizedBox(
      height: 40,
      child: CameraModeSelector(
        currentIndex: modeIndex, // Pass the current index
        onModeChanged: _handleModeChange,
      ),
    );
  },
),
        centerTitle: true,

        // Recording time
       actions: [
  AnimatedOpacity(
    opacity: isRecording ? 1.0 : 0.0,
    duration: Duration(milliseconds: 200),
    child: Container(
      margin: EdgeInsets.only(right: 10),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Red recording dot
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          // Recording time
          ValueListenableBuilder<Duration>(
            valueListenable: _recordingTimeNotifier,
            builder: (context, duration, child) {
              return Text(
                Utils.formatDuration(duration),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    ),
  ),
],
      ),

      // Main Body
      body: Stack(
        children: [

          // Main Camera display texture
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ValueListenableBuilder(
                valueListenable: _cameraHandler.rebuildNotifier,
                builder: (_, __, ___) {
                  return GestureDetector(
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    onScaleEnd: _handleScaleEnd,
                    onDoubleTap: _resetZoom,
                    onTapDown: _handleTapDown, // Add tap to focus
                    onHorizontalDragStart: _handleHorizontalDragStart,
                    onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                    onHorizontalDragEnd: _handleHorizontalDragEnd,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: _cameraHandler.buildPreview(),
                    ),
                  );
                },
              ),
          
          // Focus circle
          Positioned(
            left: _focusPoint?.dx != null ? _focusPoint!.dx - 40 : 0,
            top: _focusPoint?.dy != null ? _focusPoint!.dy - 40 : 0,
            child: _FocusCircle(
              isFocusing: _isFocusing,
              showCircle: _showFocusCircle,
            ),
          ),

          // Zoom indicator
          if (_currentScale > 1.0)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentScale.toStringAsFixed(1)}x',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Grid display
          ValueListenableBuilder(
            valueListenable: _cameraHandler.showGrid,
            builder: (context, value, child) {
              return AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
                opacity: value ? 1.0 : 0,
                child: CameraGridOverlay(),
              );
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
                onPressed: () {
  if (videoMode.value == true) {
    if (!isRecording) {
      _startRecording();
    } else {
      _stopRecording();
    }
  } else {
    _capture();
  }
},
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 3, color: Colors.white),
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: videoMode,
                      builder: (context, value, child) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 250),
                          curve: Curves.easeInOutQuint,
                          margin: EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          height: value ? (isRecording ? 25 : 40) : 0,
                          width: value ? (isRecording ? 25 : 40) : 0,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Focus Circle Widget
class _FocusCircle extends StatelessWidget {
  final bool isFocusing;
  final bool showCircle;

  const _FocusCircle({required this.isFocusing, required this.showCircle});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: showCircle ? 1.0 : 0.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: showCircle ? 1.0 : 1.2,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 2.0,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}