import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_livreur/app.dart';

void main() {
  testWidgets('MefaliLivreurApp renders phone screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliLivreurApp()));
    await tester.pumpAndSettle();

    // L'app demarre sur l'ecran de saisie du telephone (non authentifie).
    expect(find.text('Inscription Livreur'), findsOneWidget);
  });

  testWidgets('MefaliLivreurApp applies correct title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliLivreurApp()));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'mefali Livreur');
  });
}
