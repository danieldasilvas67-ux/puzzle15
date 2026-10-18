import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/difficulty.dart';
import '../models/tile_style.dart';
import '../widgets/puzzle_tile.dart';

/// Ajustes. Cada cambio se guarda al instante y se refleja en toda la app.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final s = controller.settings;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const _SectionTitle('Dificultad', Icons.grid_view_rounded),
                  SegmentedButton<Difficulty>(
                    segments: [
                      for (final d in Difficulty.values)
                        ButtonSegment(
                          value: d,
                          label: Text(d.label),
                          tooltip: d.description,
                        ),
                    ],
                    selected: {s.difficulty},
                    onSelectionChanged: (v) =>
                        controller.setDifficulty(v.first),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      '${s.difficulty.description}'
                      '${s.hasChosenDifficulty ? '' : ' (aún no elegida)'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const _SectionTitle('Tema', Icons.palette_outlined),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Claro'),
                        icon: Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Oscuro'),
                        icon: Icon(Icons.dark_mode_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Auto'),
                        icon: Icon(Icons.brightness_auto_rounded),
                      ),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => controller.setThemeMode(v.first),
                  ),
                  const _SectionTitle(
                      'Estilo de las piezas', Icons.style_outlined),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 480 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.15,
                        children: [
                          for (final style in TileStyle.values)
                            _StyleOption(
                              style: style,
                              selected: style == s.tileStyle,
                              onTap: () => controller.setTileStyle(style),
                            ),
                        ],
                      );
                    },
                  ),
                  const _SectionTitle('Partida', Icons.sports_esports_outlined),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.timer_outlined),
                          title: const Text('Modo desafío'),
                          subtitle: Text(
                            'Tiempo límite: ${Difficulty.values.map((d) => '${d.label} ${d.timeLimit.inMinutes} min').join(', ')}. '
                            'Si se acaba, pierdes.',
                          ),
                          value: s.challengeMode,
                          onChanged: controller.setChallengeMode,
                        ),
                        SwitchListTile(
                          secondary: const Icon(Icons.animation_rounded),
                          title: const Text('Animaciones'),
                          subtitle: const Text(
                              'Deslizamiento de piezas y transiciones'),
                          value: s.animationsEnabled,
                          onChanged: controller.setAnimations,
                        ),
                        SwitchListTile(
                          secondary: const Icon(Icons.volume_up_outlined),
                          title: const Text('Efectos de sonido'),
                          subtitle: const Text(
                              'Clic y vibración al mover (sin música)'),
                          value: s.soundEnabled,
                          onChanged: controller.setSound,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _confirmReset(context),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Restaurar valores predeterminados'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Volver al menú'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Restaurar ajustes?'),
        content: const Text(
          'Se volverá a la configuración inicial. Tus marcadores no se borran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).settings.resetToDefaults();
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final TileStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color:
            selected ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var n = 1; n <= 3; n++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: SizedBox.square(
                            dimension: 36,
                            child: IgnorePointer(
                              child: PuzzleTile(
                                number: n,
                                totalTiles: 8,
                                style: style,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  style.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
