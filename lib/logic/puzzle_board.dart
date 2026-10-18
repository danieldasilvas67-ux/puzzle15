import 'dart:math';

/// Dirección en la que se desplaza una PIEZA (no el hueco).
enum MoveDirection { up, down, left, right }

/// Lógica pura del tablero, sin dependencias de UI.
///
/// El tablero se representa como una lista plana de `size * size`
/// enteros, en orden de lectura (izquierda a derecha, arriba a abajo).
/// El valor `0` representa el espacio vacío.
class PuzzleBoard {
  PuzzleBoard._(this.size, this._tiles);

  /// Tablero ordenado: 1, 2, ..., n-1 y el hueco al final.
  factory PuzzleBoard.solved(int size) {
    return PuzzleBoard._(size, solvedTiles(size));
  }

  /// Crea un tablero a partir de una lista concreta (útil para pruebas).
  factory PuzzleBoard.fromTiles(int size, List<int> tiles) {
    assert(tiles.length == size * size, 'La lista no coincide con el tamaño');
    return PuzzleBoard._(size, List<int>.of(tiles));
  }

  /// Tablero desordenado aleatoriamente y garantizado como resoluble.
  ///
  /// Se baraja con Fisher-Yates ([List.shuffle]) y se repite mientras la
  /// permutación no sea resoluble (validación de paridad de inversiones)
  /// o quede ya ordenada. Cada intento tiene ~50% de probabilidad de ser
  /// válido, así que en la práctica se necesitan muy pocos intentos.
  factory PuzzleBoard.shuffled(int size, {Random? random}) {
    final rng = random ?? Random();
    final tiles = solvedTiles(size);
    do {
      tiles.shuffle(rng);
    } while (!isSolvable(tiles, size) || _listEquals(tiles, solvedTiles(size)));
    return PuzzleBoard._(size, tiles);
  }

  final int size;
  final List<int> _tiles;

  // ---------------------------------------------------------------------
  // Utilidades estáticas
  // ---------------------------------------------------------------------

  static List<int> solvedTiles(int size) =>
      [for (var i = 1; i < size * size; i++) i, 0];

  /// Cuenta los pares (a, b) donde a aparece antes que b pero a > b,
  /// ignorando el hueco.
  static int countInversions(List<int> tiles) {
    final numbers = tiles.where((t) => t != 0).toList();
    var inversions = 0;
    for (var i = 0; i < numbers.length; i++) {
      for (var j = i + 1; j < numbers.length; j++) {
        if (numbers[i] > numbers[j]) inversions++;
      }
    }
    return inversions;
  }

  /// Regla de resolubilidad del N-puzzle:
  /// * Ancho impar (3x3, 5x5): resoluble si las inversiones son pares.
  /// * Ancho par (4x4): resoluble si (inversiones + fila del hueco contada
  ///   desde abajo, empezando en 1) es impar.
  static bool isSolvable(List<int> tiles, int size) {
    final inversions = countInversions(tiles);
    if (size.isOdd) return inversions.isEven;
    final blankRowFromBottom = size - (tiles.indexOf(0) ~/ size);
    return (inversions + blankRowFromBottom).isOdd;
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------

  List<int> get tiles => List.unmodifiable(_tiles);

  int get tileCount => size * size - 1;

  int get blankIndex => _tiles.indexOf(0);

  int indexOfTile(int tile) => _tiles.indexOf(tile);

  int rowOf(int index) => index ~/ size;

  int colOf(int index) => index % size;

  /// La pieza `tile` está en su posición final.
  bool isTileInPlace(int tile) => indexOfTile(tile) == tile - 1;

  int get tilesInPlace {
    var count = 0;
    for (var t = 1; t <= tileCount; t++) {
      if (isTileInPlace(t)) count++;
    }
    return count;
  }

  /// Victoria: todas las piezas en orden y el hueco al final.
  bool get isSolved {
    for (var i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles.last == 0;
  }

  /// Una pieza se puede mover si es adyacente (no en diagonal) al hueco.
  bool canMove(int tile) {
    if (tile <= 0) return false;
    final index = indexOfTile(tile);
    if (index < 0) return false;
    final blank = blankIndex;
    final sameRow = rowOf(index) == rowOf(blank);
    final sameCol = colOf(index) == colOf(blank);
    final rowDiff = (rowOf(index) - rowOf(blank)).abs();
    final colDiff = (colOf(index) - colOf(blank)).abs();
    return (sameRow && colDiff == 1) || (sameCol && rowDiff == 1);
  }

  // ---------------------------------------------------------------------
  // Movimientos
  // ---------------------------------------------------------------------

  /// Mueve la pieza al hueco. Devuelve `false` si el movimiento no es válido.
  bool moveTile(int tile) {
    if (!canMove(tile)) return false;
    final index = indexOfTile(tile);
    final blank = blankIndex;
    _tiles[blank] = tile;
    _tiles[index] = 0;
    return true;
  }

  /// Mueve la pieza que se encuentra junto al hueco en la dirección
  /// indicada (pensado para teclado: flecha arriba sube la pieza de abajo).
  bool moveInDirection(MoveDirection direction) {
    final blank = blankIndex;
    final row = rowOf(blank);
    final col = colOf(blank);
    int? source;
    switch (direction) {
      case MoveDirection.up:
        if (row < size - 1) source = blank + size;
      case MoveDirection.down:
        if (row > 0) source = blank - size;
      case MoveDirection.left:
        if (col < size - 1) source = blank + 1;
      case MoveDirection.right:
        if (col > 0) source = blank - 1;
    }
    if (source == null) return false;
    return moveTile(_tiles[source]);
  }
}
