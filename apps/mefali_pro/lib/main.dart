import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import 'l10n/app_localizations.dart';
import 'splash_screen.dart';

void main() => runApp(const MefaliProApp());

/// Application pro Mefali. Branche `MefaliTheme` et la localisation fr.
class MefaliProApp extends StatelessWidget {
  /// Crée l'application pro.
  const MefaliProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: MefaliTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
