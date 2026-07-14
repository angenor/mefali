import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import 'l10n/app_localizations.dart';
import 'splash_screen.dart';

/// URL du backend, surchargeable au build (`--dart-define=MEFALI_API_URL=...`).
const String _urlApi =
    String.fromEnvironment('MEFALI_API_URL', defaultValue: 'http://localhost:8080');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configuration produit distante démarrée en arrière-plan (cache immédiat +
  // rafraîchissement horaire) — aucun écran, ne bloque pas le lancement.
  unawaited(demarrerServiceConfig(urlApi: _urlApi));
  runApp(const MefaliClientApp());
}

/// Application cliente Mefali. Branche `MefaliTheme` et la localisation fr.
class MefaliClientApp extends StatelessWidget {
  /// Crée l'application cliente.
  const MefaliClientApp({super.key});

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
