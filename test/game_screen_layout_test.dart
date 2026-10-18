import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15/controllers/app_scope.dart';
import 'package:puzzle15/controllers/high_score_controller.dart';
import 'package:puzzle15/controllers/settings_controller.dart';
import 'package:puzzle15/models/difficulty.dart';
import 'package:puzzle15/screens/game_screen.dart';
import 'package:puzzle15/services/storage_service.dart';

void main() {
  // Móvil vertical y apaisado, ventana mediana, escritorio y tablet.
  const sizes = [
    Size(390, 844),
    Size(844, 390),
    Size(760, 720),
    Size(1280, 800),
    Size(1024, 1366),
  ];

  for (final size in sizes) {
    for (final difficulty in Difficulty.values) {
      testWidgets(
          'el tablero ${difficulty.gridLabel} no desborda en '
          '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final storage = StorageService.inMemory();
        final settings = SettingsController(storage)..setDifficulty(difficulty);
        await tester.pumpWidget(
          AppScope(
            settings: settings,
            highScores: HighScoreController(storage),
            child: const MaterialApp(home: GameScreen()),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Se desmonta la pantalla para cancelar el temporizador del reloj.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
