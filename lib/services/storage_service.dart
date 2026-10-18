import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/difficulty.dart';
import '../models/high_score.dart';
import '../models/tile_style.dart';

/// Única puerta de acceso a la persistencia local (shared_preferences).
///
/// Nunca lanza: si un valor guardado está corrupto se usa el valor por
/// defecto, y si el navegador bloquea el almacenamiento la app sigue
/// funcionando sin persistir.
class StorageService {
  StorageService(SharedPreferences prefs) : _prefs = prefs;

  /// Sin persistencia, para cuando el almacenamiento no está disponible.
  StorageService.inMemory() : _prefs = null;

  static Future<StorageService> init() async {
    try {
      return StorageService(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('Almacenamiento local no disponible: $e');
      return StorageService.inMemory();
    }
  }

  final SharedPreferences? _prefs;

  static const _kTheme = 'settings.themeMode';
  static const _kDifficulty = 'settings.difficulty';
  static const _kChosenDifficulty = 'settings.hasChosenDifficulty';
  static const _kTileStyle = 'settings.tileStyle';
  static const _kSound = 'settings.sound';
  static const _kAnimations = 'settings.animations';
  static const _kChallenge = 'settings.challengeMode';
  static String _scoreKey(Difficulty d) => 'highscore.${d.name}';

  // Lecturas tolerantes: un valor de otro tipo cuenta como ausente.
  String? _getString(String key) {
    try {
      return _prefs?.getString(key);
    } catch (_) {
      return null;
    }
  }

  bool? _getBool(String key) {
    try {
      return _prefs?.getBool(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(Future<bool> Function(SharedPreferences prefs) op) async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await op(prefs);
    } catch (e) {
      debugPrint('No se pudo guardar en el almacenamiento local: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Preferencias
  // ---------------------------------------------------------------------

  AppSettings loadSettings() {
    const defaults = AppSettings();
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == _getString(_kTheme),
        orElse: () => defaults.themeMode,
      ),
      difficulty: Difficulty.fromName(_getString(_kDifficulty)),
      hasChosenDifficulty:
          _getBool(_kChosenDifficulty) ?? defaults.hasChosenDifficulty,
      tileStyle: TileStyle.fromName(_getString(_kTileStyle)),
      soundEnabled: _getBool(_kSound) ?? defaults.soundEnabled,
      animationsEnabled: _getBool(_kAnimations) ?? defaults.animationsEnabled,
      challengeMode: _getBool(_kChallenge) ?? defaults.challengeMode,
    );
  }

  Future<void> saveSettings(AppSettings s) async {
    await Future.wait([
      _write((p) => p.setString(_kTheme, s.themeMode.name)),
      _write((p) => p.setString(_kDifficulty, s.difficulty.name)),
      _write((p) => p.setBool(_kChosenDifficulty, s.hasChosenDifficulty)),
      _write((p) => p.setString(_kTileStyle, s.tileStyle.name)),
      _write((p) => p.setBool(_kSound, s.soundEnabled)),
      _write((p) => p.setBool(_kAnimations, s.animationsEnabled)),
      _write((p) => p.setBool(_kChallenge, s.challengeMode)),
    ]);
  }

  // ---------------------------------------------------------------------
  // High scores
  // ---------------------------------------------------------------------

  Map<Difficulty, HighScore> loadHighScores() {
    final result = <Difficulty, HighScore>{};
    for (final d in Difficulty.values) {
      final score = HighScore.tryDecode(_getString(_scoreKey(d)));
      if (score != null) result[d] = score;
    }
    return result;
  }

  Future<void> saveHighScore(Difficulty d, HighScore score) =>
      _write((p) => p.setString(_scoreKey(d), score.encode()));

  Future<void> clearHighScores() async {
    for (final d in Difficulty.values) {
      await _write((p) => p.remove(_scoreKey(d)));
    }
  }
}
