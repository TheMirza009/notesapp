import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';

class CoinAnimation extends StatelessWidget {
  const CoinAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 800,
      child: ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: - (index * 61.5).toDouble(), end: (300 - ((index + 1) * 61.5)).toDouble()),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.easeInOutQuint,
            builder: (context, value, child) {
              return Transform.translate(offset: Offset(0, value), child: child);
            },
            child: Image.asset(IconPaths.coin, height: 50,),
          );
        },
      ),
    );
  }
}
