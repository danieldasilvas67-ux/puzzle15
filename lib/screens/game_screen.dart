import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_scope.dart';
import '../logic/game_session.dart';
import '../logic/puzzle_board.dart';
import '../models/high_score.dart';
import '../models/tile_style.dart';
import '../utils/formatters.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/puzzle_board_view.dart';

/// Pantalla de juego.
///
/// Es StatefulWidget porque su estado (tablero, contador, reloj, overlay)
/// cambia con cada interacción y solo le importa a esta pantalla, por eso
/// se usa setState. La lógica vive en [GameSession]/[PuzzleBoard].
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late GameSession _session;
  Timer? _ticker;
  RecordResult? _record;
  bool _showOverlay = false;
  bool _initialized = false;
  final FocusNode _focusNode = FocusNode(debugLabel: 'board');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), _onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _session = _newSession();
    }
  }

  GameSession _newSession() {
    final s = AppScope.read(context).settings.settings;
    return GameSession(difficulty: s.difficulty, challengeMode: s.challengeMode);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  /// Si la app pasa a segundo plano, se pausa para no perder tiempo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        _session.status == GameStatus.playing) {
      setState(_session.pause);
    }
  }

  void _onTick(Timer _) {
    if (!mounted || _session.status != GameStatus.playing) return;
    final timeUp = _session.checkTimeLimit();
    setState(() {});
    if (timeUp) _onGameOver();
  }

  // ---------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------

  void _handleTileTap(int tile) {
    _focusNode.requestFocus();
    final moved = _session.tryMoveTile(tile);
    _afterMove(moved);
  }

  void _handleDirection(MoveDirection direction) {
    final moved = _session.tryMoveDirection(direction);
    _afterMove(moved);
  }

  void _afterMove(bool moved) {
    if (!moved) return;
    _feedback();
    setState(() {});
    if (_session.status == GameStatus.won) _onGameOver();
  }

  void _feedback() {
    final s = AppScope.read(context).settings.settings;
    if (!s.soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  void _onGameOver() {
    final won = _session.status == GameStatus.won;
    if (won) {
      _record = AppScope.read(context).highScores.submitWin(
            _session.difficulty,
            _session.elapsed,
            _session.moves,
          );
      if (AppScope.read(context).settings.settings.soundEnabled) {
        HapticFeedback.heavyImpact();
      }
    }
    // Pequeña pausa para que se vea la última pieza deslizarse.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && _session.isOver) setState(() => _showOverlay = true);
    });
  }

  void _togglePause() {
    setState(() {
      if (_session.status == GameStatus.playing) {
        _session.pause();
      } else if (_session.status == GameStatus.paused) {
        _session.resume();
        _focusNode.requestFocus();
      }
    });
  }

  void _restart() {
    setState(() {
      _session = _newSession();
      _record = null;
      _showOverlay = false;
    });
    _focusNode.requestFocus();
  }

  Future<void> _confirmRestart() async {
    if (_session.moves == 0 || _session.isOver) {
      _restart();
      return;
    }
    final wasPlaying = _session.status == GameStatus.playing;
    if (wasPlaying) setState(_session.pause);
    final ok = await _confirm(
      title: '¿Reiniciar la partida?',
      message: 'Se generará un tablero nuevo y perderás el progreso actual.',
      confirmLabel: 'Reiniciar',
    );
    if (!mounted) return;
    if (ok) {
      _restart();
    } else if (wasPlaying) {
      setState(_session.resume);
    }
  }

  Future<void> _confirmSurrender() async {
    final wasPlaying = _session.status == GameStatus.playing;
    if (wasPlaying) setState(_session.pause);
    final ok = await _confirm(
      title: '¿Rendirte?',
      message: 'La partida contará como perdida.',
      confirmLabel: 'Rendirme',
    );
    if (!mounted) return;
    if (ok) {
      setState(_session.surrender);
      _onGameOver();
    } else if (wasPlaying) {
      setState(_session.resume);
    }
  }

  bool get _inProgress =>
      _session.moves > 0 &&
      (_session.status == GameStatus.playing ||
          _session.status == GameStatus.paused);

  Future<void> _handleBack() async {
    if (!_inProgress) {
      Navigator.of(context).pop();
      return;
    }
    final wasPlaying = _session.status == GameStatus.playing;
    if (wasPlaying) setState(_session.pause);
    final ok = await _confirm(
      title: '¿Salir al menú?',
      message: 'La partida en curso se perderá.',
      confirmLabel: 'Salir',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else if (wasPlaying) {
      setState(_session.resume);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    MoveDirection? direction;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      direction = MoveDirection.up;
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      direction = MoveDirection.down;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      direction = MoveDirection.left;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      direction = MoveDirection.right;
    } else if (key == LogicalKeyboardKey.keyP ||
        key == LogicalKeyboardKey.space) {
      _togglePause();
      return KeyEventResult.handled;
    }
    if (direction == null) return KeyEventResult.ignored;
    _handleDirection(direction);
    return KeyEventResult.handled;
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings.settings;
    final difficulty = _session.difficulty;
    final paused = _session.status == GameStatus.paused;
    final canPause = _session.status == GameStatus.playing || paused;

    return PopScope(
      canPop: !_inProgress,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Volver al menú',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
          title: Text('${difficulty.label} · ${difficulty.gridLabel}'),
          actions: [
            IconButton(
              tooltip: paused ? 'Continuar' : 'Pausar',
              onPressed: canPause ? _togglePause : null,
              icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            ),
            IconButton(
              tooltip: 'Reiniciar',
              onPressed: _confirmRestart,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _onKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > constraints.maxHeight &&
                    constraints.maxWidth >= 720;
                final double boardSize = wide
                    ? min(constraints.maxHeight - 32, constraints.maxWidth * 0.58)
                    : min(constraints.maxWidth - 32, constraints.maxHeight - 250);
                final board = _buildBoard(
                  max(180.0, min(boardSize, 640.0)),
                  settings.tileStyle,
                  settings.animationsEnabled,
                );
                final panel = _buildPanel(wide);

                final content = wide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          board,
                          const SizedBox(width: 32),
                          SizedBox(width: 300, child: panel),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _StatsBar(session: _session),
                            const SizedBox(height: 16),
                            board,
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: panel,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );

                return Stack(
                  children: [
                    Positioned.fill(child: Center(child: content)),
                    if (_showOverlay)
                      GameOverOverlay(
                        won: _session.status == GameStatus.won,
                        lossReason: _session.lossReason,
                        difficulty: difficulty,
                        elapsed: _session.elapsed,
                        moves: _session.moves,
                        record: _record,
                        animate: settings.animationsEnabled,
                        onRestart: _restart,
                        onViewBoard: () => setState(() => _showOverlay = false),
                        onExit: () => Navigator.of(context).pop(),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(double size, TileStyle tileStyle, bool animate) {
    final paused = _session.status == GameStatus.paused;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          PuzzleBoardView(
            board: _session.board,
            dimension: size,
            style: tileStyle,
            animate: animate,
            hidden: paused,
            onTileTap: _handleTileTap,
          ),
          if (paused)
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pause_circle_rounded,
                        size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('En pausa',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _togglePause,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPanel(bool wide) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final status = _session.status;

    final String hint;
    switch (status) {
      case GameStatus.ready:
        hint = 'Toca una pieza junto al espacio vacío para empezar. '
            'El cronómetro arranca con tu primer movimiento.';
      case GameStatus.playing:
        hint = 'Teclado: flechas o WASD para mover, P para pausar.';
      case GameStatus.paused:
        hint = 'Partida en pausa. El tiempo está detenido.';
      case GameStatus.won:
      case GameStatus.lost:
        hint = 'Partida terminada.';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide) ...[
          _StatsBar(session: _session, vertical: true),
          const SizedBox(height: 20),
        ],
        Text(
          hint,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (_session.isOver) ...[
          FilledButton.icon(
            onPressed: () => setState(() => _showOverlay = true),
            icon: const Icon(Icons.summarize_rounded),
            label: const Text('Ver resultado'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Nueva partida'),
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _confirmRestart,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Reiniciar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: _session.moves > 0 ? _confirmSurrender : null,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Rendirse'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Contadores: movimientos, tiempo (o tiempo restante) y piezas colocadas.
class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.session, this.vertical = false});

  final GameSession session;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = session.remaining;
    final lowTime = remaining != null && remaining.inSeconds < 30;

    final items = [
      _StatTile(
        icon: Icons.swap_horiz_rounded,
        label: 'Movimientos',
        value: '${session.moves}',
      ),
      _StatTile(
        icon: remaining != null ? Icons.hourglass_bottom_rounded : Icons.timer_outlined,
        label: remaining != null ? 'Restante' : 'Tiempo',
        value: formatDuration(remaining ?? session.elapsed),
        color: lowTime ? scheme.error : null,
      ),
      _StatTile(
        icon: Icons.check_circle_outline_rounded,
        label: 'En su lugar',
        value: '${session.board.tilesInPlace}/${session.board.tileCount}',
      ),
    ];

    if (vertical) {
      return Column(
        children: [
          for (final item in items)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: item),
        ],
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: items[i]),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fg = color ?? scheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color ?? scheme.primary),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(label, style: textTheme.labelSmall, maxLines: 1),
        ],
      ),
    );
  }
}
