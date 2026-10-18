import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/difficulty.dart';
import '../models/high_score.dart';
import '../utils/formatters.dart';

class HighScoresScreen extends StatelessWidget {
  const HighScoresScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded),
        title: const Text('¿Borrar todos los marcadores?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await AppScope.read(context).highScores.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marcadores borrados')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scores = AppScope.of(context).highScores;

    return ListenableBuilder(
      listenable: scores,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Marcadores'),
          actions: [
            IconButton(
              tooltip: 'Borrar marcadores',
              onPressed: scores.isEmpty ? null : () => _confirmClear(context),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (scores.isEmpty)
                  const _EmptyState()
                else
                  for (final d in Difficulty.values)
                    _ScoreCard(difficulty: d, score: scores.scoreFor(d)),
                const SizedBox(height: 16),
                if (!scores.isEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => _confirmClear(context),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Borrar todos los marcadores'),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Volver al menú'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: scheme.primary),
          const SizedBox(height: 16),
          Text('Todavía no hay récords', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Completa tu primera partida y aquí aparecerán tu mejor tiempo '
            'y tu menor número de movimientos. ¡Tú puedes!',
            textAlign: TextAlign.center,
            style:
                textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.difficulty, required this.score});

  final Difficulty difficulty;
  final HighScore? score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final s = score;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Text(difficulty.gridLabel,
                      style: TextStyle(color: scheme.onPrimaryContainer)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(difficulty.label,
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (s != null)
                  Chip(
                    label: Text(
                        '${s.gamesWon} ${s.gamesWon == 1 ? 'victoria' : 'victorias'}'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (s == null)
              Text('Sin partidas ganadas en esta dificultad.',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant))
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Stat(
                    icon: Icons.timer_outlined,
                    label: 'Mejor tiempo',
                    value: formatDuration(s.bestTime),
                    date: formatDate(s.bestTimeDate),
                  ),
                  _Stat(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Menos movimientos',
                    value: '${s.fewestMoves}',
                    date: formatDate(s.fewestMovesDate),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.date,
  });

  final IconData icon;
  final String label;
  final String value;
  final String date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.labelMedium),
              Text(value,
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(date,
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
