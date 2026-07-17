import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../adresses/liste_adresses.dart';
import '../appareils/ecran_appareils.dart';
import '../config/service_config.dart';
import '../theme/tokens.dart';
import 'parcours_auth.dart';
import 'session.dart';

/// Racine de navigation des deux apps : démarrage → authentification → accueil.
///
/// Le stockage sécurisé est relu ICI (asynchrone, canal de plateforme), pas
/// avant `runApp` : bloquer le lancement sur une lecture de Keystore ferait
/// clignoter un écran blanc sur les Android d'entrée de gamme qui sont notre
/// cible. L'écran de démarrage tient l'attente.
class RacineAuth extends ConsumerStatefulWidget {
  /// Crée la racine.
  const RacineAuth({
    super.key,
    required this.demarrage,
    required this.accueil,
    required this.nomAppareil,
  });

  /// Écran de démarrage, affiché tant que le stockage n'est pas relu.
  final Widget demarrage;

  /// Accueil, construit une fois la session ouverte.
  final WidgetBuilder accueil;

  /// Nom d'appareil déclaré à l'ouverture de session.
  final String nomAppareil;

  @override
  ConsumerState<RacineAuth> createState() => _RacineAuthState();
}

class _RacineAuthState extends ConsumerState<RacineAuth> {
  String? _versionConsentement;

  @override
  void initState() {
    super.initState();
    // Le chargement du stockage reste DÉCLENCHÉ ICI, impérativement (FR-002) :
    // le provider `session` a un `build()` qui ne charge rien.
    ref.read(sessionProvider.notifier).charger();
    _lireVersionConsentement();
  }

  /// Récupère la version du texte ARTCI dès que la config est là.
  ///
  /// INSTANTANÉ FIGÉ (FR-021) : lu par `ref.read`, JAMAIS `ref.watch` — c'est un
  /// instantané pris à l'entrée de l'écran, pas une valeur observée. Son absence
  /// ne bloque ni le démarrage ni la saisie du numéro : elle ne compte qu'à
  /// l'étape du consentement, qui la refusera explicitement si elle manque encore.
  Future<void> _lireVersionConsentement() async {
    try {
      final service = await ref.read(serviceConfigProvider);
      final version = service.courante?.consentementArtciVersion;
      if (mounted) setState(() => _versionConsentement = version);
    } catch (_) {
      // Config injoignable : le parcours le dira au moment du consentement.
    }
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(sessionProvider);
    if (!etat.charge) return widget.demarrage;
    if (!etat.connecte) {
      return ParcoursAuth(
        nomAppareil: widget.nomAppareil,
        versionConsentement: _versionConsentement,
        // `onConnecte` est vide : le `watch(sessionProvider)` ci-dessus rebâtit
        // déjà sur l'ouverture. Router ici EN PLUS pousserait deux fois.
        onConnecte: () {},
      );
    }
    return widget.accueil(context);
  }
}

/// Accueil PROVISOIRE posé par le cycle CPT : il prouve que la session tient et
/// donne de quoi se déconnecter. Les vrais accueils (C1 côté client, routeur de
/// rôles côté Pro) appartiennent aux cycles CMD et CRS/VND.
class AccueilProvisoire extends ConsumerWidget {
  /// Crée l'accueil provisoire.
  const AccueilProvisoire({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      builder: (_) => const ListeAdresses(),
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
                      builder: (_) => const EcranAppareils(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MefaliTokens.space3),
              SizedBox(
                height: MefaliTokens.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(sessionProvider.notifier).fermer(),
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
