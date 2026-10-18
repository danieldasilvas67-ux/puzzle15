/// Estilos de visualización de las piezas.
enum TileStyle {
  classic('Numérico clásico'),
  colorful('Colorido'),
  retro('Retro'),
  minimal('Minimalista');

  const TileStyle(this.label);

  final String label;

  static TileStyle fromName(String? name) {
    return TileStyle.values.firstWhere(
      (s) => s.name == name,
      orElse: () => TileStyle.classic,
    );
  }
}
