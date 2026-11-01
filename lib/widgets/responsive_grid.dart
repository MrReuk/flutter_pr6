import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

/// Плитки в несколько колонок. Число колонок зависит от места, которое
/// выделил родитель, а не от размера окна: на телефоне плитки идут в одну
/// колонку на всю ширину, на планшете в две, на мониторе в три и больше.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 260,
    this.spacing = 12,
  });

  final List<Widget> children;

  /// Наименьшая допустимая ширина плитки.
  final double minTileWidth;

  /// Промежуток между плитками по горизонтали и вертикали.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : minTileWidth;
        final columns = gridColumns(width, minTile: minTileWidth, spacing: spacing);
        final tileWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final child in children) SizedBox(width: tileWidth, child: child)],
        );
      },
    );
  }
}
