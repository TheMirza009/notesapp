import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:svg_flutter/svg.dart';

class NothingToSee extends StatelessWidget {
  final String? path;
  const NothingToSee({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: SvgPicture.asset(
            path ?? IconPaths.nothing,
            colorFilter: ColorFilter.mode(Colors.blueGrey, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
