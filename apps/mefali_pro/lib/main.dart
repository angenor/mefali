import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'l10n/app_localizations.dart';
import 'roles/routeur_roles.dart';
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
  // rafraîchissement horaire) — le dossier coursier y lit les véhicules
  // déclarables. Amorçage impératif au lancement, NON attendu (FR-024) : bloquer
  // le lancement sur un appel réseau ferait patienter devant un écran vide.
  unawaited(container.read(serviceConfigProvider));
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MefaliProApp(),
    ),
  );
}

/// Application pro Mefali. Branche `MefaliTheme` et la localisation fr.
class MefaliProApp extends StatelessWidget {
  /// Crée l'application pro.
  const MefaliProApp({super.key});

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
        nomAppareil: 'Mefali Pro',
        demarrage: const SplashScreen(),
        // Mefali Pro n'a pas d'accueil « connecté » : il a un accueil par RÔLE
        // VALIDÉ (FR-013). Le routeur des rôles ferme la porte.
        accueil: (_) => const RouteurRoles(),
      ),
    );
  }
}
