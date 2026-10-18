import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15/screens/instructions_screen.dart';

void main() {
  testWidgets('La pantalla de instrucciones muestra las reglas',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InstructionsScreen()));

    expect(find.text('Cómo jugar'), findsOneWidget);
    expect(find.text('Objetivo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cuándo ganas'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cuándo ganas'), findsOneWidget);
  });
}
