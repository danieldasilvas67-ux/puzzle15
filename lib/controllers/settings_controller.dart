import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/difficulty.dart';
import '../models/tile_style.dart';
import '../services/storage_service.dart';

/// Mantiene las preferencias en memoria, las persiste y avisa a la UI.
///
/// Se usa un [ChangeNotifier] (incluido en Flutter) porque las
/// preferencias se comparten entre varias pantallas (tema global, menú,
/// juego). Con setState local no se reflejarían de inmediato en todas.
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage) : _settings = _storage.loadSettings();

  final StorageService _storage;
  AppSettings _settings;

  AppSettings get settings => _settings;

  void _update(AppSettings next) {
    _settings = next;
    notifyListeners();
    unawaited(_storage.saveSettings(next));
  }

  void setThemeMode(ThemeMode mode) =>
      _update(_settings.copyWith(themeMode: mode));

  void setDifficulty(Difficulty d) =>
      _update(_settings.copyWith(difficulty: d, hasChosenDifficulty: true));

  void setTileStyle(TileStyle style) =>
      _update(_settings.copyWith(tileStyle: style));

  void setSound(bool enabled) =>
      _update(_settings.copyWith(soundEnabled: enabled));

  void setAnimations(bool enabled) =>
      _update(_settings.copyWith(animationsEnabled: enabled));

  void setChallengeMode(bool enabled) =>
      _update(_settings.copyWith(challengeMode: enabled));

  void resetToDefaults() => _update(const AppSettings());
}
