import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import 'l10n/app_localizations.dart';
import 'roles/routeur_roles.dart';
import 'splash_screen.dart';

/// URL du backend, surchargeable au build (`--dart-define=MEFALI_API_URL=...`).
const String _urlApi =
    String.fromEnvironment('MEFALI_API_URL', defaultValue: 'http://localhost:8080');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configuration produit distante démarrée en arrière-plan (cache immédiat +
  // rafraîchissement horaire) — le dossier coursier y lit les véhicules
  // déclarables (FR-015). NON attendue ici : bloquer le lancement sur un appel
  // réseau ferait patienter devant un écran vide, et rien avant le formulaire
  // n'en a besoin.
  final config = demarrerServiceConfig(urlApi: _urlApi);
  // Session partagée : jetons dans le stockage CHIFFRÉ du système, en-tête
  // Authorization posé sur le client GÉNÉRÉ (jamais d'appel artisanal).
  final session = construireSessionAuth(urlApi: _urlApi);
  runApp(MefaliProApp(session: session, config: config));
}

/// Application pro Mefali. Branche `MefaliTheme` et la localisation fr.
class MefaliProApp extends StatelessWidget {
  /// Crée l'application pro.
  const MefaliProApp({super.key, required this.session, this.config});

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
        nomAppareil: 'Mefali Pro',
        demarrage: const SplashScreen(),
        // Mefali Pro n'a pas d'accueil « connecté » : il a un accueil par RÔLE
        // VALIDÉ (FR-013). L'accueil provisoire de mefali_core reste celui de
        // l'app client, jusqu'au cycle CMD.
        accueil: (_) => RouteurRoles(session: session, config: config),
      ),
    );
  }
}
