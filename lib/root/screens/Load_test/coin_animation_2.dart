import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';

class CoinAnimation2 extends StatelessWidget {
  final double coinSize;
  final int coinCount;
  final VoidCallback? onComplete;

  const CoinAnimation2({
    super.key,
    this.coinSize = 20,
    this.coinCount = 14,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final double startSpacingRatio = 3.0;
    final double endSpacingRatio = -0.25;

    final double totalHeight = coinCount * coinSize * startSpacingRatio;

    return SizedBox(
      height: totalHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Stack(
          children: List.generate(coinCount, (index) {
            final double startY = -(250 + index * coinSize * startSpacingRatio);
            final double endY = index * coinSize * endSpacingRatio;

            final bool isLastCoin = index == coinCount - 1;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: startY, end: endY),
              duration: Duration(milliseconds: 600 + index * 100),
              curve: Curves.easeInOutQuint,
              onEnd: isLastCoin ? onComplete : null,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: child,
                );
              },
              child: Image.asset(
                IconPaths.coin,
                height: coinSize,
              ),
            );
          }),
        ),
      ),
    );
  }
}
