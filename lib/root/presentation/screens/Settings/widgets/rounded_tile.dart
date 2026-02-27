import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';

/// A rounded, bordered version of [ListTile].
///
/// Matches the visual style of tiles in [TileContainer.solidBox],
/// but can be used standalone with full [ListTile] flexibility.
class RoundedTile extends StatelessWidget {
  /// ---- Standard ListTile properties ----
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool isThreeLine;
  final bool dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? contentPadding;
  final Color? tileColor;
  final Color? selectedColor;
  final Color? iconColor;
  final Color? textColor;
  final bool enabled;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final MouseCursor? mouseCursor;
  final bool selected;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;

  /// ---- RoundedTile custom additions ----
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? iconPadding;
  final EdgeInsetsGeometry? margins;
  final double? borderThickness;

  const RoundedTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense = false,
    this.visualDensity,
    this.shape,
    this.contentPadding,
    this.tileColor,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.mouseCursor,
    this.selected = false,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,

    /// custom
    this.borderRadius = 15,
    this.backgroundColor,
    this.borderColor,
    this.iconPadding,
    this.borderThickness,
    this.margins,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLight;

    const lightBG = Color.fromARGB(255, 228, 239, 240);
    const darkBG = Color.fromARGB(255, 34, 52, 65);

    final resolvedBG =
        backgroundColor ?? tileColor ?? (isLight ? lightBG : darkBG);
    final resolvedBorder =
        borderColor ??
        (isLight
            ? ThemeConstants.homeDividerLight.withValues(alpha: 0.3)
            : ThemeConstants.homeDividerLight.withValues(alpha: 0.2));

    return Padding(
      padding: margins ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Ink(
            decoration: ShapeDecoration(
              color: resolvedBG,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                side: BorderSide(
                  color: resolvedBorder,
                  width: borderThickness ?? 1.5,
                ),
              ),
            ),
            child: ListTile(
              // disable its own tap so InkWell handles it
              onTap: null,
              leading: leading != null 
                ? Padding( 
                    padding: iconPadding ?? const EdgeInsets.all(8.0), 
                    child: leading) 
                : null,
              title: title,
              subtitle: subtitle,
              trailing: trailing,
              isThreeLine: isThreeLine,
              dense: dense,
              visualDensity: visualDensity,
              shape: shape,
              contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              selectedColor: selectedColor,
              iconColor: iconColor,
              textColor: textColor,
              enabled: enabled,
              selected: selected,
              focusNode: focusNode,
              autofocus: autofocus,
            ),
          ),
        ),
      ),
    );
  }
}
