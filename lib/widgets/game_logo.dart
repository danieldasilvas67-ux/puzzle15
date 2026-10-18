import 'package:flutter/material.dart';

/// Logo del juego: mini tablero 2x2 con una pieza faltante.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [scheme.primary, scheme.tertiary, scheme.secondary];
    final cell = size / 2;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: (i % 2) * cell,
              top: (i ~/ 2) * cell,
              width: cell,
              height: cell,
              child: Padding(
                padding: EdgeInsets.all(size * 0.03),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(size * 0.12),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: cell * 0.45,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
