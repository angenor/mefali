import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_b2c/app.dart';
import 'package:mefali_b2c/features/profile/profile_screen.dart';
import 'package:mefali_core/mefali_core.dart';

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

  group('ProfileScreen', () {
    testWidgets('displays user name, phone, role, and logout button', (
      WidgetTester tester,
    ) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final n = AuthNotifier(AuthEndpoint(dio), dio);
              n.updateUser(
                const User(
                  id: '00000000-0000-0000-0000-000000000001',
                  phone: '+2250700000000',
                  name: 'Koffi',
                  role: UserRole.client,
                  status: UserStatus.active,
                ),
              );
              return n;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Koffi'), findsOneWidget);
      expect(find.text('+2250700000000'), findsOneWidget);
      expect(find.text('client'), findsOneWidget);
      expect(find.text('Deconnexion'), findsOneWidget);
    });

    testWidgets('shows avatar initial from user name', (
      WidgetTester tester,
    ) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final n = AuthNotifier(AuthEndpoint(dio), dio);
              n.updateUser(
                const User(
                  id: '00000000-0000-0000-0000-000000000001',
                  phone: '+2250700000000',
                  name: 'Koffi',
                  role: UserRole.client,
                  status: UserStatus.active,
                ),
              );
              return n;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
    });
  });
}
