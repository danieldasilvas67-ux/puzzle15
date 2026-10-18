import 'package:flutter/material.dart';

/// Botón grande del menú con animación de presión (escala) y cambio de
/// color al pasar el cursor o pulsar.
class AnimatedMenuButton extends StatefulWidget {
  const AnimatedMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.subtitle,
    this.primary = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  State<AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<AnimatedMenuButton> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor =
        widget.primary ? scheme.primary : scheme.surfaceContainerHighest;
    final activeColor = widget.primary
        ? Color.lerp(scheme.primary, scheme.tertiary, 0.35)!
        : scheme.secondaryContainer;
    final foreground = widget.primary ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : (_hovered ? 1.02 : 1),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: (_pressed || _hovered) ? activeColor : baseColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        scheme.shadow.withValues(alpha: _pressed ? 0.05 : 0.15),
                    blurRadius: _pressed ? 4 : 12,
                    offset: Offset(0, _pressed ? 1 : 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: foreground, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: foreground.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
