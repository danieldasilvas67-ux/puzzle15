import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Mejores marcas para una dificultad.
@immutable
class HighScore {
  const HighScore({
    required this.bestTimeMs,
    required this.bestTimeDate,
    required this.fewestMoves,
    required this.fewestMovesDate,
    required this.gamesWon,
  });

  final int bestTimeMs;
  final DateTime bestTimeDate;
  final int fewestMoves;
  final DateTime fewestMovesDate;
  final int gamesWon;

  Duration get bestTime => Duration(milliseconds: bestTimeMs);

  Map<String, dynamic> toJson() => {
        'bestTimeMs': bestTimeMs,
        'bestTimeDate': bestTimeDate.toIso8601String(),
        'fewestMoves': fewestMoves,
        'fewestMovesDate': fewestMovesDate.toIso8601String(),
        'gamesWon': gamesWon,
      };

  factory HighScore.fromJson(Map<String, dynamic> json) {
    final score = HighScore(
      bestTimeMs: json['bestTimeMs'] as int,
      bestTimeDate: DateTime.parse(json['bestTimeDate'] as String),
      fewestMoves: json['fewestMoves'] as int,
      fewestMovesDate: DateTime.parse(json['fewestMovesDate'] as String),
      gamesWon: (json['gamesWon'] as int?) ?? 1,
    );
    // Un récord válido siempre tiene al menos un movimiento y una victoria.
    if (score.bestTimeMs < 0 || score.fewestMoves < 1 || score.gamesWon < 1) {
      throw const FormatException('Récord con valores fuera de rango');
    }
    return score;
  }

  String encode() => jsonEncode(toJson());

  /// Devuelve `null` si el texto guardado está corrupto.
  static HighScore? tryDecode(String? raw) {
    if (raw == null) return null;
    try {
      return HighScore.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// Resultado de registrar una victoria contra los récords existentes.
@immutable
class RecordResult {
  const RecordResult({
    required this.newBestTime,
    required this.newFewestMoves,
  });

  final bool newBestTime;
  final bool newFewestMoves;

  bool get isNewRecord => newBestTime || newFewestMoves;
}
