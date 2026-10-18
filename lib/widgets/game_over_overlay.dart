import 'package:flutter/material.dart';

import '../logic/game_session.dart';
import '../models/difficulty.dart';
import '../models/high_score.dart';
import '../utils/formatters.dart';

/// Capa superpuesta de fin de partida (victoria o derrota).
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.won,
    required this.difficulty,
    required this.elapsed,
    required this.moves,
    required this.onRestart,
    required this.onViewBoard,
    required this.onExit,
    this.lossReason,
    this.record,
    this.animate = true,
  });

  final bool won;
  final LossReason? lossReason;
  final Difficulty difficulty;
  final Duration elapsed;
  final int moves;
  final RecordResult? record;
  final VoidCallback onRestart;
  final VoidCallback onViewBoard;
  final VoidCallback onExit;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isRecord = won && (record?.isNewRecord ?? false);

    final subtitle = won
        ? '¡Resolviste el tablero ${difficulty.gridLabel}!'
        : lossReason == LossReason.timeUp
            ? 'Se acabó el tiempo (${formatDuration(difficulty.timeLimit)}).'
            : 'Te rendiste. ¡La próxima sale!';

    final card = Card(
      elevation: 8,
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              won
                  ? Icons.emoji_events_rounded
                  : Icons.sentiment_dissatisfied_rounded,
              size: 72,
              color: won ? Colors.amber.shade600 : scheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              won ? '¡Ganaste!' : 'Perdiste',
              textAlign: TextAlign.center,
              style: textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center),
            if (isRecord) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _recordText(record!),
                    style: TextStyle(
                      color: Colors.brown.shade800,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                _Summary(label: 'Tiempo', value: formatDuration(elapsed)),
                _Summary(label: 'Movimientos', value: '$moves'),
                _Summary(label: 'Dificultad', value: difficulty.label),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Reiniciar'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onViewBoard,
              icon: const Icon(Icons.grid_on_rounded),
              label: const Text('Ver tablero'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onExit,
              icon: const Icon(Icons.home_rounded),
              label: const Text('Salir al menú principal'),
            ),
          ],
        ),
      ),
    );

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: animate
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.7, end: 1),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: card,
                    )
                  : card,
            ),
          ),
        ),
      ),
    );
  }

  static String _recordText(RecordResult r) {
    if (r.newBestTime && r.newFewestMoves)
      return '¡Nuevo récord! Tiempo y movimientos';
    if (r.newBestTime) return '¡Nuevo récord de tiempo!';
    return '¡Nuevo récord de movimientos!';
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: textTheme.labelMedium),
        ],
      ),
    );
  }
}
