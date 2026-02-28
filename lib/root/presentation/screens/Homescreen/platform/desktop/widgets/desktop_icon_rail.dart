import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/utils/windows_utils.dart';

enum RailTab { chats, search, settings, profile }

class DesktopIconRail extends StatefulWidget {
  final Color headerColor;
  final RailTab selectedTab;
  final ValueChanged<RailTab> onTabSelected;

  /// Optional custom profile widget — e.g. a circular avatar.
  /// Falls back to [Icons.person_outline_rounded] if null.
  final Widget? profileWidget;

  const DesktopIconRail({
    super.key,
    required this.headerColor,
    required this.selectedTab,
    required this.onTabSelected,
    this.profileWidget,
  });

  @override
  State<DesktopIconRail> createState() => _DesktopIconRailState();
}

class _DesktopIconRailState extends State<DesktopIconRail> {
  RailTab? _hoveredTab;

  static const _accent     = Color(0xFF00BCD4);
  static const _barWidth   = 2.5;
  static const _iconSize   = 20.0;
  // Squircle container is smaller than the full rail slot
  static const _squircleSize = 34.0;
  // Outer slot height — provides breathing room / padding around squircle
  static const _slotSize    = 46.0;

  static const _topTabs    = [RailTab.chats, RailTab.search];
  static const _bottomTabs = [RailTab.settings, RailTab.profile];

  IconData _iconFor(RailTab tab) => switch (tab) {
        RailTab.chats    => Icons.chat_bubble_outline_rounded,
        RailTab.search   => Icons.search_rounded,
        RailTab.settings => Icons.settings_outlined,
        RailTab.profile  => Icons.person_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: windowsTitleBarColor,
      builder: (context, value, child) {
        return Container(
          color: widget.headerColor,
          height: double.maxFinite,
          width: WindowsUtils.titlebarHeight,
          child: Column(
            children: [
              // TOP TABS
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    ..._topTabs.map((tab) => _RailIcon(
                          tab: tab,
                          icon: _iconFor(tab),
                          isSelected: widget.selectedTab == tab,
                          isHovered: _hoveredTab == tab,
                          accent: _accent,
                          iconSize: _iconSize,
                          squircleSize: _squircleSize,
                          slotSize: _slotSize,
                          barWidth: _barWidth,
                          customChild: null,
                          onTap: () => widget.onTabSelected(tab),
                          onHover: (v) => setState(
                              () => _hoveredTab = v ? tab : null),
                        )),
                  ],
                ),
              ),

              // BOTTOM TABS
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ..._bottomTabs.map((tab) {
                      final isProfile = tab == RailTab.profile && widget.profileWidget != null;
                      return _RailIcon(
                        tab: tab,
                        icon: _iconFor(tab),
                        isSelected: widget.selectedTab == tab,
                        isHovered: _hoveredTab == tab,
                        accent: _accent,
                        iconSize: _iconSize,
                        squircleSize: _squircleSize,
                        slotSize: _slotSize,
                        barWidth: _barWidth,
                        showSquircleHighlight: !isProfile, // squircle off for profile avatar
                        customChild: isProfile ? widget.profileWidget : null,
                        onTap: () => widget.onTabSelected(tab),
                        onHover: (v) => setState(() => _hoveredTab = v ? tab : null),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Single Rail Icon ─────────────────────────────────────────────────────────

class _RailIcon extends StatefulWidget {
  final RailTab tab;
  final IconData icon;
  final bool isSelected;
  final bool isHovered;
  final Color accent;
  final double iconSize;
  final double squircleSize;
  final double slotSize;
  final double barWidth;
  final bool? showSquircleHighlight;
  final Widget? customChild;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _RailIcon({
    required this.tab,
    required this.icon,
    required this.isSelected,
    required this.isHovered,
    required this.accent,
    required this.iconSize,
    required this.squircleSize,
    required this.slotSize,
    required this.barWidth,
    this.showSquircleHighlight = true,
    required this.customChild,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_RailIcon> createState() => _RailIconState();
}

class _RailIconState extends State<_RailIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _barScale;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _barScale = CurvedAnimation(
      parent: _barController,
      curve: Curves.easeOutBack,
    );
    if (widget.isSelected) _barController.value = 1.0;
  }

  @override
  void didUpdateWidget(_RailIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _barController.forward(from: 0);
    } else if (oldWidget.isSelected && !widget.isSelected) {
      _barController.reverse();
    }
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.isSelected ? widget.accent : ThemeConstants.iconLight;
    final showBg = widget.isSelected || widget.isHovered;
    final bgColor = widget.isSelected
        ? widget.accent.withOpacity(0.14)
        : ThemeConstants.iconLight.withOpacity(0.07);

    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
  width: widget.slotSize,
  height: widget.slotSize,
  child: Stack(
    alignment: Alignment.center,
    children: [
      // HIGHLIGHT BAR — left edge of the slot, outside the squircle
      Positioned(
        left: 0,
        top: widget.slotSize * 0.2,
        child: ScaleTransition(
          scale: _barScale,
          alignment: Alignment.center,
          child: Container(
            width: widget.barWidth,
            height: widget.slotSize * 0.6,
            decoration: BoxDecoration(
              color: widget.accent,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
        ),
      ),

      // SQUIRCLE + ICON — no bar inside anymore
      Padding(
        padding: const EdgeInsets.only(left: 6.0, right: 4),
        child: SizedBox(
          width: widget.squircleSize,
          height: widget.squircleSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: showBg ? ( (widget.showSquircleHighlight ?? true) ? 1.0 : 0.0) : 0.0,
                duration: const Duration(milliseconds: 350),
                child: CustomPaint(
                  size: Size(widget.squircleSize, widget.squircleSize),
                  painter: _SquirclePainter(color: bgColor),
                ),
              ),
              widget.customChild != null
                  ? SizedBox(
                      width: widget.iconSize,
                      height: widget.iconSize,
                      child: ClipOval(child: widget.customChild!),
                    )
                  : AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(color: iconColor),
                      child: Icon(
                        widget.icon,
                        size: widget.iconSize,
                        color: iconColor,
                      ),
                    ),
            ],
          ),
        ),
      ),
    ],
  ),
),
      ),
    );
  }
}

// ─── Squircle Painter ─────────────────────────────────────────────────────────
// Approximates the CSS squircle shape using a superellipse path.
// The CSS version uses overlapping pseudo-elements with asymmetric border
// radii — this approximates it with a cubic bezier superellipse.

class _SquirclePainter extends CustomPainter {
  final Color color;
  const _SquirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = _squirclePath(size);
    canvas.drawPath(path, paint);
  }

  // Superellipse approximation: control point at ~55% of half-side
  // gives the characteristic "squircle" — more curved than a rounded rect,
  // less circular than an ellipse, matching the CSS pseudo-element approach.
  static Path _squirclePath(Size size) {
    final w = size.width;
    final h = size.height;
    // Control point factor — 0.45 gives a tight squircle
    const c = 0.45;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * (0.5 + c), 0, w, h * (0.5 - c), w, h * 0.5)
      ..cubicTo(w, h * (0.5 + c), w * (0.5 + c), h, w * 0.5, h)
      ..cubicTo(w * (0.5 - c), h, 0, h * (0.5 + c), 0, h * 0.5)
      ..cubicTo(0, h * (0.5 - c), w * (0.5 - c), 0, w * 0.5, 0)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(_SquirclePainter old) => old.color != color;
}