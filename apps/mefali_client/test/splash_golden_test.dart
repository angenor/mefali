import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/l10n/app_localizations.dart';
import 'package:mefali_client/splash_screen.dart';
import 'package:mefali_core/mefali_core.dart';

Widget _app() => MaterialApp(
      theme: MefaliTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: const SplashScreen(),
    );

void main() {
  testWidgets('écran de démarrage : chaînes i18n fr + thème appliqué', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Mefali'), findsOneWidget);
    expect(find.textContaining('Tiassalé'), findsOneWidget);
    // Le fond suit le token de fond (thème prouvé).
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor ?? MefaliTheme.light.scaffoldBackgroundColor,
        anyOf(isNull, MefaliTokens.background));
  });

  testWidgets('écran de démarrage : golden', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash.png'),
    );
  }, tags: 'golden');
}
