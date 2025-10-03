import 'package:flutter/material.dart';

class ReverseCupertinoPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ReverseCupertinoPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          opaque: false, // 👈 important: let the old route stay visible
          barrierColor: Colors.transparent, // no auto scrim
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Incoming page slides in from left
            final inTween = Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            // Scrim fades in
            final opacityTween = Tween<double>(
              begin: 0.0,
              end: 0.3,
            ).chain(CurveTween(curve: Curves.easeIn));

            return Stack(
              children: [
                // Scrim overlay (sits above previous route, below incoming)
                FadeTransition(
                  opacity: animation.drive(opacityTween),
                  child: Container(color: Colors.black),
                ),

                // Incoming page
                SlideTransition(
                  position: animation.drive(inTween),
                  child: child,
                ),
              ],
            );
          },
        );
}
