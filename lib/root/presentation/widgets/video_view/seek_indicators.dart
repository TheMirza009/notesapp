import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:svg_flutter/svg.dart';

class SeekIndicator extends StatefulWidget {
  final VoidCallback onDoubleTap;
  final VoidCallback? onTap;
  final bool forward;
  
  const SeekIndicator({super.key, required this.onDoubleTap, this.onTap, this.forward = false});

  @override
  State<SeekIndicator> createState() => _SeekIndicatorState();
}

class _SeekIndicatorState extends State<SeekIndicator> {
  bool _showRewind = false;
  bool _shouldSlide = false;

  void _handleDoubleTap() {
    widget.onDoubleTap();
    
    setState(() {
      _showRewind = true;
      _shouldSlide = true;
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showRewind = false);
        // Keep slide state true briefly for exit animation
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _shouldSlide = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _handleDoubleTap,
      child: Container(
        color: Colors.transparent,
        width: 120,
        height: 300,
        child: AnimatedOpacity(
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 150),
          opacity: _showRewind ? 1.0 : 0.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.flip(
                flipX: widget.forward ? false : true,
                child: Transform.scale(
                  scale: 4,
                  child: SvgPicture.string(
                    IconPaths.sideOverlay,
                    height: context.screenHeight,
                    color: Colors.black38,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!widget.forward)
                  AnimatedSlide(
                    curve: Curves.easeInOutQuint,
                    duration: const Duration(milliseconds: 200),
                    offset: Offset(_shouldSlide ? -1.0 : 0, 0), // Changed from -3.5 to 3.5
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.forward ? "+5" : "-5s",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.forward)
                  AnimatedSlide(
                    curve: Curves.easeInOutQuint,
                    duration: const Duration(milliseconds: 200),
                    offset: Offset(_shouldSlide ? 1.0 : 0, 0), // Changed from -3.5 to 3.5
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Usage in your main build:
// RewindIndicator(
//   onDoubleTap: () => videoController.seekTo(videoController.position - Duration(seconds: 5)),
// )