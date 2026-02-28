import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/utils/transitions.dart';
import 'package:notesapp/core/utils/windows_utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/presentation/screens/Profile/profile_screen.dart';
import 'package:notesapp/root/presentation/screens/Settings/settings_screen.dart';
import 'package:notesapp/root/presentation/widgets/custom_icon_dialogue.dart';

class TitleBarMenuButton extends ConsumerStatefulWidget {
  const TitleBarMenuButton({super.key});

  @override
  ConsumerState<TitleBarMenuButton> createState() =>
      _TitleBarMenuButtonState();
}

class _TitleBarMenuButtonState extends ConsumerState<TitleBarMenuButton>
    with WidgetsBindingObserver {
  OverlayEntry? _overlayEntry;
  OverlayEntry? _barrierEntry;
  final _buttonKey = GlobalKey();

  bool get _isOpen => _overlayEntry != null;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeOverlays(); // no setState — widget is being disposed
    super.dispose();
  }

  // Catches window resize, minimize, maximize
  @override
  void didChangeMetrics() {
    if (_isOpen) _closeMenu();
  }

  // ─── Overlay management ─────────────────────────────────────────────────────

  /// Removes overlay entries without calling setState — safe to call from dispose.
  void _removeOverlays() {
    _barrierEntry?.remove();
    _overlayEntry?.remove();
    _barrierEntry = null;
    _overlayEntry = null;
  }

  void _closeMenu() {
    _removeOverlays();
    if (mounted) setState(() {});
  }

  // ─── Position ───────────────────────────────────────────────────────────────

  /// Always anchors to the right edge of the screen, top of title bar.
  /// Window-resize safe because it reads MediaQuery at call time via
  /// navigatorKey context.
  Offset _menuPosition() {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return const Offset(0, 40);

    final screenWidth = MediaQuery.of(navContext).size.width;
    final titleBarHeight = AppBar().preferredSize.height;

    // Menu will be right-aligned — position is its LEFT edge.
    // We don't know menu width yet, so we anchor to screen right and let
    // _AnimatedMenu use a fixed width (200) that we also use here.
    const menuWidth = 200.0;
    return Offset(screenWidth - menuWidth - 8, - titleBarHeight + 65);
  }

  // ─── Toggle ─────────────────────────────────────────────────────────────────

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
      return;
    }

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final navContext = navigatorKey.currentContext!;
    final isLight = navContext.isLight;

    const lightBG = Color.fromARGB(255, 228, 239, 240);
    const darkBG = Color.fromARGB(255, 34, 52, 65);
    final bgColor = isLight ? lightBG : darkBG;
    final dividerColor = isLight
        ? ThemeConstants.homeDividerLight.withValues(alpha: 0.3)
        : ThemeConstants.homeDividerLight.withValues(alpha: 0.2);

    final List<PopupMenuEntry<String>> allItems = [
      ...homeScreenOptions,
      PopupMenuDivider(height: 1, thickness: 1.5, color: dividerColor),
      PopupMenuItem(
    value: 'exit',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.power, color: Colors.redAccent),
      text: "Close",
    ),
  ),
    ];

    // BARRIER
    _barrierEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeMenu,
          child: const SizedBox.expand(),
        ),
      ),
    );

    // MENU — position recalculated on every rebuild so it tracks resize
    _overlayEntry = OverlayEntry(
      builder: (_) {
        final pos = _menuPosition();
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: _AnimatedMenu(
            color: bgColor,
            dividerColor: dividerColor,
            items: allItems,
            onSelected: (val) {
              _closeMenu();
              if (val == 'exit') {
                appWindow.close();
                return;
              }
              if (navContext.mounted) {
                _handleContextMenuAction(val, navContext, ref);
              }
            },
          ),
        );
      },
    );

    overlay.insertAll([_barrierEntry!, _overlayEntry!]);
    setState(() {});
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: _buttonKey,
        onTap: _toggleMenu,
        hoverColor: Colors.white.withOpacity(0.1),
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              _isOpen ? Icons.close : Icons.more_vert,
              key: ValueKey(_isOpen),
              color: Colors.white70,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Menu ────────────────────────────────────────────────────────────

class _AnimatedMenu extends StatefulWidget {
  final Color color;
  final Color dividerColor;
  final List<PopupMenuEntry<dynamic>> items;
  final ValueChanged<String> onSelected;

  const _AnimatedMenu({
    required this.color,
    required this.dividerColor,
    required this.items,
    required this.onSelected,
  });

  @override
  State<_AnimatedMenu> createState() => _AnimatedMenuState();
}

class _AnimatedMenuState extends State<_AnimatedMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(_scale),
        alignment: Alignment.topRight, // anchors scale to top-right corner
        child: SizedBox(
          width: 200,
          child: Material(
            color: widget.color,
            borderRadius: BorderRadius.circular(15),
            elevation: 8,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.items.map((item) {
                if (item is PopupMenuDivider) {
                  return Divider(
                    height: 1,
                    thickness: 1.5,
                    color: widget.dividerColor,
                    indent: 15,
                    endIndent: 15,
                  );
                }
                if (item is PopupMenuItem<String>) {
                  return InkWell(
                    onTap: () => widget.onSelected(item.value ?? ''),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: item.child ?? const SizedBox.shrink(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

void _handleContextMenuAction(
  String value,
  BuildContext context,
  WidgetRef ref,
) {
  final chatNotifier = ref.read(chatListProvider.notifier);

  switch (value) {
    case "profile":
      Navigator.of(context, rootNavigator: true).push(
  slideFromLeftRoute(const ProfileScreen()),
);
      break;
    case "settings":
      Navigator.of(context, rootNavigator: true).push(
  slideFromLeftRoute(const SettingsScreen()),
);
      break;
    case "deleteAll":
      showDialog(
        context: context,
        builder: (_) => CustomAlertDialog(
          title: "Delete all notes",
          content: "Are you sure you want to delete all notes?",
          iconColor: Colors.redAccent,
          iconData: Mdi.delete_empty_outline,
          iconSize: 25,
          option: TextButton(
            onPressed: () {
              Navigator.pop(context);
              chatNotifier.clearChats();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      );
      break;
  }
}