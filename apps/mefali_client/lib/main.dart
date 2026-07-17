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
  // rafraîchissement horaire) — l'inscription y lit la version du texte ARTCI
  // qu'elle affiche, pour la renvoyer telle quelle (FR-006). NON attendue ici :
  // bloquer le lancement sur un appel réseau ferait patienter devant un écran
  // vide, et la saisie du numéro n'en a pas besoin.
  final config = demarrerServiceConfig(urlApi: _urlApi);
  // Session partagée : jetons dans le stockage CHIFFRÉ du système, en-tête
  // Authorization posé sur le client GÉNÉRÉ (jamais d'appel artisanal).
  final session = construireSessionAuth(urlApi: _urlApi);
  runApp(MefaliClientApp(session: session, config: config));
}

/// Application cliente Mefali. Branche `MefaliTheme` et la localisation fr.
class MefaliClientApp extends StatelessWidget {
  /// Crée l'application cliente.
  const MefaliClientApp({super.key, required this.session, this.config});

  /// Session d'authentification de l'application.
  final SessionAuth session;

  /// Configuration de zone, en cours de chargement.
  final Future<ServiceConfig>? config;

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
        session: session,
        config: config,
        nomAppareil: 'Mefali',
        demarrage: const SplashScreen(),
        accueil: (_) => AccueilProvisoire(session: session),
      ),
    );
  }
}
