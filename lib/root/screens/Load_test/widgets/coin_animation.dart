import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';

class CoinAnimation extends StatelessWidget {
  final double coinSize; // base size for coins
  final int coinCount;
  final bool allowSpin;

  const CoinAnimation({super.key, this.coinSize = 20, this.coinCount = 14, this.allowSpin = true});

  @override
  Widget build(BuildContext context) {
    // spacing ratios
    final double startSpacingRatio =
        3.0; // how far above previous coin each starts
    final double endSpacingRatio = -0.25; // how close coins land to each other

    final double totalHeight = coinCount * coinSize * startSpacingRatio;

    return SizedBox(
      height: totalHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Stack(
          children: List.generate(coinCount, (index) {
            final double startY = -(250 + index * coinSize * startSpacingRatio);
            final double endY = index * coinSize * endSpacingRatio;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: startY, end: endY),
              duration: Duration(milliseconds: 600 + index * 100),
              curve: Curves.easeInOutQuint,
              builder: (context, value, child) {
                // Compute progress from startY -> endY to drive rotation & scale
                final progress = ((value - startY) / (endY - startY)).clamp( 0.0, 1.0, );

                // Rotation from -90 degrees to 0
                final rotation = (-360 + 360 * progress) * (3.14159265 / 180); // convert to radians

                // Scale from 0 to 1 (or adjust)
                final scale = progress;

                return Transform.translate(
                  offset: Offset(0, value),
                  child: Transform.rotate(
                    angle: allowSpin! ? 0 : rotation,
                    child: child,
                  ),
                );
              },
              child: Image.asset(IconPaths.coin, height: coinSize),
            );
          }),
        ),
      ),
    );
  }
}
