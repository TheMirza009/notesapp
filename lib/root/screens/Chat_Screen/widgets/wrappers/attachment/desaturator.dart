import 'package:flutter/material.dart';

/// A compositing-safe desaturation & fade effect.
/// No Stack, no layout distortion, works perfectly inside Material widgets.
class Desaturator extends StatelessWidget {
  final Widget child;

  /// Whether to apply the visual effect.
  final bool desaturate;

  /// 0.0 = full color, 1.0 = full grayscale.
  final double intensity;

  /// Opacity when desaturating (0–1).
  final double opacity;

  /// Optional tint color (blue-grey by default).
  final Color tint;

  const Desaturator({
    super.key,
    required this.child,
    this.desaturate = true,
    this.intensity = 0.5,
    this.opacity = 0.6,
    this.tint = const Color(0xFF90A4AE),
  });

  @override
  Widget build(BuildContext context) {
    if (!desaturate) return child;

    final i = intensity.clamp(0.0, 1.0);
    final o = opacity.clamp(0.0, 1.0);

    // If visually neutral, just return child.
    if (i == 0.0 && o == 1.0) return child;

    Widget current = child;

    // Apply desaturation using ColorFiltered — safe, layout-friendly.
    if (i > 0) {
      current = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: current,
      );
    }

    // Apply a subtle tint using ShaderMask instead of Stack.
    if (i > 0) {
      current = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Colors.white,
            tint.withOpacity(i * 0.25),
          ],
        ).createShader(bounds),
        blendMode: BlendMode.modulate,
        child: current,
      );
    }

    // Apply opacity last for control over visibility.
    if (o < 1.0) {
      current = Opacity(opacity: o, child: current);
    }

    return current;
  }
}
