import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';

/// A reusable [HeroWrapper] that manages both:
/// - the source (thumbnail in widget tree)
/// - the destination (expanded fullscreen overlay)
///
/// ✅ No redundancy: you provide `tag`, `thumbnail`, and `expandedChild` once.
/// ✅ Tap on thumbnail automatically pushes fullscreen overlay.
/// ✅ Optional `topWidget` and `bottomWidget` fade in after hero animates.
/// ✅ `.push` still exists if you want to trigger manually without thumbnail.
///
/// Example:
/// ```dart
/// HeroWrapper(
///   tag: "profile-avatar",
///   thumbnail: Image.asset("assets/avatar.png", height: 80),
///   expandedChild: Image.asset("assets/avatar.png", fit: BoxFit.contain),
///   bottomWidget: TextButton(onPressed: () {}, child: Text("Close")),
/// )
/// ```
class HeroWrapper extends StatelessWidget {
  /// Unique tag used for Hero transition.
  final String tag;

  /// Small version shown in the widget tree (thumbnail).
  final Widget defaultChild;

  /// Large version shown in fullscreen overlay.
  final Widget expandedChild;

  /// Optional widget above expanded child (fades in).
  final Widget? topWidget;

  /// Optional widget below expanded child (fades in).
  final Widget? bottomWidget;

  /// Transition configs.
  final Duration pushDuration;
  final Duration popDuration;
  final Curve pushCurve;
  final Curve popCurve;
  final Alignment alignment;

  final void Function()? onHeroTapped;
  final void Function()? onBackgroundTapped;

  const HeroWrapper({
    super.key,
    required this.tag,
    required this.defaultChild,
    required this.expandedChild,
    this.topWidget,
    this.bottomWidget,
    this.pushDuration = const Duration(milliseconds: 400),
    this.popDuration = const Duration(milliseconds: 300),
    this.pushCurve = Curves.easeOut,
    this.popCurve = Curves.easeInBack,
    this.alignment = Alignment.center,
    this.onHeroTapped,
    this.onBackgroundTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onHeroTapped?.call();
        HeroWrapper.push(
          context,
          tag: tag,
          expandedChild: expandedChild,
          topWidget: topWidget,
          bottomWidget: bottomWidget,
          pushDuration: pushDuration,
          popDuration: popDuration,
          pushCurve: pushCurve,
          popCurve: popCurve,
          alignment: alignment,
        );
      },
      child: Hero(
        tag: tag,
        child: defaultChild,
      ),
    );
  }

  /// Internal fullscreen page
  static Widget _destination(
    BuildContext context, {
    required String tag,
    required Widget expandedChild,
    Widget? topWidget,
    Widget? bottomWidget,
    Duration pushDuration = const Duration(milliseconds: 400),
    Duration popDuration = const Duration(milliseconds: 300),
    Curve pushCurve = Curves.easeOut,
    Curve popCurve = Curves.easeInBack,
    Alignment alignment = Alignment.center,
    void Function()? onBackgroundTapped,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(systemNavigationBarColor: Colors.black),
      child: GestureDetector(
        onTap: onBackgroundTapped ?? () => Navigator.of(context).pop(),
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (topWidget != null)
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: ModalRoute.of(context)!.animation!,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                    ),
                    child: topWidget,
                  ),
                Hero(
                  tag: tag,
                  flightShuttleBuilder: (
                    flightContext,
                    animation,
                    flightDirection,
                    fromHeroContext,
                    toHeroContext,
                  ) {
                    final curvedAnimation = CurvedAnimation(
                      parent: animation,
                      curve: flightDirection == HeroFlightDirection.push
                          ? pushCurve
                          : popCurve,
                    );
                    return AnimatedBuilder(
                      animation: curvedAnimation,
                      builder: (context, child) => child!,
                      child: toHeroContext.widget,
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Align(
                      alignment: alignment,
                      child: expandedChild,
                    ),
                  ),
                ),
                if (bottomWidget != null)
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: ModalRoute.of(context)!.animation!,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                    ),
                    child: bottomWidget,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pushes fullscreen overlay manually (if you don’t want to use the widget thumbnail).
  static Future<T?> push<T>(
  BuildContext context, {
  required String tag,
  required Widget expandedChild,
  Widget? topWidget,
  Widget? bottomWidget,
  Duration pushDuration = const Duration(milliseconds: 400),
  Duration popDuration = const Duration(milliseconds: 300),
  Curve pushCurve = Curves.easeOut,
  Curve popCurve = Curves.easeInBack,
  Alignment alignment = Alignment.center,
}) async {
  
  // 👇 Push fullscreen
  final result = await Navigator.of(context).push<T>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      transitionDuration: pushDuration,
      reverseTransitionDuration: popDuration,
      pageBuilder: (_, __, ___) {
        return _destination(
          context,
          tag: tag,
          expandedChild: expandedChild,
          topWidget: topWidget,
          bottomWidget: bottomWidget,
          pushDuration: pushDuration,
          popDuration: popDuration,
          pushCurve: pushCurve,
          popCurve: popCurve,
          alignment: alignment,
        );
      },
    ),
  );

  return result;
}

}
