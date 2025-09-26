import 'package:flutter/cupertino.dart';

class RebuildCounter extends StatelessWidget {
  final String name;
  final Widget child;

  const RebuildCounter({
    super.key,
    required this.name,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    print("🔄 $name rebuilt");
    return child;
  }
}
