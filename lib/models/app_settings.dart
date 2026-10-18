import 'package:flutter/material.dart';

import 'difficulty.dart';
import 'tile_style.dart';

/// Preferencias del usuario. Inmutable: los cambios se hacen con [copyWith].
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.difficulty = Difficulty.medium,
    this.hasChosenDifficulty = false,
    this.tileStyle = TileStyle.classic,
    this.soundEnabled = true,
    this.animationsEnabled = true,
    this.challengeMode = true,
  });

  final ThemeMode themeMode;
  final Difficulty difficulty;

  /// Si el usuario ya eligió una dificultad alguna vez. Si es `false`,
  /// al pulsar "Jugar" se le pide que seleccione una.
  final bool hasChosenDifficulty;
  final TileStyle tileStyle;
  final bool soundEnabled;
  final bool animationsEnabled;

  /// Modo desafío: la partida tiene tiempo límite y se puede perder.
  final bool challengeMode;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Difficulty? difficulty,
    bool? hasChosenDifficulty,
    TileStyle? tileStyle,
    bool? soundEnabled,
    bool? animationsEnabled,
    bool? challengeMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      difficulty: difficulty ?? this.difficulty,
      hasChosenDifficulty: hasChosenDifficulty ?? this.hasChosenDifficulty,
      tileStyle: tileStyle ?? this.tileStyle,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      challengeMode: challengeMode ?? this.challengeMode,
    );
  }
}
