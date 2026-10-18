import 'package:flutter/material.dart';

import '../models/difficulty.dart';

/// Hoja inferior para elegir dificultad. Devuelve `null` si se cierra.
Future<Difficulty?> showDifficultyPicker(
  BuildContext context, {
  required Difficulty current,
}) {
  return showModalBottomSheet<Difficulty>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Elige la dificultad',
                  style: textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Se guardará como predeterminada. Puedes cambiarla en Configuración.',
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              for (final d in Difficulty.values)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(d.gridLabel)),
                    title: Text(d.label),
                    subtitle: Text(d.description),
                    trailing: d == current
                        ? const Icon(Icons.check_circle_rounded)
                        : null,
                    onTap: () => Navigator.of(context).pop(d),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
