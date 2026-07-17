import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'l10n/app_localizations.dart';
import 'splash_screen.dart';

/// URL du backend, surchargeable au build (`--dart-define=MEFALI_API_URL=...`).
/// Constante de compilation du POINT D'ENTRÉE (FR-012) : le cœur ne la lit jamais.
const String _urlApi =
    String.fromEnvironment('MEFALI_API_URL', defaultValue: 'http://localhost:8080');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La SEULE forme qui donne un handle sur le conteneur AVANT runApp (R10) :
  // retry NEUTRE sur la portée (FR-002), url d'API surchargée ici (FR-012).
  final container = ProviderContainer(
    retry: pasDeRetry,
    overrides: [urlApiProvider.overrideWithValue(_urlApi)],
  );
  // Configuration produit distante démarrée en arrière-plan (cache immédiat +
  // rafraîchissement horaire) — l'inscription y lit la version du texte ARTCI.
  // Amorçage impératif au lancement, NON attendu (FR-024) : bloquer le lancement
  // sur un appel réseau ferait patienter devant un écran vide.
  unawaited(container.read(serviceConfigProvider));
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MefaliClientApp(),
    ),
  );
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
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        // Les écrans canoniques (auth, adresses, appareils) portent leurs
        // propres clés fr dans mefali_core.
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      debugShowCheckedModeBanner: false,
      home: RacineAuth(
        nomAppareil: 'Mefali',
        demarrage: const SplashScreen(),
        accueil: (_) => const AccueilProvisoire(),
      ),
    );
  }
}
