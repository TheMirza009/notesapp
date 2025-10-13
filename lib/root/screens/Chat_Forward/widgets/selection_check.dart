import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';

class SelectionCheck extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const SelectionCheck({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic, // smoother than easeOutBack
      child: IconButton(
        onPressed: onTap,
        iconSize: 28,
        splashRadius: 22,
        padding: EdgeInsets.zero,
        icon: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.circle_outlined,
              size: 26,
              color: Colors.grey.shade400,
            ),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutExpo, // smoother "reveal" feel
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: Icon(
                  Icons.check_circle,
                  size: 26,
                  color: const Color.fromARGB(255, 38, 174, 253),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
