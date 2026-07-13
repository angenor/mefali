import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/splash_screen.dart';

Widget _app() => MaterialApp(
      theme: MefaliTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: const SplashScreen(),
    );

void main() {
  testWidgets('écran de démarrage pro : chaînes i18n fr + thème appliqué', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Mefali Pro'), findsOneWidget);
    expect(find.textContaining('Tiassalé'), findsOneWidget);
  });

  testWidgets('écran de démarrage pro : golden', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash.png'),
    );
  }, tags: 'golden');
}
