import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/difficulty.dart';
import '../models/high_score.dart';
import '../services/storage_service.dart';

/// Gestiona los récords por dificultad.
class HighScoreController extends ChangeNotifier {
  HighScoreController(this._storage) : _scores = _storage.loadHighScores();

  final StorageService _storage;
  final Map<Difficulty, HighScore> _scores;

  HighScore? scoreFor(Difficulty d) => _scores[d];

  bool get isEmpty => _scores.isEmpty;

  /// Registra una victoria y devuelve qué récords se superaron.
  RecordResult submitWin(Difficulty d, Duration time, int moves) {
    final now = DateTime.now();
    final timeMs = time.inMilliseconds;
    final previous = _scores[d];

    if (previous == null) {
      _scores[d] = HighScore(
        bestTimeMs: timeMs,
        bestTimeDate: now,
        fewestMoves: moves,
        fewestMovesDate: now,
        gamesWon: 1,
      );
      _persist(d);
      return const RecordResult(newBestTime: true, newFewestMoves: true);
    }

    final betterTime = timeMs < previous.bestTimeMs;
    final fewerMoves = moves < previous.fewestMoves;
    _scores[d] = HighScore(
      bestTimeMs: betterTime ? timeMs : previous.bestTimeMs,
      bestTimeDate: betterTime ? now : previous.bestTimeDate,
      fewestMoves: fewerMoves ? moves : previous.fewestMoves,
      fewestMovesDate: fewerMoves ? now : previous.fewestMovesDate,
      gamesWon: previous.gamesWon + 1,
    );
    _persist(d);
    return RecordResult(newBestTime: betterTime, newFewestMoves: fewerMoves);
  }

  void _persist(Difficulty d) {
    notifyListeners();
    unawaited(_storage.saveHighScore(d, _scores[d]!));
  }

  Future<void> clearAll() async {
    _scores.clear();
    notifyListeners();
    await _storage.clearHighScores();
  }
}
