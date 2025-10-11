import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/screens/Settings/widgets/bordered_container.dart';

class EmergingCircle extends StatefulWidget {
  final bool open;
  final Widget child;
  final double maxRadius;
  const EmergingCircle({super.key, required this.open, required this.child, required this.maxRadius });

  @override
  State<EmergingCircle> createState() => _EmergingCircleState();
}

class _EmergingCircleState extends State<EmergingCircle> {

  // static const double contentWidth = 150;
  // static const double contentHeight = 100;

  // double get _maxRadius =>
  //     math.sqrt(math.pow(contentWidth / 2, 2) + math.pow(contentHeight / 2, 2));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0,
            end: widget.open ? widget.maxRadius : 0,
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutQuint,
          builder: (context, radius, child) {
            return ClipPath(
              clipper: _SimpleCircleClipper(radius, alignment: Alignment(0.7, 1)),
              child: child,
            );
          },
          child: widget.child, // AttachmentBoard(isOpen: widget.open,),
          // BorderedContainer(
          //   margins: const EdgeInsets.all(50),
          //   color: ThemeConstants.darkAppbar,
          //   borderColor: ThemeConstants.darkIconbackground,
          //   height: contentHeight,
          //   width: contentWidth,
          //   child: const Center(child: Text("CONTENT")),
          // ),
        ),
        // const SizedBox(height: 20),
        // BorderedContainer(
        //   margins: const EdgeInsets.all(15),
        //   contentPadding:
        //       const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        //   color: ThemeConstants.darkIconBorder,
        //   borderColor: ThemeConstants.darkIconbackground,
        //   onTap: () => setState(() => open = !open),
        //   child: SizedBox(
        //     width: 100,
        //     child: Center(child: Text(open ? "Hide" : "Reveal")),
        //   ),
        // ),
      ],
    );
  }
}

class _SimpleCircleClipper extends CustomClipper<Path> {
  final double radius;
  final Alignment? alignment;

  _SimpleCircleClipper(this.radius, {this.alignment = Alignment.center});

  @override
  Path getClip(Size size) {
    final path = Path();

    // Convert alignment (-1..1 range) to actual pixel coordinates
    final center = Offset(
      size.width  - 60,// * (alignment!.x + 1) / 2,
      size.height * (alignment!.y + 1) / 2,
    );

    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(_SimpleCircleClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.alignment != alignment;
}
