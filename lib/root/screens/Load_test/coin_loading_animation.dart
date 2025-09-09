import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';

/// A looping falling coin animation.
///
/// - Coins fall from top to bottom, then reset and fall again.
/// - Each coin has a staggered delay, so the animation looks continuous.
/// - Controlled externally by [AnimationController] to start/stop looping.
class CoinWaterfall extends StatelessWidget {
  final double coinSize;
  final int coinCount;
  final Animation<double> animation; // progress from 0 → 1 repeatedly

  const CoinWaterfall({
    super.key,
    required this.coinSize,
    required this.coinCount,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double containerHeight = constraints.maxHeight;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: List.generate(coinCount, (index) {
                // Each coin falls with a slight phase shift
                final double phase = (index / coinCount);
                final double progress =
                    ((animation.value + phase) % 1.0); // loop 0→1

                // Vertical position: 0 at top → containerHeight at bottom
                final double y = lerpDouble(-coinSize, containerHeight, progress)!;

                // Horizontal "wobble" to make it look organic
                final double x = sin(progress * pi * 2 + index) * coinSize * 0.3;

                return Positioned(
                  top: y,
                  left: (constraints.maxWidth / 2) + x - coinSize / 2,
                  child: Image.asset(
                    IconPaths.coin,
                    height: coinSize,
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}
