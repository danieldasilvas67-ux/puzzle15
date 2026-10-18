import 'package:flutter/material.dart';

import 'controllers/app_scope.dart';
import 'controllers/high_score_controller.dart';
import 'controllers/settings_controller.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  runApp(
    PuzzleApp(
      settings: SettingsController(storage),
      highScores: HighScoreController(storage),
    ),
  );
}

class PuzzleApp extends StatelessWidget {
  const PuzzleApp({
    super.key,
    required this.settings,
    required this.highScores,
  });

  final SettingsController settings;
  final HighScoreController highScores;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: settings,
      highScores: highScores,
      // El tema se reconstruye en cuanto cambia la preferencia.
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: '15-Puzzle Flutter',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.settings.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
