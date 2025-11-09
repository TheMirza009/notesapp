import 'package:flutter/material.dart';
import 'dart:math' as math;

class CameraModeSelector extends StatefulWidget {
  final Function(int index)? onModeChanged;
  const CameraModeSelector({super.key, this.onModeChanged});

  @override
  State<CameraModeSelector> createState() => _CameraModeSelectorState();
}

class _CameraModeSelectorState extends State<CameraModeSelector> {
  final FixedExtentScrollController _controller = FixedExtentScrollController();
  int _currentIndex = 0;

  final modes = ['Photo', 'Video'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 250,
      child: RotatedBox(
        quarterTurns: -1, // Rotate the wheel horizontally
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: 70,
          perspective: 0.0025, // Depth for 3D effect
          diameterRatio: 1.3, // Adjust curve depth
          physics: const BouncingScrollPhysics().applyTo(const ClampingScrollPhysics()),          
          onSelectedItemChanged: (index) {
            widget.onModeChanged?.call(index);
            setState(() => _currentIndex = index);
            },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: modes.length,
            builder: (context, index) {
              final isActive = index == _currentIndex;
              return RotatedBox(
                quarterTurns: 1, // Rotate text back upright
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: isActive ? 18 : 16,
                    fontWeight: isActive ? FontWeight.normal : FontWeight.normal,
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                    // color: isActive ? (index == 0 ? Colors.white : Colors.white.withOpacity(0.5)) : Colors.white.withOpacity(0.5),
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
