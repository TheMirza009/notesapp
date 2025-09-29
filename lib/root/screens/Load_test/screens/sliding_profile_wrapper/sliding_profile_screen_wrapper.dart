import 'package:flutter/material.dart';
import 'package:notesapp/root/screens/Load_test/screens/sliding_profile_wrapper/sliding_profile_controller.dart';

/// A wrapper that provides:
/// - A single [Scaffold] with a single [AppBar].
/// - A floating widget that starts in the AppBar leading position,
///   but expands & animates independently.
/// - A parent body (home content) and a profile body (overlay).
///
/// Example:
/// ```dart
/// SlidingProfileScreenWrapper(
///   title: Text("Home"),
///   parentBody: HomeBody(),
///   profileBody: ProfileBody(),
///   floatingWidget: Image.asset("assets/avatar.png"),
/// )
/// ```
class SlidingProfileScreenWrapper extends StatefulWidget {
  /// Title for the app bar.
  final Widget? appBarTitle;

  /// Body shown by default (home content).
  final Widget parentBody;

  /// Body shown when profile is expanded.
  final Widget profileBody;

  /// Floating widget (e.g., avatar).
  final Widget floatingWidget;

  /// AppBar actions (always shown).
  final List<Widget>? appBarActions;

  final Color? appBarBackgroundColor;
  final double? appBarElevation;

  /// Leading widget shown when profile is expanded.
  final Widget? expandedLeading;

  /// Hidden (collapsed) scale of the floating widget.
  final double defaultScale;

  /// Expanded scale of the floating widget.
  final double expandedScale;

  /// Duration of animations.
  final Duration duration;

  /// Curve for animations.
  final Curve curve;

  /// External controller for programmatic open/close.
  final SlidingProfileController? controller;

  final bool? slideFromRight;

  const SlidingProfileScreenWrapper({
    super.key,
    required this.parentBody,
    required this.profileBody,
    required this.floatingWidget,
    this.expandedLeading,
    this.defaultScale = 1.0,
    this.expandedScale = 6.0,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOutQuint,
    this.controller, 
    this.appBarTitle,
    this.appBarActions,
    this.appBarBackgroundColor, 
    this.appBarElevation,
    this.slideFromRight = true,
  });

  @override
  State<SlidingProfileScreenWrapper> createState() =>  _SlidingProfileScreenWrapperState();
}


class _SlidingProfileScreenWrapperState
    extends State<SlidingProfileScreenWrapper> {
  late SlidingProfileController _controller;

  bool _showProfileWidget = false; // controls mounting

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SlidingProfileController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller.isOpen) {
      // ensure widget is mounted before opening animation
      setState(() => _showProfileWidget = true);
    } else {
      // delay unmount until animation completes
      Future.delayed(widget.duration, () {
        if (mounted && !_controller.isOpen) {
          setState(() => _showProfileWidget = false);
        }
      });
    }
    setState(() {}); // still rebuild for animation values
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    const double avatarSize = 40.0;

    final double topWhenHidden =
        statusBarHeight + (kToolbarHeight - avatarSize) / 2;
    const double leftWhenHidden = 16.0;

    final double topWhenShown = (screenSize.height / 5.5) - avatarSize / 2;
    final double leftWhenShown = (screenSize.width / 2) - avatarSize / 2;

    final bool isOpen = _controller.isOpen;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          /// Parent (home) body with embedded AppBar
          IgnorePointer(
            ignoring: isOpen,
            child: Column(
              children: [
                PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: SafeArea(
                    bottom: false,
                    child: AppBar(
                      automaticallyImplyLeading: false,
                      title: widget.appBarTitle,
                      backgroundColor: widget.appBarBackgroundColor ?? Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
                      elevation: widget.appBarElevation ?? 2,
                      leading: const SizedBox(width: 40),
                      actions: isOpen
                          ? [
                              widget.expandedLeading ??
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _controller.close,
                                  ),
                            ]
                          : widget.appBarActions,
                    ),
                  ),
                ),
                Expanded(child: widget.parentBody),
              ],
            ),
          ),

          /// Profile body (slides in fully now)
          // if (_showProfileWidget)
          AnimatedSlide(
            offset: isOpen ? Offset.zero : Offset(widget.slideFromRight! ? 1 : -1, 0),
            duration: widget.duration,
            curve: widget.curve,
            child: IgnorePointer(
              ignoring: !isOpen,
              child: widget.profileBody,
            ),
          ),

          /// Floating widget (avatar)
          AnimatedPositioned(
            duration: widget.duration,
            curve: widget.curve,
            top: isOpen ? topWhenShown : topWhenHidden,
            left: isOpen ? leftWhenShown : leftWhenHidden,
            child: AnimatedScale(
              scale: isOpen ? widget.expandedScale : widget.defaultScale,
              duration: widget.duration,
              curve: widget.curve,
              child: GestureDetector(
                onTap: _controller.open,
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: widget.floatingWidget,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
