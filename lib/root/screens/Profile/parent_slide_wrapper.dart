import 'package:flutter/material.dart';

class ParentSlideWrapper extends StatelessWidget {
  final bool trigger;
  final Widget overlay;
  final Widget child;

  const ParentSlideWrapper({
    super.key,
    required this.trigger,
    required this.overlay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 350);

    return Stack(
      children: [
        // Child that shifts slightly right
        TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(
            begin: Offset.zero,
            end: trigger ? const Offset(0.5, 0) : Offset.zero,
          ),
          duration: duration,
          curve: Curves.linearToEaseOut, // trigger ? Curves.linearToEaseOut : Curves.easeInToLinear,
          builder: (_, offset, childWidget) {
            return FractionalTranslation(
              translation: offset,
              child: childWidget,
            );
          },
          child: child,
        ),

        // Scrim
        // IgnorePointer(
        //   ignoring: true,
        //   child: TweenAnimationBuilder<double>(
        //     tween: Tween<double>(
        //       begin: 0.0,
        //       end: trigger ? 0.3 : 0.0,
        //     ),
        //     duration: duration,
        //     curve: trigger ? Curves.linearToEaseOut : Curves.easeInToLinear,
        //     builder: (_, opacity, __) {
        //       return Container(
        //         color: Colors.black.withOpacity(opacity),
        //       );
        //     },
        //   ),
        // ),

        // Overlay sliding from left
        TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: trigger ? Offset.zero : const Offset(-1, 0),
          ),
          duration: Duration(milliseconds: 400),
          curve: trigger ? Curves.linearToEaseOut : Curves.easeInToLinear,
          builder: (_, offset, childWidget) {
            return FractionalTranslation(
              translation: offset,
              child: childWidget,
            );
          },
          child: overlay,
        ),
      ],
    );
  }
}
