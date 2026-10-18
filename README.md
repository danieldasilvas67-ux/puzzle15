# 15-Puzzle Flutter

Rompecabezas deslizante (Sliding Puzzle) hecho en Flutter para el micro-proyecto de la Universidad Metropolitana.

## Cómo correrlo

Este repositorio trae el código de la app (`lib/`, `test/`, `pubspec.yaml`). Las carpetas de plataforma (`android/`, `ios/`, `web/` completa, etc.) se generan con Flutter:

```bash
cd puzzle15
flutter create . --project-name puzzle15 --platforms=android,ios,web,windows,macos,linux
flutter pub get
flutter run -d chrome      # o el dispositivo que prefieras
```

`flutter create .` solo agrega los archivos que faltan: no sobrescribe `lib/`, `test/` ni `web/manifest.json`.

Pruebas:

```bash
flutter test
```

Versión web (PWA instalable y con soporte offline gracias al service worker que genera Flutter):

```bash
flutter build web --release
```

## Funcionalidades

- **Splash** con animación de entrada (fade + escala) y botón "Saltar".
- **Menú principal** con fondo temático, botones grandes con animación de presión/hover y entrada escalonada.
- **Configuración** (se guarda al instante y se refleja en toda la app):
  - Dificultad: Fácil 3x3, Medio 4x4, Difícil 5x5.
  - Tema: claro, oscuro o automático (sigue al sistema).
  - Estilo de piezas: Numérico clásico, Colorido, Retro y Minimalista.
  - Modo desafío (tiempo límite), animaciones y efectos de sonido activables.
- **Marcadores** por dificultad: mejor tiempo, menor número de movimientos, fecha de cada récord y victorias. Mensaje amigable si no hay datos y borrado con confirmación.
- **Cómo jugar**: reglas, cuándo se gana y cuándo se pierde.
- **Juego**:
  - Tablero aleatorio garantizado como resoluble (validación de paridad de inversiones).
  - Movimiento por toque/clic y por teclado (flechas o WASD); P o espacio para pausar.
  - Contador de movimientos, cronómetro que arranca en el primer movimiento y contador de piezas en su lugar.
  - Pausa (el tablero se oculta) y pausa automática si la app pasa a segundo plano.
  - Confirmación antes de reiniciar o salir con una partida en curso.
  - Diseño responsive: en pantallas anchas el panel de estadísticas pasa al costado.
- **Fin de partida**: "¡Ganaste!" o "Perdiste" con tiempo, movimientos, dificultad y aviso de "¡Nuevo récord!". Botones Reiniciar, Ver tablero y Salir al menú.

### ¿Cómo se pierde?

Con el **Modo desafío** activo (por defecto) cada dificultad tiene tiempo límite: Fácil 3 min, Medio 10 min, Difícil 25 min. Si se agota, pierdes. También puedes rendirte. Sin el modo desafío no hay límite.

## Arquitectura

```
lib/
├── main.dart                 # Arranque, carga de persistencia y MaterialApp
├── models/                   # Datos puros: Difficulty, TileStyle, AppSettings, HighScore
├── logic/                    # Lógica de negocio sin UI
│   ├── puzzle_board.dart     # Tablero, barajado resoluble, movimientos, victoria
│   └── game_session.dart     # Estado de partida: movimientos, reloj, victoria/derrota
├── services/
│   └── storage_service.dart  # Único acceso a shared_preferences
├── controllers/              # ChangeNotifier compartidos + AppScope (InheritedWidget)
├── screens/                  # Splash, menú, juego, configuración, marcadores, instrucciones
├── widgets/                  # Pieza, tablero, botón de menú, overlay de fin, etc.
├── theme/                    # Tema claro/oscuro centralizado
└── utils/                    # Formato de tiempo y fecha
```

### Gestión de estado

- **setState** en `GameScreen`: el tablero, contador, reloj y overlay solo le importan a esa pantalla y cambian con cada interacción.
- **ChangeNotifier + InheritedWidget** (incluidos en Flutter, sin paquetes extra) para preferencias y récords, porque se comparten entre pantallas y el tema debe cambiar en toda la app al instante.
- **StatelessWidget** en pantallas estáticas (instrucciones, menú, marcadores, configuración; estas dos últimas se redibujan escuchando a su controlador).

### Dependencias

- `material.dart` (core).
- `shared_preferences` para persistencia local.
- Las animaciones usan las APIs nativas de Flutter (`AnimatedPositioned`, `AnimatedScale`, `FadeTransition`, etc.).

### Resolubilidad

Se baraja con Fisher-Yates y se valida:

- Ancho impar (3x3, 5x5): resoluble si el número de inversiones es par.
- Ancho par (4x4): resoluble si inversiones + fila del hueco contada desde abajo es impar.

Si no cumple, se vuelve a barajar. Está cubierto por pruebas en `test/puzzle_board_test.dart`.
