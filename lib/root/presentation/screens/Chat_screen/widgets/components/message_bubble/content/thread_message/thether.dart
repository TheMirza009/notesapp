
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// TETHER & RIDGE ELEMENTS (visual connectors between bubbles)
/// ---------------------------------------------------------------------------
const EdgeInsets threadPadding = EdgeInsets.only(left: 5, top: 3, bottom: 3);

class Ridge extends StatelessWidget {
  const Ridge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: threadPadding,
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.3),
      ),
    );
  }
}

class Thether extends StatelessWidget {
  final bool? top;
  const Thether({super.key, this.top = false});

  @override
  Widget build(BuildContext context) {
    const double threadLength = 20;
    return Stack(
      alignment: top == true ? Alignment.topCenter : Alignment.bottomCenter,
      children: [
        const Ridge(),
        Transform.translate(
          offset:
              Offset(0, top == true ? -threadLength + 7 : threadLength - 7),
          child: Container(
            margin: threadPadding,
            height: threadLength,
            width: 3.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ],
    );
  }
}