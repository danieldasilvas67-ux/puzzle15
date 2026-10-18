import 'package:flutter/material.dart';

/// Pantalla estática: StatelessWidget. No depende de ningún controlador.
class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo jugar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _SolvedPreview(),
              const SizedBox(height: 16),
              const _Rule(
                icon: Icons.flag_rounded,
                title: 'Objetivo',
                body:
                    'Ordena las piezas en orden numérico utilizando el espacio '
                    'vacío para deslizar las piezas adyacentes.',
              ),
              const _Rule(
                icon: Icons.touch_app_rounded,
                title: 'Cómo mover',
                body:
                    'Toca o haz clic en una pieza que esté junto al espacio vacío '
                    '(arriba, abajo, izquierda o derecha) y se deslizará hacia él. '
                    'En computadora también puedes usar las flechas del teclado o '
                    'W A S D. Las diagonales no están permitidas.',
              ),
              const _Rule(
                icon: Icons.emoji_events_rounded,
                title: 'Cuándo ganas',
                body:
                    'Ganas cuando todas las piezas quedan ordenadas de izquierda a '
                    'derecha y de arriba hacia abajo (1, 2, 3...) y el espacio vacío '
                    'queda al final, en la esquina inferior derecha.',
              ),
              const _Rule(
                icon: Icons.timer_off_rounded,
                title: 'Cuándo pierdes',
                body:
                    'Con el "Modo desafío" activo cada dificultad tiene un tiempo '
                    'límite (Fácil 3 min, Medio 10 min, Difícil 25 min). Si el '
                    'cronómetro llega al límite antes de ordenar el tablero, pierdes. '
                    'También pierdes si pulsas "Rendirse". Sin el modo desafío no '
                    'hay límite de tiempo.',
              ),
              const _Rule(
                icon: Icons.timer_outlined,
                title: 'Tiempo y movimientos',
                body: 'El cronómetro empieza con tu primer movimiento y cada '
                    'deslizamiento suma uno al contador. Puedes pausar en cualquier '
                    'momento: el tablero se oculta mientras está en pausa.',
              ),
              const _Rule(
                icon: Icons.star_rounded,
                title: 'Récords',
                body:
                    'Por cada dificultad se guardan tu mejor tiempo y tu menor '
                    'número de movimientos. Siempre es posible resolver el tablero: '
                    'el juego solo genera combinaciones con solución.',
              ),
              const _Rule(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Consejo',
                body:
                    'Resuelve primero la fila superior y la columna izquierda; '
                    'luego trabaja el tablero restante como si fuera uno más pequeño. '
                    'El punto en la esquina de cada pieza indica que ya está en su lugar.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Volver al menú'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini tablero 3x3 resuelto como referencia visual.
class _SolvedPreview extends StatelessWidget {
  const _SolvedPreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text('Así se ve un tablero resuelto',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox.square(
          dimension: 150,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 1; i <= 9; i++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: i == 9
                        ? scheme.surfaceContainerHighest
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      i == 9 ? '' : '$i',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
