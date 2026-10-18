import 'package:flutter/widgets.dart';

import 'high_score_controller.dart';
import 'settings_controller.dart';

/// Expone los controladores a todo el árbol de widgets sin paquetes
/// externos. Los controladores no cambian de instancia, así que no hace
/// falta notificar; cada pantalla escucha sus cambios con ListenableBuilder.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.highScores,
    required super.child,
  });

  final SettingsController settings;
  final HighScoreController highScores;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No se encontró AppScope en el árbol');
    return scope!;
  }

  /// Versión sin suscripción, para usar en callbacks (onTap, timers).
  static AppScope read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No se encontró AppScope en el árbol');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      settings != oldWidget.settings || highScores != oldWidget.highScores;
}
