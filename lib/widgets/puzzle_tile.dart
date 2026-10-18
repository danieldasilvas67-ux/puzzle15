import 'package:flutter/material.dart';

import '../models/tile_style.dart';

/// Una pieza del tablero dibujada según el [TileStyle] elegido.
class PuzzleTile extends StatelessWidget {
  const PuzzleTile({
    super.key,
    required this.number,
    required this.totalTiles,
    required this.style,
    this.inPlace = false,
    this.onTap,
  });

  final int number;
  final int totalTiles;
  final TileStyle style;
  final bool inPlace;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final look = _TileLook.resolve(style, scheme, isDark, number, totalTiles);

    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = constraints.biggest.shortestSide;
        final radius = BorderRadius.circular(extent * 0.18);
        return Semantics(
          button: onTap != null,
          label: 'Pieza $number',
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                gradient: look.gradient,
                color: look.gradient == null ? look.background : null,
                borderRadius: radius,
                border: look.border,
                boxShadow: look.shadows,
              ),
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          color: look.foreground,
                          fontSize: extent * 0.4,
                          fontWeight: look.weight,
                          fontFamily: look.fontFamily,
                          height: 1,
                        ),
                      ),
                    ),
                    if (inPlace)
                      Positioned(
                        top: extent * 0.1,
                        right: extent * 0.1,
                        child: Container(
                          width: extent * 0.09,
                          height: extent * 0.09,
                          decoration: BoxDecoration(
                            color: look.foreground.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TileLook {
  const _TileLook({
    required this.background,
    required this.foreground,
    this.gradient,
    this.border,
    this.shadows,
    this.weight = FontWeight.w800,
    this.fontFamily,
  });

  final Color background;
  final Color foreground;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final FontWeight weight;
  final String? fontFamily;

  static _TileLook resolve(
    TileStyle style,
    ColorScheme scheme,
    bool isDark,
    int number,
    int total,
  ) {
    switch (style) {
      case TileStyle.classic:
        return _TileLook(
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          shadows: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case TileStyle.colorful:
        final hue = ((number - 1) / total) * 320;
        final base = HSLColor.fromAHSL(1, hue, 0.7, isDark ? 0.45 : 0.55);
        return _TileLook(
          background: base.toColor(),
          foreground: Colors.white,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              base
                  .withLightness((base.lightness + 0.1).clamp(0.0, 1.0))
                  .toColor(),
              base.toColor(),
            ],
          ),
          shadows: [
            BoxShadow(
              color: base.toColor().withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        );
      case TileStyle.retro:
        const wood = Color(0xFFF2D49B);
        const edge = Color(0xFF7A4B1E);
        return const _TileLook(
          background: wood,
          foreground: Color(0xFF4A2C0E),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [wood, Color(0xFFE0B46A)],
          ),
          border: Border.fromBorderSide(BorderSide(color: edge, width: 2)),
          shadows: [BoxShadow(color: edge, offset: Offset(3, 3))],
          fontFamily: 'monospace',
        );
      case TileStyle.minimal:
        return _TileLook(
          background: scheme.surface,
          foreground: scheme.onSurface,
          border: Border.all(color: scheme.outlineVariant, width: 1.5),
          weight: FontWeight.w300,
        );
    }
  }
}
