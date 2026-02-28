import 'package:flutter/material.dart';

/// Slides in from the LEFT (reverse of the default Cupertino right-to-left).
/// Use for panels that conceptually "live" to the left — e.g. Profile drawer.
Route<T> slideFromLeftRoute<T>(Widget page) {
  return _SlideRoute<T>(
    page: page,
    beginOffset: const Offset(-1.0, 0.0),
  );
}

/// Standard slide from the RIGHT — same feel as CupertinoPageRoute.
/// Use when you want a consistent native feel without importing Cupertino.
Route<T> slideFromRightRoute<T>(Widget page) {
  return _SlideRoute<T>(
    page: page,
    beginOffset: const Offset(1.0, 0.0),
  );
}

class _SlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset beginOffset;

  _SlideRoute({
    required this.page,
    required this.beginOffset,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // PRIMARY — the incoming page slides in
            final slideIn = Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            ));

            // SECONDARY — the outgoing page slides out slightly in the
            // opposite direction (parallax depth feel, same as Cupertino)
            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: Offset(-beginOffset.dx * 0.25, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            ));

            return SlideTransition(
              position: slideOut,
              child: SlideTransition(
                position: slideIn,
                child: child,
              ),
            );
          },
        );
}