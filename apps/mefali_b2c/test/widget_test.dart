import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_b2c/app.dart';

void main() {
  testWidgets('MefaliB2cApp renders phone screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliB2cApp()));
    await tester.pumpAndSettle();

    // L'app demarre sur l'ecran de saisie du telephone (non authentifie).
    expect(find.text('Inscription'), findsOneWidget);
  });

  testWidgets('MefaliB2cApp applies mefali theme and title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliB2cApp()));
    await tester.pumpAndSettle();

    // Verifie que le MaterialApp est configure avec le bon titre.
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'mefali');
  });
}
