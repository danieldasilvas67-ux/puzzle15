import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15/logic/game_session.dart';
import 'package:puzzle15/logic/puzzle_board.dart';
import 'package:puzzle15/models/difficulty.dart';

void main() {
  group('PuzzleBoard', () {
    test('el tablero ordenado está resuelto', () {
      for (final size in [3, 4, 5]) {
        expect(PuzzleBoard.solved(size).isSolved, isTrue);
      }
    });

    test('los tableros barajados siempre son resolubles y no vienen ordenados',
        () {
      final rng = Random(42);
      for (final size in [3, 4, 5]) {
        for (var i = 0; i < 300; i++) {
          final board = PuzzleBoard.shuffled(size, random: rng);
          expect(PuzzleBoard.isSolvable(board.tiles, size), isTrue);
          expect(board.isSolved, isFalse);
          expect(board.tiles.toSet().length, size * size);
        }
      }
    });

    test('detecta el clásico 14-15 intercambiado como irresoluble', () {
      final tiles = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 14, 0];
      expect(PuzzleBoard.isSolvable(tiles, 4), isFalse);
    });

    test('3x3 con una inversión es irresoluble', () {
      expect(PuzzleBoard.isSolvable([2, 1, 3, 4, 5, 6, 7, 8, 0], 3), isFalse);
    });

    test('solo se mueven piezas adyacentes al hueco', () {
      final board =
          PuzzleBoard.solved(4); // hueco en la esquina inferior derecha
      expect(board.canMove(15), isTrue);
      expect(board.canMove(12), isTrue);
      expect(board.canMove(11), isFalse); // diagonal
      expect(board.canMove(1), isFalse);
      expect(board.moveTile(1), isFalse);
      expect(board.moveTile(15), isTrue);
      expect(board.blankIndex, 14);
      expect(board.isSolved, isFalse);
    });

    test('no hay saltos de fila entre extremos', () {
      // Hueco al inicio de la fila 2: la pieza al final de la fila 1 no es adyacente.
      final board = PuzzleBoard.fromTiles(3, [1, 2, 3, 0, 4, 5, 6, 7, 8]);
      expect(board.canMove(3), isFalse);
      expect(board.canMove(4), isTrue);
    });

    test('movimiento por dirección', () {
      final board = PuzzleBoard.solved(3);
      expect(board.moveInDirection(MoveDirection.up), isFalse);
      expect(board.moveInDirection(MoveDirection.down), isTrue); // baja el 6
      expect(board.tiles[8], 6);
      expect(board.moveInDirection(MoveDirection.up), isTrue);
      expect(board.isSolved, isTrue);
    });
  });

  group('GameSession', () {
    test('el cronómetro arranca con el primer movimiento y se gana', () {
      final session = GameSession(
        difficulty: Difficulty.easy,
        challengeMode: false,
        random: Random(7),
      );
      expect(session.status, GameStatus.ready);

      final movable = [
        for (var t = 1; t <= 8; t++)
          if (session.board.canMove(t)) t,
      ];
      expect(session.tryMoveTile(movable.first), isTrue);
      expect(session.moves, 1);
      expect(session.status, anyOf(GameStatus.playing, GameStatus.won));
    });

    test('pausa bloquea movimientos y rendirse cuenta como derrota', () {
      final session = GameSession(
        difficulty: Difficulty.medium,
        challengeMode: true,
        random: Random(3),
      );
      final first = [
        for (var t = 1; t <= 15; t++)
          if (session.board.canMove(t)) t,
      ].first;
      session.tryMoveTile(first);
      session.pause();
      expect(session.status, GameStatus.paused);
      expect(session.tryMoveDirection(MoveDirection.up), isFalse);
      session.resume();
      session.surrender();
      expect(session.status, GameStatus.lost);
      expect(session.lossReason, LossReason.surrendered);
      expect(session.remaining, isNotNull);
    });
  });
}
