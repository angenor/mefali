import 'dart:async';

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
  // rafraîchissement horaire) — aucun écran, ne bloque pas le lancement.
  unawaited(demarrerServiceConfig(urlApi: _urlApi));
  // Session partagée : jetons dans le stockage CHIFFRÉ du système, en-tête
  // Authorization posé sur le client GÉNÉRÉ (jamais d'appel artisanal).
  final session = construireSessionAuth(urlApi: _urlApi);
  runApp(MefaliProApp(session: session));
}

/// Application pro Mefali. Branche `MefaliTheme` et la localisation fr.
class MefaliProApp extends StatelessWidget {
  /// Crée l'application pro.
  const MefaliProApp({super.key, required this.session});

  /// Session d'authentification de l'application.
  final SessionAuth session;

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
        accueil: (_) => RouteurRoles(session: session),
      ),
    );
  }
}
