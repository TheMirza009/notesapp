import 'package:flutter/material.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/video_handler.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/presentation/widgets/photo_view/media_preview_screen.dart';
class MediaPreviewModal extends StatefulWidget {
  final Media originalMedia;

  const MediaPreviewModal({
    super.key,
    required this.originalMedia,
  });

  @override
  State<MediaPreviewModal> createState() => _MediaPreviewModalState();
}

class _MediaPreviewModalState extends State<MediaPreviewModal> with SingleTickerProviderStateMixin {  // ✅ Add this mixin
  late Media _currentMedia;
  Media? _croppedMedia;
  bool _animationComplete = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentMedia = widget.originalMedia;
    
    // ✅ Create controller with proper TickerProvider (this)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Start animation and listen for completion
    _animationController.forward();
    _animationController.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _animationComplete = true);
    }
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_onAnimationStatus);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onCropped(Media media) async {
    final newMedia = await MediaHandler.cropAndSavePhoto(
      _currentMedia.path!,
      isProfilePicture: false,
    );
    if (newMedia != null) {
      setState(() {
      _croppedMedia = newMedia;
      _currentMedia = newMedia;
    });
    }
  }

  void _onClose() {
    if (_croppedMedia != null && _croppedMedia != widget.originalMedia) {
      MediaHandler.deleteMedia(_croppedMedia!);
    } else {
      MediaHandler.deleteMedia(_currentMedia);
    }

    // Dispose Video
    if (widget.originalMedia.isVideo) {
      VideoHandler.disposeAll();
    }
    Navigator.of(context).pop(null);  // ✅ Simplified - no rootNavigator needed
  }

  void _onSend() {
    // Dispose Video
    if (widget.originalMedia.isVideo) {
      VideoHandler.disposeAll();
    }

    if (_croppedMedia != null && _croppedMedia != widget.originalMedia) {
      Navigator.of(context).pop(_croppedMedia);
    } else {
      Navigator.of(context).pop(_currentMedia);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - 
          (kisWindows ? 0 : (kToolbarHeight / 1.5)),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: MediaPreviewScreen(
          media: _currentMedia,
          animationComplete: _animationComplete,
          onSend: _onSend,  // ✅ Use method reference
          onCancelled: _onClose,  // ✅ Use method reference
          onCropped: (media) => _onCropped(media),
        ),
      ),
    );
  }
}