import 'package:flutter/material.dart';
import 'dart:math' as math;

class CameraModeSelector extends StatefulWidget {
  final Function(int index)? onModeChanged;
  final int currentIndex; // Add this
  const CameraModeSelector({
    super.key, 
    this.onModeChanged,
    required this.currentIndex, // Required parameter
  });

  @override
  State<CameraModeSelector> createState() => _CameraModeSelectorState();
}

class _CameraModeSelectorState extends State<CameraModeSelector> {
  final FixedExtentScrollController _controller = FixedExtentScrollController();
  
  @override
  void initState() {
    super.initState();
    // Initialize controller to current index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.animateToItem(
        widget.currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didUpdateWidget(CameraModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update scroll position when parent changes the currentIndex
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.animateToItem(
        widget.currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  final modes = ['Photo', 'Video'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 250,
      child: RotatedBox(
        quarterTurns: -1,
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: 70,
          perspective: 0.0025,
          diameterRatio: 1.3,
          physics: const BouncingScrollPhysics().applyTo(const ClampingScrollPhysics()),          
          onSelectedItemChanged: (index) {
            widget.onModeChanged?.call(index);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: modes.length,
            builder: (context, index) {
              final isActive = index == widget.currentIndex; // Use widget.currentIndex
              return RotatedBox(
                quarterTurns: 1,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: isActive ? 18 : 16,
                    fontWeight: isActive ? FontWeight.normal : FontWeight.normal,
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                  child: Center(child: Text(modes[index])),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}