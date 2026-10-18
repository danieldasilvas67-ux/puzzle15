/// Niveles de dificultad del juego.
///
/// Cada nivel define el tamaño de la cuadrícula y el tiempo límite
/// usado cuando el "Modo desafío" está activo (condición de derrota).
enum Difficulty {
  easy(size: 3, label: 'Fácil', timeLimit: Duration(minutes: 3)),
  medium(size: 4, label: 'Medio', timeLimit: Duration(minutes: 10)),
  hard(size: 5, label: 'Difícil', timeLimit: Duration(minutes: 25));

  const Difficulty({
    required this.size,
    required this.label,
    required this.timeLimit,
  });

  final int size;
  final String label;
  final Duration timeLimit;

  /// Número de piezas (sin contar el espacio vacío).
  int get tileCount => size * size - 1;

  String get gridLabel => '${size}x$size';

  String get description => '$gridLabel · $tileCount piezas';

  static Difficulty fromName(String? name) {
    return Difficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => Difficulty.medium,
    );
  }
}
