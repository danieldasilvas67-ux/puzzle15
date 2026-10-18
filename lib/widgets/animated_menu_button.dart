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
  bool _focused = false;

  void _activate() {
    widget.onPressed();
  }

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

    final highlighted = _pressed || _hovered || _focused;

    // FocusableActionDetector hace que el botón reciba foco con Tab y se
    // active con Enter o Espacio, igual que los botones de Material.
    return Semantics(
      button: true,
      label: widget.label,
      hint: widget.subtitle,
      onTap: _activate,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() {
          _hovered = value;
          if (!value) _pressed = false;
        }),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _activate(),
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => _activate(),
          ),
        },
        child: GestureDetector(
          excludeFromSemantics: true,
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
                color: highlighted ? activeColor : baseColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _focused ? scheme.outline : Colors.transparent,
                  width: 2,
                ),
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
