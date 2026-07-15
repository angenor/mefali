import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../theme/tokens.dart';
import 'parcours_auth.dart';
import 'session_auth.dart';

/// Racine de navigation des deux apps : démarrage → authentification → accueil.
///
/// Le stockage sécurisé est relu ICI (asynchrone, canal de plateforme), pas
/// avant `runApp` : bloquer le lancement sur une lecture de Keystore ferait
/// clignoter un écran blanc sur les Android d'entrée de gamme qui sont notre
/// cible. L'écran de démarrage tient l'attente.
class RacineAuth extends StatefulWidget {
  /// Crée la racine.
  const RacineAuth({
    super.key,
    required this.session,
    required this.demarrage,
    required this.accueil,
    required this.nomAppareil,
  });

  /// Session partagée de l'application.
  final SessionAuth session;

  /// Écran de démarrage, affiché tant que le stockage n'est pas relu.
  final Widget demarrage;

  /// Accueil, construit une fois la session ouverte.
  final WidgetBuilder accueil;

  /// Nom d'appareil déclaré à l'ouverture de session.
  final String nomAppareil;

  @override
  State<RacineAuth> createState() => _RacineAuthState();
}

class _RacineAuthState extends State<RacineAuth> {
  @override
  void initState() {
    super.initState();
    widget.session.charger();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        if (!widget.session.charge) return widget.demarrage;
        if (!widget.session.connecte) {
          return ParcoursAuth(
            session: widget.session,
            nomAppareil: widget.nomAppareil,
            // `onConnecte` est vide : `SessionAuth` est un ChangeNotifier, ce
            // ListenableBuilder rebâtit déjà sur l'ouverture. Router ici EN PLUS
            // pousserait deux fois vers l'accueil.
            onConnecte: () {},
          );
        }
        return widget.accueil(context);
      },
    );
  }
}

/// Accueil PROVISOIRE posé par le cycle CPT : il prouve que la session tient et
/// donne de quoi se déconnecter. Les vrais accueils (C1 côté client, routeur de
/// rôles côté Pro) appartiennent aux cycles CMD et CRS/VND.
class AccueilProvisoire extends StatelessWidget {
  /// Crée l'accueil provisoire.
  const AccueilProvisoire({super.key, required this.session});

  /// Session à fermer sur déconnexion.
  final SessionAuth session;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Symbols.check_circle,
                size: 72,
                fill: 1,
                color: MefaliTokens.success,
              ),
              const SizedBox(height: MefaliTokens.space3),
              Text(
                l10n.accueilProvisoireTitre,
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                height: MefaliTokens.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: session.fermer,
                  icon: const Icon(Symbols.logout),
                  label: Text(l10n.accueilProvisoireDeconnexion),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
