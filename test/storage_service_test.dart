import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15/controllers/high_score_controller.dart';
import 'package:puzzle15/models/app_settings.dart';
import 'package:puzzle15/models/difficulty.dart';
import 'package:puzzle15/models/high_score.dart';
import 'package:puzzle15/models/tile_style.dart';
import 'package:puzzle15/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StorageService', () {
    test('los valores corruptos se reemplazan por los valores por defecto',
        () async {
      SharedPreferences.setMockInitialValues({
        'settings.sound': 'si',
        'settings.difficulty': 42,
        'settings.themeMode': true,
        'highscore.easy': '{roto',
        'highscore.medium': 7,
      });
      final storage = await StorageService.init();

      final settings = storage.loadSettings();
      const defaults = AppSettings();
      expect(settings.soundEnabled, defaults.soundEnabled);
      expect(settings.difficulty, defaults.difficulty);
      expect(settings.themeMode, defaults.themeMode);
      expect(storage.loadHighScores(), isEmpty);
    });

    test('guardar y volver a cargar conserva las preferencias', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      const saved = AppSettings(
        themeMode: ThemeMode.dark,
        difficulty: Difficulty.hard,
        hasChosenDifficulty: true,
        tileStyle: TileStyle.minimal,
        soundEnabled: false,
        animationsEnabled: false,
        challengeMode: false,
      );
      await storage.saveSettings(saved);

      final loaded = (await StorageService.init()).loadSettings();
      expect(loaded.themeMode, saved.themeMode);
      expect(loaded.difficulty, saved.difficulty);
      expect(loaded.hasChosenDifficulty, isTrue);
      expect(loaded.tileStyle, saved.tileStyle);
      expect(loaded.soundEnabled, isFalse);
      expect(loaded.animationsEnabled, isFalse);
      expect(loaded.challengeMode, isFalse);
    });

    test('sin almacenamiento la app funciona en memoria', () async {
      final storage = StorageService.inMemory();
      await storage.saveSettings(const AppSettings());
      expect(storage.loadHighScores(), isEmpty);
    });
  });

  group('HighScore', () {
    test('un récord con valores fuera de rango se descarta', () {
      final raw = HighScore(
        bestTimeMs: 1000,
        bestTimeDate: DateTime(2026),
        fewestMoves: 0,
        fewestMovesDate: DateTime(2026),
        gamesWon: 1,
      ).encode();
      expect(HighScore.tryDecode(raw), isNull);
    });
  });

  group('HighScoreController.submitWin', () {
    late HighScoreController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      controller = HighScoreController(await StorageService.init());
    });

    test('la primera victoria es récord de tiempo y de movimientos', () {
      final result = controller.submitWin(
          Difficulty.easy, const Duration(seconds: 30), 40);
      expect(result.newBestTime, isTrue);
      expect(result.newFewestMoves, isTrue);
    });

    test('una victoria peor no es récord pero suma partidas ganadas', () {
      controller.submitWin(Difficulty.easy, const Duration(seconds: 30), 40);
      final result = controller.submitWin(
          Difficulty.easy, const Duration(seconds: 50), 60);
      expect(result.isNewRecord, isFalse);
      expect(controller.scoreFor(Difficulty.easy)!.gamesWon, 2);
    });

    test('mejor tiempo con más movimientos solo mejora el tiempo', () {
      controller.submitWin(Difficulty.easy, const Duration(seconds: 30), 40);
      final result = controller.submitWin(
          Difficulty.easy, const Duration(seconds: 20), 55);
      expect(result.newBestTime, isTrue);
      expect(result.newFewestMoves, isFalse);
      expect(controller.scoreFor(Difficulty.easy)!.fewestMoves, 40);
    });
  });
}
