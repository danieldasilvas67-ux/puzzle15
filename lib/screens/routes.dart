import 'package:flutter/material.dart';

/// Transición de fundido + leve escala, usada para navegar entre pantallas.
Route<T> fadeRoute<T>(Widget page, {bool animate = true}) {
  return PageRouteBuilder<T>(
    transitionDuration:
        animate ? const Duration(milliseconds: 320) : Duration.zero,
    reverseTransitionDuration:
        animate ? const Duration(milliseconds: 250) : Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
