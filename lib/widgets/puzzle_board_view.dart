import 'package:flutter/material.dart';

import '../logic/puzzle_board.dart';
import '../models/tile_style.dart';
import 'puzzle_tile.dart';

/// Dibuja el tablero. Cada pieza es un [AnimatedPositioned] con clave
/// propia, así Flutter anima el deslizamiento cuando cambia de casilla.
class PuzzleBoardView extends StatelessWidget {
  const PuzzleBoardView({
    super.key,
    required this.board,
    required this.dimension,
    required this.style,
    required this.animate,
    required this.onTileTap,
    this.hidden = false,
  });

  final PuzzleBoard board;
  final double dimension;
  final TileStyle style;
  final bool animate;
  final ValueChanged<int> onTileTap;

  /// Oculta las piezas (pausa) para que no se pueda planear sin reloj.
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const padding = 8.0;
    final inner = dimension - padding * 2;
    final cell = inner / board.size;
    final gap = (inner * 0.012).clamp(2.0, 6.0);

    return Container(
      width: dimension,
      height: dimension,
      padding: const EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: AnimatedOpacity(
        opacity: hidden ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          children: [
            for (var tile = 1; tile <= board.tileCount; tile++)
              _buildTile(tile, cell, gap),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(int tile, double cell, double gap) {
    final index = board.indexOfTile(tile);
    return AnimatedPositioned(
      key: ValueKey(tile),
      duration: animate ? const Duration(milliseconds: 160) : Duration.zero,
      curve: Curves.easeOutCubic,
      left: board.colOf(index) * cell,
      top: board.rowOf(index) * cell,
      width: cell,
      height: cell,
      child: Padding(
        padding: EdgeInsets.all(gap / 2),
        child: PuzzleTile(
          number: tile,
          totalTiles: board.tileCount,
          style: style,
          inPlace: board.isTileInPlace(tile),
          semanticLabel: 'Pieza $tile, fila ${board.rowOf(index) + 1}, '
              'columna ${board.colOf(index) + 1}'
              '${board.canMove(tile) ? ', se puede mover' : ''}',
          onTap: hidden ? null : () => onTileTap(tile),
        ),
      ),
    );
  }
}
