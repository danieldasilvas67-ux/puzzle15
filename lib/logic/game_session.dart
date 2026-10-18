import 'dart:math';

import '../models/difficulty.dart';
import 'puzzle_board.dart';

enum GameStatus { ready, playing, paused, won, lost }

/// Motivo de la derrota, para mostrarlo en la pantalla de fin de partida.
enum LossReason { timeUp, surrendered }

/// Estado de una partida: tablero, movimientos, cronómetro y estado.
///
/// No conoce nada de widgets; la pantalla solo lee su estado y le
/// delega las acciones del usuario.
class GameSession {
  GameSession({
    required this.difficulty,
    required this.challengeMode,
    Random? random,
  }) : board = PuzzleBoard.shuffled(difficulty.size, random: random);

  final Difficulty difficulty;
  final bool challengeMode;
  final PuzzleBoard board;
  final Stopwatch _stopwatch = Stopwatch();

  int moves = 0;
  GameStatus status = GameStatus.ready;
  LossReason? lossReason;

  Duration get elapsed => _stopwatch.elapsed;

  /// Tiempo restante en modo desafío, o `null` si no aplica.
  Duration? get remaining {
    if (!challengeMode) return null;
    final left = difficulty.timeLimit - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isOver => status == GameStatus.won || status == GameStatus.lost;

  bool get acceptsMoves =>
      status == GameStatus.ready || status == GameStatus.playing;

  bool tryMoveTile(int tile) {
    if (!acceptsMoves) return false;
    if (!board.moveTile(tile)) return false;
    _registerMove();
    return true;
  }

  bool tryMoveDirection(MoveDirection direction) {
    if (!acceptsMoves) return false;
    if (!board.moveInDirection(direction)) return false;
    _registerMove();
    return true;
  }

  void _registerMove() {
    // El cronómetro arranca con el primer movimiento.
    if (status == GameStatus.ready) {
      status = GameStatus.playing;
      _stopwatch.start();
    }
    moves++;
    if (board.isSolved) {
      status = GameStatus.won;
      _stopwatch.stop();
    }
  }

  /// Devuelve `true` si en esta comprobación se agotó el tiempo.
  bool checkTimeLimit() {
    if (!challengeMode || status != GameStatus.playing) return false;
    if (elapsed >= difficulty.timeLimit) {
      _stopwatch.stop();
      status = GameStatus.lost;
      lossReason = LossReason.timeUp;
      return true;
    }
    return false;
  }

  void pause() {
    if (status == GameStatus.playing) {
      _stopwatch.stop();
      status = GameStatus.paused;
    }
  }

  void resume() {
    if (status == GameStatus.paused) {
      _stopwatch.start();
      status = GameStatus.playing;
    }
  }

  void surrender() {
    if (isOver) return;
    _stopwatch.stop();
    status = GameStatus.lost;
    lossReason = LossReason.surrendered;
  }
}
