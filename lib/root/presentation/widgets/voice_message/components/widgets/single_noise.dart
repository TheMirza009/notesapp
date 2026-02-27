import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:notesapp/root/presentation/widgets/voice_message/components/helpers/utils.dart';

/// A widget that represents a single noise.
///
/// This widget is used to display a single noise in the UI.
/// It is a stateful widget, meaning it can change its state over time.
class SingleNoise extends StatefulWidget {
  const SingleNoise({
    super.key,
    required this.activeSliderColor,
    required this.height,
  });

  /// The color of the active slider.
  final Color activeSliderColor;

  /// The height of the noise.
  final double height;
  @override
  State<SingleNoise> createState() => _SingleNoiseState();
}

class _SingleNoiseState extends State<SingleNoise> {
  /// Get screen media.
  final double height = 5.74.width() * math.Random().nextDouble() + .26.width();

  @override

  /// Build the widget.
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: .2.width()),
      width: .56.width(),
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1000),
        color: widget.activeSliderColor,
      ),
    );
  }
}
