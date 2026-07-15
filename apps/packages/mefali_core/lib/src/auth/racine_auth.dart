import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../adresses/liste_adresses.dart';
import '../appareils/ecran_appareils.dart';
import '../config/service_config.dart';
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
    this.config,
  });

  /// Session partagée de l'application.
  final SessionAuth session;

  /// Configuration de zone, en cours de chargement.
  ///
  /// Le parcours d'inscription y lit la version du texte ARTCI qu'il affiche,
  /// pour la renvoyer telle quelle (FR-006/FR-024). Non attendue au démarrage :
  /// l'écran de téléphone n'en a pas besoin, et la config sera là bien avant
  /// que l'utilisateur n'atteigne le consentement (il aura fallu un SMS).
  final Future<ServiceConfig>? config;

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
  String? _versionConsentement;

  @override
  void initState() {
    super.initState();
    widget.session.charger();
    _lireVersionConsentement();
  }

  /// Récupère la version du texte ARTCI dès que la config est là.
  ///
  /// En silence : son absence ne bloque ni le démarrage ni la saisie du
  /// numéro — elle ne compte qu'à l'étape du consentement, qui la refusera
  /// explicitement si elle manque encore.
  Future<void> _lireVersionConsentement() async {
    final config = widget.config;
    if (config == null) return;
    try {
      final service = await config;
      final version = service.courante?.consentementArtciVersion;
      if (mounted) setState(() => _versionConsentement = version);
    } catch (_) {
      // Config injoignable : le parcours le dira au moment du consentement.
    }
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
            versionConsentement: _versionConsentement,
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
              // Paramètres du cycle CPT : les appareils connectés (US2) et les
              // adresses enregistrées (US5).
              SizedBox(
                height: MefaliTokens.tapMin,
                child: ListTile(
                  leading: const Icon(Symbols.bookmark),
                  title: Text(l10n.parametresAdresses),
                  trailing: const Icon(Symbols.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListeAdresses(session: session),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MefaliTokens.tapMin,
                child: ListTile(
                  leading: const Icon(Symbols.devices),
                  title: Text(l10n.parametresAppareils),
                  trailing: const Icon(Symbols.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EcranAppareils(session: session),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MefaliTokens.space3),
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
