import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15/controllers/app_scope.dart';
import 'package:puzzle15/controllers/high_score_controller.dart';
import 'package:puzzle15/controllers/settings_controller.dart';
import 'package:puzzle15/screens/menu_screen.dart';
import 'package:puzzle15/services/storage_service.dart';

void main() {
  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('el botón Jugar se activa con ${key.keyLabel} del teclado',
        (tester) async {
      final storage = StorageService.inMemory();
      await tester.pumpWidget(
        AppScope(
          settings: SettingsController(storage),
          highScores: HighScoreController(storage),
          child: const MaterialApp(home: MenuScreen()),
        ),
      );
      await tester.pumpAndSettle();

      Focus.of(tester.element(find.text('Jugar'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();

      // Sin dificultad elegida, Jugar abre primero el selector.
      expect(find.text('Elige la dificultad'), findsOneWidget);
    });
  }
}
