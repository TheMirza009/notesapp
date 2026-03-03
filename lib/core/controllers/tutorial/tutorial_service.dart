import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:svg_flutter/svg.dart';

// ─── Tutorial Registry ────────────────────────────────────────────────────────
// Add new tutorial keys here as the app grows.
// Each key maps to a unique SharedPreferences flag and a TutorialConfig.

enum TutorialKey {
  homeScreen,
  chatScreen,
  searchScreen,
  settingsScreen,
  profileScreen,
}

// ─── Tutorial Config ──────────────────────────────────────────────────────────
// Describes what a tutorial looks like and where its hint points.

class TutorialConfig {
  // For screen modification
  final TutorialKey? screenKey;

  /// Main instruction text shown in the hint bubble
  final String message;

  /// Optional secondary hint (e.g. "Tap anywhere to dismiss")
  final String? dismissHint;

  /// Where the arrow/bubble should be anchored on screen
  final TutorialAnchor anchor;

  const TutorialConfig({
    this.screenKey,
    required this.message,
    required this.anchor,
    this.dismissHint = 'Tap anywhere to dismiss',
  });
}

enum TutorialAnchor {
  bottomRight,  // FAB area
  bottomLeft,
  bottomCenter,
  topRight,
  topLeft,
  topCenter,
  center,
}

// ─── Tutorial Definitions ─────────────────────────────────────────────────────
// Add or edit tutorials here. One entry per TutorialKey.

const Map<TutorialKey, TutorialConfig> _tutorials = {
  TutorialKey.homeScreen: TutorialConfig(
    screenKey: TutorialKey.homeScreen,
    message: 'Tap here to create\na new chat',
    anchor: TutorialAnchor.bottomRight,
    dismissHint: 'Tap anywhere to dismiss',
  ),
  TutorialKey.chatScreen: TutorialConfig(
    message: 'Tap the mic or attachment\nto add media to your note',
    anchor: TutorialAnchor.bottomRight,
    dismissHint: 'Tap anywhere to dismiss',
  ),
  TutorialKey.searchScreen: TutorialConfig(
    message: 'Search across all your notes\nand messages at once',
    anchor: TutorialAnchor.topCenter,
    dismissHint: 'Tap anywhere to dismiss',
  ),
  TutorialKey.settingsScreen: TutorialConfig(
    message: 'Customize your experience\nfrom here',
    anchor: TutorialAnchor.center,
    dismissHint: 'Tap anywhere to dismiss',
  ),
  TutorialKey.profileScreen: TutorialConfig(
    message: 'Set your profile photo\nand display name here',
    anchor: TutorialAnchor.topCenter,
    dismissHint: 'Tap anywhere to dismiss',
  ),
};

// ─── TutorialService ──────────────────────────────────────────────────────────

class TutorialService {
  TutorialService._(); // prevent instantiation — static only

  static const _prefix = 'tutorial_seen_';
  static OverlayEntry? _activeEntry;

  // ─── Public screen-specific methods ─────────────────────────────────────
  // Call these from initState. Each checks the flag and shows if unseen.

  static Future<void> showHomeScreenHelp() =>
      _showIfUnseen(TutorialKey.homeScreen);

  static Future<void> showChatScreenHelp() =>
      _showIfUnseen(TutorialKey.chatScreen);

  static Future<void> showSearchScreenHelp() =>
      _showIfUnseen(TutorialKey.searchScreen);

  static Future<void> showSettingsScreenHelp() =>
      _showIfUnseen(TutorialKey.settingsScreen);

  static Future<void> showProfileScreenHelp() =>
      _showIfUnseen(TutorialKey.profileScreen);

  // ─── Force show — ignores the seen flag (e.g. from a "Show tips" button) ─

  static Future<void> forceShow(TutorialKey key) => _show(key);

  // ─── Reset a specific tutorial (user can re-trigger it) ──────────────────

  static Future<void> reset(TutorialKey key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey(key));
  }

  // ─── Reset all tutorials ──────────────────────────────────────────────────

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in TutorialKey.values) {
      await prefs.remove(_prefKey(key));
    }
    debugPrint("📃 All tutorials reset");
  }

  // ─── Check if a tutorial has been seen ───────────────────────────────────

  static Future<bool> hasSeen(TutorialKey key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey(key)) ?? false;
  }

  // ─── Dismiss active overlay imperatively (e.g. on screen dispose) ────────

  static void dismiss() {
    _activeEntry?.remove();
    _activeEntry = null;
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  static Future<void> _showIfUnseen(TutorialKey key) async {
    final seen = await hasSeen(key);
    if (seen) return;
    await _show(key);
  }

  static Future<void> _show(TutorialKey key) async {
    final config = _tutorials[key];
    assert(config != null, 'No TutorialConfig found for $key — add it to _tutorials');
    if (config == null) return;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // Dismiss any existing tutorial before showing a new one
    dismiss();

    _activeEntry = OverlayEntry(
      builder: (_) => _TutorialOverlay(
        config: config,
        onDismiss: () async {
          dismiss();
          await _markSeen(key);
        },
      ),
    );

    // Wait for first frame so overlay is mounted and sized correctly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeEntry != null) {
        Future.delayed(Duration(seconds: 2), () {
          overlay.insert(_activeEntry!);
        });
      }
    });
  }

  static Future<void> _markSeen(TutorialKey key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(key), true);
  }

  static String _prefKey(TutorialKey key) => '$_prefix${key.name}';
}

// ─── Tutorial Overlay Widget ──────────────────────────────────────────────────

class _TutorialOverlay extends StatefulWidget {
  final TutorialConfig config;
  final VoidCallback onDismiss;

  const _TutorialOverlay({
    required this.config,
    required this.onDismiss,
  });

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // catches taps everywhere
        onTap: _handleDismiss,
        child: SizedBox.expand(
          child: CustomPaint(
            painter: CutoutOverlayPainter(
    cutoutRect: _anchorToRect(widget.config.anchor, MediaQuery.sizeOf(context)),
    radius: 35, // match roughly the FAB size
  ),
            child: SafeArea(
              child: Stack(
                children: [
                  // HINT BUBBLE + ARROW — positioned by anchor
                  _buildHintAtAnchor(widget.config),

                  // DISMISS HINT — always at top center
                  if (widget.config.dismissHint != null)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Text(
                        widget.config.dismissHint!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color:  Color.fromARGB(145, 159, 194, 211),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.7,
                          fontFamily: 'Poppins',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintAtAnchor(TutorialConfig config) {
    final bubble = _HintBubble(screenKey: config.screenKey, message: config.message, anchor: config.anchor);
    final bool isHomeScreen = config.screenKey == TutorialKey.homeScreen;

    switch (config.anchor) {
      case TutorialAnchor.bottomRight:
        return Positioned(
          bottom: isHomeScreen ? 100 : 90,
          right: isHomeScreen ? 20 : 20,
          left: isHomeScreen ? 20 : null,
          child: bubble,
        );
      case TutorialAnchor.bottomLeft:
        return Positioned(
          bottom: 90,
          left: 20,
          child: bubble,
        );
      case TutorialAnchor.bottomCenter:
        return Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          child: Center(child: bubble),
        );
      case TutorialAnchor.topRight:
        return Positioned(
          top: 80,
          right: 20,
          child: bubble,
        );
      case TutorialAnchor.topLeft:
        return Positioned(
          top: 80,
          left: 20,
          child: bubble,
        );
      case TutorialAnchor.topCenter:
        return Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(child: bubble),
        );
      case TutorialAnchor.center:
        return Positioned.fill(
          child: Center(child: bubble),
        );
    }
  }
}

// ─── Hint Bubble ──────────────────────────────────────────────────────────────

class _HintBubble extends StatelessWidget {
  final String message;
  final TutorialAnchor anchor;
  final TutorialKey? screenKey;

  const _HintBubble({
    required this.message,
    required this.anchor,
    this.screenKey,
  });

  bool get _arrowBelow =>
      anchor == TutorialAnchor.bottomRight ||
      anchor == TutorialAnchor.bottomLeft ||
      anchor == TutorialAnchor.bottomCenter;

  bool get _isHomeScreen => screenKey == TutorialKey.homeScreen;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ThemeConstants.darkAppbar, // Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
        boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.35),
    blurRadius: 20,
    spreadRadius: 2,
    offset: const Offset(4, 6),
  ),
],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
        ),
      ),
    );

    final twistingArrow = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Transform.rotate(
        angle: 0.15,
        child: SvgPicture.asset(
          height: 140,
          IconPaths.twistingArrow2,
          colorFilter: ColorFilter.mode(
            ThemeConstants.sacredSeed,
            BlendMode.srcIn,
          ),
        ),
      ),
    );

    final arrow = Icon(
      _arrowBelow
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      color: Colors.white,
      size: 22,
    );

    // Homescreen — bubble left, arrow right, side by side
    if (_isHomeScreen) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final screenHeight = MediaQuery.sizeOf(context).height;
  final arrowHeight = (screenHeight * 0.18).clamp(80.0, 140.0);

  return SizedBox(
    width: screenWidth,
    height: screenHeight * 0.35,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // Bubble — left anchored
        Positioned(
          left: context.screenWidth * 0.15,
          bottom: screenHeight * 0.2,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.55),
            child: bubble,
          ),
        ),
        // Arrow — right anchored, height scales with screen
        Positioned(
          right: 20,
          bottom: 0,
          child: Transform.rotate(
            angle: 0.15,
            child: SvgPicture.asset(
              IconPaths.twistingArrow2,
              height: arrowHeight, // ← scales, clamped between 80-140
              colorFilter: ColorFilter.mode(
                ThemeConstants.sacredSeed,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

    // Default — stacked vertically
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _arrowBelow
          ? [bubble, const SizedBox(height: 6), twistingArrow]
          : [arrow, const SizedBox(height: 6), bubble],
    );
  }
}

class CutoutOverlayPainter extends CustomPainter {
  final Rect cutoutRect;
  final double radius;

  const CutoutOverlayPainter({
    required this.cutoutRect,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.4);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(
        center: cutoutRect.center,
        radius: radius,
      ))
      ..fillType = PathFillType.evenOdd; // ← this is the key, cuts the hole

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CutoutOverlayPainter old) =>
      old.cutoutRect != cutoutRect || old.radius != radius;
}

Rect _anchorToRect(TutorialAnchor anchor, Size screen) {
  const fabSize = 56.0;
  const fabMargin = 16.0;

  switch (anchor) {
    case TutorialAnchor.bottomRight:
  return Rect.fromCenter(
    center: Offset(
      screen.width - fabMargin - fabSize / 2 - 5,  // ← -5 left
      screen.height - fabMargin - fabSize / 2 - 3, // ← -5 up
    ),
    width: fabSize,
    height: fabSize,
  );
    case TutorialAnchor.bottomLeft:
      return Rect.fromCenter(
        center: Offset(fabMargin + fabSize / 2, screen.height - fabMargin - fabSize / 2),
        width: fabSize, height: fabSize,
      );
    case TutorialAnchor.bottomCenter:
      return Rect.fromCenter(
        center: Offset(screen.width / 2, screen.height - fabMargin - fabSize / 2),
        width: fabSize, height: fabSize,
      );
    case TutorialAnchor.topRight:
      return Rect.fromCenter(
        center: Offset(screen.width - fabMargin - fabSize / 2, fabMargin + fabSize / 2),
        width: fabSize, height: fabSize,
      );
    case TutorialAnchor.topLeft:
      return Rect.fromCenter(
        center: Offset(fabMargin + fabSize / 2, fabMargin + fabSize / 2),
        width: fabSize, height: fabSize,
      );
    case TutorialAnchor.topCenter:
      return Rect.fromCenter(
        center: Offset(screen.width / 2, fabMargin + fabSize / 2),
        width: fabSize, height: fabSize,
      );
    case TutorialAnchor.center:
      return Rect.fromCenter(
        center: Offset(screen.width / 2, screen.height / 2),
        width: fabSize, height: fabSize,
      );
  }
}