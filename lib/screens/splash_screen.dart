import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/game_logo.dart';
import 'menu_screen.dart';
import 'routes.dart';

/// Pantalla de carga con animación de entrada (fade-in + escala).
/// Pasa al menú tras unos segundos o al pulsar "Saltar".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  late final Animation<double> _scale = Tween<double>(begin: 0.6, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2600), _goToMenu);
  }

  void _goToMenu() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _timer?.cancel();
    final animate = AppScope.read(context).settings.settings.animationsEnabled;
    Navigator.of(context)
        .pushReplacement(fadeRoute(const MenuScreen(), animate: animate));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundFor(scheme),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GameLogo(size: 120),
                        const SizedBox(height: 24),
                        Text(
                          '15-Puzzle Flutter',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rompecabezas deslizante',
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: TextButton.icon(
                  onPressed: _goToMenu,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Saltar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
