# 15-Puzzle Flutter

Rompecabezas deslizante (Sliding Puzzle) hecho en Flutter para el micro-proyecto de la Universidad Metropolitana.

**Demo:** https://danieldasilvas67-ux.github.io/puzzle15/ (PWA: se puede instalar desde el navegador y funciona sin conexión).

## Cómo correrlo

Requisitos: Flutter 3.47.x (canal stable).

```bash
flutter pub get
flutter run -d chrome      # o el dispositivo que prefieras
flutter test
```

El repositorio incluye la plataforma web. Para generar las demás (Android, iOS, escritorio):

```bash
flutter create . --platforms=android,ios,windows,macos,linux
```

`flutter create .` solo agrega los archivos que faltan: no sobrescribe `lib/`, `test/` ni `web/`.

### Versión web y PWA

```bash
flutter build web --release --no-web-resources-cdn --base-href /puzzle15/
```

En las versiones actuales de Flutter (3.47), el service worker que genera Flutter ya no guarda caché (solo se desregistra). Por eso la app trae su propio `web/sw.js`, registrado en `web/index.html`, y un `web/flutter_bootstrap.js` que arranca Flutter sin el service worker por defecto. `--no-web-resources-cdn` sirve CanvasKit desde el mismo sitio para que quede en caché y la app arranque sin conexión.

## Despliegue (CI/CD)

El workflow `.github/workflows/deploy.yml` corre en cada push y pull request a `main` y `develop`:

1. `dart format` (sin cambios pendientes), `flutter analyze --fatal-infos` y `flutter test`.
2. `flutter build web` con el `--base-href` del repositorio.
3. Verificación de la PWA:
   - `.github/scripts/verify_pwa_static.mjs`: manifest válido, íconos 192/512 reales, `index.html` con `lang="es"` y registro del service worker.
   - `.github/scripts/verify_pwa_offline.mjs`: abre el build en Chromium, comprueba que Chrome lo considera instalable y que vuelve a arrancar **sin conexión**.
4. Solo en `main`: publica `build/web` en GitHub Pages (Settings → Pages → Source: GitHub Actions).

### Flujo de ramas (gitflow)

- `main`: versión publicada. Cada push despliega.
- `develop`: integración.
- `feature/*`: una rama por cambio, fusionada en `develop` con `--no-ff`. `develop` llega a `main` mediante pull request.

## Funcionalidades

- **Splash** con animación de entrada (fade + escala) y botón "Saltar".
- **Menú principal** con fondo temático, botones grandes con animación de presión/hover y entrada escalonada. Se puede usar con teclado (Tab y Enter).
- **Configuración** (se guarda al instante y se refleja en toda la app):
  - Dificultad: Fácil 3x3, Medio 4x4, Difícil 5x5.
  - Tema: claro, oscuro o automático (sigue al sistema).
  - Estilo de piezas: Numérico clásico, Colorido, Retro y Minimalista.
  - Modo desafío (tiempo límite), animaciones y efectos de sonido activables.
- **Marcadores** por dificultad: mejor tiempo, menor número de movimientos, fecha de cada récord y victorias. Mensaje amigable si no hay datos y borrado con confirmación.
- **Cómo jugar**: reglas, cuándo se gana y cuándo se pierde.
- **Juego**:
  - Tablero aleatorio garantizado como resoluble (validación de paridad de inversiones).
  - Movimiento por toque/clic y por teclado (flechas o WASD); P o espacio para pausar, Esc para volver al menú.
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
│   └── storage_service.dart  # Único acceso a shared_preferences (tolerante a datos corruptos)
├── controllers/              # ChangeNotifier compartidos + AppScope (InheritedWidget)
├── screens/                  # Splash, menú, juego, configuración, marcadores, instrucciones
├── widgets/                  # Pieza, tablero, botón de menú, overlay de fin, etc.
├── theme/                    # Tema claro/oscuro centralizado
└── utils/                    # Formato de tiempo y fecha
web/
├── index.html                # Registro del service worker y pantalla de carga
├── flutter_bootstrap.js      # Arranque de Flutter sin el service worker por defecto
├── sw.js                     # Caché offline de la PWA
└── manifest.json             # Datos de instalación de la PWA
.github/                      # Workflow de CI/CD y scripts de verificación PWA
```

### Gestión de estado

- **setState** en `GameScreen`: el tablero, contador, reloj y overlay solo le importan a esa pantalla y cambian con cada interacción.
- **ChangeNotifier + InheritedWidget** (incluidos en Flutter, sin paquetes extra) para preferencias y récords, porque se comparten entre pantallas y el tema debe cambiar en toda la app al instante.
- **StatelessWidget** en pantallas estáticas (instrucciones, menú, marcadores, configuración; estas dos últimas se redibujan escuchando a su controlador).

### Persistencia

Si un valor guardado está corrupto o es de otro tipo, se usa el valor por defecto. Si el navegador bloquea el almacenamiento, la app funciona igual sin guardar (en memoria).

### Dependencias

- `material.dart` (core).
- `shared_preferences` para persistencia local.
- Las animaciones usan las APIs nativas de Flutter (`AnimatedPositioned`, `AnimatedScale`, `FadeTransition`, etc.).

### Resolubilidad

Se baraja con Fisher-Yates y se valida:

- Ancho impar (3x3, 5x5): resoluble si el número de inversiones es par.
- Ancho par (4x4): resoluble si inversiones + fila del hueco contada desde abajo es impar.

Si no cumple, se vuelve a barajar. Está cubierto por pruebas en `test/puzzle_board_test.dart`.
