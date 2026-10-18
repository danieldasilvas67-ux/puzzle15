import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_menu_button.dart';
import '../widgets/difficulty_picker.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/game_logo.dart';
import 'game_screen.dart';
import 'high_scores_screen.dart';
import 'instructions_screen.dart';
import 'routes.dart';
import 'settings_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<void> _play(BuildContext context) async {
    final controller = AppScope.read(context).settings;
    var settings = controller.settings;

    // Si nunca se eligió dificultad, se pide antes de jugar.
    if (!settings.hasChosenDifficulty) {
      final picked =
          await showDifficultyPicker(context, current: settings.difficulty);
      if (picked == null || !context.mounted) return;
      controller.setDifficulty(picked);
      settings = controller.settings;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      fadeRoute(const GameScreen(), animate: settings.animationsEnabled),
    );
  }

  void _open(BuildContext context, Widget page) {
    final animate = AppScope.read(context).settings.settings.animationsEnabled;
    Navigator.of(context).push(fadeRoute(page, animate: animate));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).settings;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundFor(scheme),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final s = controller.settings;
                    final animate = s.animationsEnabled;
                    Widget staggered(int i, Widget child) => FadeSlideIn(
                          enabled: animate,
                          delay: Duration(milliseconds: 90 * i),
                          child: child,
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        staggered(0, const Center(child: GameLogo(size: 88))),
                        const SizedBox(height: 16),
                        staggered(
                          0,
                          Text(
                            '15-Puzzle Flutter',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        staggered(
                          1,
                          Text(
                            'Ordena las piezas lo más rápido que puedas',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 32),
                        staggered(
                          2,
                          AnimatedMenuButton(
                            primary: true,
                            label: 'Jugar',
                            subtitle: s.hasChosenDifficulty
                                ? '${s.difficulty.label} · ${s.difficulty.gridLabel}'
                                    '${s.challengeMode ? ' · Modo desafío' : ''}'
                                : 'Elige tu dificultad',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () => _play(context),
                          ),
                        ),
                        const SizedBox(height: 14),
                        staggered(
                          3,
                          AnimatedMenuButton(
                            label: 'Marcadores',
                            subtitle: 'Tus mejores tiempos y movimientos',
                            icon: Icons.emoji_events_rounded,
                            onPressed: () =>
                                _open(context, const HighScoresScreen()),
                          ),
                        ),
                        const SizedBox(height: 14),
                        staggered(
                          4,
                          AnimatedMenuButton(
                            label: 'Configuración',
                            subtitle: 'Dificultad, tema y estilo de piezas',
                            icon: Icons.tune_rounded,
                            onPressed: () =>
                                _open(context, const SettingsScreen()),
                          ),
                        ),
                        const SizedBox(height: 14),
                        staggered(
                          5,
                          AnimatedMenuButton(
                            label: 'Instrucciones',
                            subtitle: 'Cómo jugar: reglas y controles',
                            icon: Icons.help_outline_rounded,
                            onPressed: () =>
                                _open(context, const InstructionsScreen()),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
