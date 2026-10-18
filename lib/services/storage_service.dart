import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/difficulty.dart';
import '../models/high_score.dart';
import '../models/tile_style.dart';

/// Única puerta de acceso a la persistencia local (shared_preferences).
class StorageService {
  StorageService(this._prefs);

  static Future<StorageService> init() async {
    return StorageService(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;

  static const _kTheme = 'settings.themeMode';
  static const _kDifficulty = 'settings.difficulty';
  static const _kChosenDifficulty = 'settings.hasChosenDifficulty';
  static const _kTileStyle = 'settings.tileStyle';
  static const _kSound = 'settings.sound';
  static const _kAnimations = 'settings.animations';
  static const _kChallenge = 'settings.challengeMode';
  static String _scoreKey(Difficulty d) => 'highscore.${d.name}';

  // ---------------------------------------------------------------------
  // Preferencias
  // ---------------------------------------------------------------------

  AppSettings loadSettings() {
    const defaults = AppSettings();
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_kTheme),
        orElse: () => defaults.themeMode,
      ),
      difficulty: Difficulty.fromName(_prefs.getString(_kDifficulty)),
      hasChosenDifficulty:
          _prefs.getBool(_kChosenDifficulty) ?? defaults.hasChosenDifficulty,
      tileStyle: TileStyle.fromName(_prefs.getString(_kTileStyle)),
      soundEnabled: _prefs.getBool(_kSound) ?? defaults.soundEnabled,
      animationsEnabled:
          _prefs.getBool(_kAnimations) ?? defaults.animationsEnabled,
      challengeMode: _prefs.getBool(_kChallenge) ?? defaults.challengeMode,
    );
  }

  Future<void> saveSettings(AppSettings s) async {
    await Future.wait([
      _prefs.setString(_kTheme, s.themeMode.name),
      _prefs.setString(_kDifficulty, s.difficulty.name),
      _prefs.setBool(_kChosenDifficulty, s.hasChosenDifficulty),
      _prefs.setString(_kTileStyle, s.tileStyle.name),
      _prefs.setBool(_kSound, s.soundEnabled),
      _prefs.setBool(_kAnimations, s.animationsEnabled),
      _prefs.setBool(_kChallenge, s.challengeMode),
    ]);
  }

  // ---------------------------------------------------------------------
  // High scores
  // ---------------------------------------------------------------------

  Map<Difficulty, HighScore> loadHighScores() {
    final result = <Difficulty, HighScore>{};
    for (final d in Difficulty.values) {
      final score = HighScore.tryDecode(_prefs.getString(_scoreKey(d)));
      if (score != null) result[d] = score;
    }
    return result;
  }

  Future<void> saveHighScore(Difficulty d, HighScore score) async {
    await _prefs.setString(_scoreKey(d), score.encode());
  }

  Future<void> clearHighScores() async {
    for (final d in Difficulty.values) {
      await _prefs.remove(_scoreKey(d));
    }
  }
}
