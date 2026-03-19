import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_livreur/app.dart';
import 'package:mefali_livreur/features/profile/profile_screen.dart';

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

  group('ProfileScreen', () {
    testWidgets('displays user info and KYC pending badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProfileScreen())),
      );
      ProviderScope.containerOf(tester.element(find.byType(ProfileScreen)))
          .read(authProvider.notifier)
          .updateUser(
            const User(
              id: '00000000-0000-0000-0000-000000000001',
              phone: '+2250700000000',
              name: 'Moussa',
              role: UserRole.driver,
              status: UserStatus.pendingKyc,
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('Moussa'), findsOneWidget);
      expect(find.text('+2250700000000'), findsOneWidget);
      expect(find.text('En attente KYC'), findsOneWidget);
      expect(find.text('Deconnexion'), findsOneWidget);
    });

    testWidgets('displays active KYC badge when user is active', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProfileScreen())),
      );
      ProviderScope.containerOf(tester.element(find.byType(ProfileScreen)))
          .read(authProvider.notifier)
          .updateUser(
            const User(
              id: '00000000-0000-0000-0000-000000000001',
              phone: '+2250700000000',
              name: 'Moussa',
              role: UserRole.driver,
              status: UserStatus.active,
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('Actif'), findsOneWidget);
      expect(find.text('En attente KYC'), findsNothing);
    });
  });
}
