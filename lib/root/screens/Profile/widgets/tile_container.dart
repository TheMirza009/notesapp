import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';

/// A reusable, styled container for displaying option tiles.
///
/// Supports two rendering modes:
/// - [TileContainer.softTiles] : each tile has its own container with radius
/// - [TileContainer.solidBox]  : single box wraps all tiles with dividers
///
/// Provides a clean, scalable, declarative API.
class TileContainer extends StatelessWidget {
  /// List of tile definitions
  final List<TileItem> items;

  /// Layout mode (soft vs solid)
  final TileContainerStyle style;

  /// Optional max width (defaults to screen width - 70)
  final double? width;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom divider color
  final Color? dividerColor;

  /// Corner radius for tiles/box
  final double borderRadius;

  /// Padding inside each tile
  final EdgeInsetsGeometry tilePadding;
  final EdgeInsetsGeometry? iconPadding;

  /// Whether to insert dividers between items
  final bool showDividers;

  final double? borderThickness;
  final double? dividerThickness;

  const TileContainer({
    super.key,
    required this.items,
    this.style = TileContainerStyle.solidBox,
    this.width,
    this.backgroundColor,
    this.dividerColor,
    this.borderRadius = 15,
    this.tilePadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.showDividers = true,
    this.borderThickness,
    this.dividerThickness,
    this.iconPadding,
  });

  /// Soft variant: rounded tiles separated by small gaps
  factory TileContainer.softTiles({
    Key? key,
    required List<TileItem> items,
    double? width,
    double? borderRadius,
    Color? backgroundColor,
    Color? dividerColor,
    EdgeInsetsGeometry? tilePadding,
    EdgeInsetsGeometry? iconPadding,
  }) {
    return TileContainer(
      key: key,
      items: items,
      style: TileContainerStyle.softTiles,
      width: width,
      backgroundColor: backgroundColor,
      dividerColor: dividerColor,
      borderRadius: borderRadius ?? 25,
      showDividers: false,
      tilePadding: tilePadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      iconPadding: iconPadding,
    );
  }

  /// Solid variant: one box with dividers
  factory TileContainer.solidBox({
    Key? key,
    required List<TileItem> items,
    double? width,
    double? borderRadius,
    Color? backgroundColor,
    Color? dividerColor,
    double? borderThickness,
    double? dividerThickness,
    EdgeInsetsGeometry? iconPadding,
    EdgeInsetsGeometry? tilePadding,
  }) {
    return TileContainer(
      key: key,
      items: items,
      style: TileContainerStyle.solidBox,
      width: width,
      backgroundColor: backgroundColor,
      dividerColor: dividerColor,
      borderRadius: borderRadius ?? 15,
      showDividers: true,
      borderThickness: borderThickness ?? 1.5,
      dividerThickness: dividerThickness ?? 1.5,
      iconPadding: iconPadding,
      tilePadding: tilePadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLight;

    const lightBG = Color.fromARGB(255, 228, 239, 240);
    const darkBG = Color.fromARGB(255, 34, 52, 65);

    final resolvedBG = backgroundColor ?? (isLight ? lightBG : darkBG);
    final resolvedDivider = dividerColor ??
        (isLight
            ? ThemeConstants.homeDividerLight.withValues(alpha: 0.3)
            : ThemeConstants.homeDividerLight.withValues(alpha: 0.2));

    final maxWidth = width ?? context.screenWidth - 70;

    switch (style) {
      case TileContainerStyle.solidBox:
        return _buildSolidBox(maxWidth, resolvedBG, resolvedDivider);

      case TileContainerStyle.softTiles:
        return _buildSoftTiles(maxWidth, resolvedDivider, resolvedBG);
    }
  }

  /// Solid mode: one container wrapping all tiles
  Widget _buildSolidBox(double maxWidth, Color bg, Color divider) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: maxWidth,
        decoration: ShapeDecoration(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: divider, width: borderThickness ?? 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _buildTile(items[i]),
              if (i < items.length - 1 && showDividers)
                Divider(
                  height: 1,
                  thickness: dividerThickness ?? 1.5,
                  color: divider,
                  indent: 15,
                  endIndent: 15,
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Soft mode: each tile gets its own rounded container (fixed width + corner behavior)
  Widget _buildSoftTiles(double maxWidth, Color bg, Color gapColor) {
    // small radius for interior corners
    const double innerRadius = 5.0;
    final isSingle = items.length == 1;

    return Container(
      width: maxWidth,
      // gapColor becomes the visible color between tiles
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular( isSingle ? borderRadius : (i == 0 ? borderRadius : innerRadius)),
                topRight: Radius.circular( isSingle ? borderRadius : (i == 0 ? borderRadius : innerRadius)),
                bottomLeft: Radius.circular(isSingle ? borderRadius : (i == items.length - 1 ? borderRadius : innerRadius)),
                bottomRight: Radius.circular(isSingle ? borderRadius : (i == items.length - 1 ? borderRadius : innerRadius)),
              ),
              child: Material(
                color: bg,
                clipBehavior: Clip.antiAlias,
                child: _buildTile(items[i]),
              ),
            ),
            if (i < items.length - 1) const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  /// Shared tile builder
  Widget _buildTile(TileItem item) {
    return ListTile(
      contentPadding: tilePadding,
      leading: Padding(
        padding: iconPadding ?? const EdgeInsets.all(8.0),
        child: item.icon,
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w200),
      ),
      onTap: item.onTap,
    );
  }
}

/// Available styles
enum TileContainerStyle { solidBox, softTiles }

/// Declarative item model
class TileItem {
  final String title;
  final Widget icon;
  final VoidCallback? onTap;

  const TileItem({
    required this.title,
    required this.icon,
    this.onTap,
  });
}
