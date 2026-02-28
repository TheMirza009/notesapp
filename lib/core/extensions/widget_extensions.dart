// keyboard_extensions.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension KeyboardShortcutsX on Widget {
  /// Add keyboard shortcuts with a clean builder syntax
  /// ______________________
  ///
  /// ### MAPS
  /// onEscape: ESC
  /// onEnter: Enter
  /// onSave: CTRL + S
  /// onNew: CTRL + N
  /// onPrint: CTRL + P
  /// onRefresh: F5
  Widget withKeys({
    VoidCallback? onEscape,
    VoidCallback? onEnter,
    VoidCallback? onNextLine,
    VoidCallback? onSpace,
    VoidCallback? onSave,
    VoidCallback? onNew,
    VoidCallback? onPrint,
    VoidCallback? onRefresh,
    VoidCallback? onQuestionMark,
    Map<LogicalKeySet, VoidCallback>? custom,
    bool autofocus = true,
  }) {
    final shortcuts = <LogicalKeySet, VoidCallback>{};
    
    // Add pre-defined shortcuts
    if (onEscape != null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.escape)] = onEscape;
    }
    if (onEnter != null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.enter)] = onEnter;
    }
    if (onNextLine != null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter)] = onNextLine;
    }
    if (onSpace != null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.space)] = onSpace;
    }
    if (onSave != null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS)] = onSave;
    }
    if (onNew != null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN)] = onNew;
    }
    if (onPrint != null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP)] = onPrint;
    }
    if (onRefresh != null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.f5)] = onRefresh;
    }
    if (onQuestionMark != null) {
      shortcuts[LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.slash)] = onQuestionMark;
    }
    
    // Add custom shortcuts
    custom?.forEach((key, callback) {
      shortcuts[key] = callback;
    });

    return _KeyboardShortcutWrapper(
      child: this,
      shortcuts: shortcuts,
      autofocus: autofocus,
    );
  }
}

class _KeyboardShortcutWrapper extends StatelessWidget {
  final Widget child;
  final Map<LogicalKeySet, VoidCallback> shortcuts;
  final bool autofocus;

  const _KeyboardShortcutWrapper({
    required this.child,
    required this.shortcuts,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    if (shortcuts.isEmpty) return child;

    final shortcutMap = shortcuts.map((key, callback) => 
      MapEntry(key, _CallbackIntent(callback))
    );

    return Shortcuts(
      shortcuts: shortcutMap,
      child: Actions(
        actions: {
          _CallbackIntent: CallbackAction<_CallbackIntent>(
            onInvoke: (_CallbackIntent intent) {
              intent.callback();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: autofocus,
          child: child,
        ),
      ),
    );
  }
}

class _CallbackIntent extends Intent {
  final VoidCallback callback;
  const _CallbackIntent(this.callback);
}