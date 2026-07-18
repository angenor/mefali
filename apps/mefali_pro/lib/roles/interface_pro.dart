import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../l10n/app_localizations.dart';
import '../vendeur/interface_vendeur.dart';
import 'etat_roles.dart';
import 'libelles_roles.dart';
import 'pied_pro.dart';

/// Interface du rôle actif, et bascule vers l'autre rôle validé (FR-013).
///
/// La bascule n'apparaît QUE si le compte porte deux rôles validés — un
/// coursier seul ne doit pas voir un sélecteur à une case.
///
/// Le rôle VENDEUR est servi par l'espace du cycle 005 (`InterfaceVendeur` —
/// écrans V1/V2) ; le rôle coursier reste un placeholder jusqu'au cycle CRS
/// (K1..K5). Porte et routeur inchangés (FR-046).
class InterfacePro extends StatelessWidget {
  /// Crée l'interface du rôle actif.
  const InterfacePro({super.key, required this.etat});

  /// Rôles du compte connecté.
  final EtatRolesData etat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final valides = etat.rolesValides;
    final actif = etat.actif;

    // Défensif : ce widget n'est construit qu'avec au moins un rôle validé.
    if (actif == null) return const SizedBox.shrink();

    // L'espace vendeur du cycle 005 remplace le placeholder (FR-046).
    if (actif == RolePro.vendeur) {
      return InterfaceVendeur(etat: etat);
    }

    final (titre, aide) = (
      l10n.proInterfaceCoursierTitre,
      l10n.proInterfaceCoursierAide,
    );

    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (valides.length > 1) ...[
                BasculeRoles(valides: valides, actif: actif),
                const SizedBox(height: MefaliTokens.space4),
              ],
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pictoRole(actif),
                        size: 48,
                        color: MefaliTokens.textMuted,
                      ),
                      const SizedBox(height: MefaliTokens.space3),
                      Text(
                        aide,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: MefaliTokens.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MefaliTokens.space3),
              const PiedPro(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sélecteur d'interface entre rôles validés.
///
/// `SegmentedButton` M3 : la bascule est un choix entre deux vues, pas une
/// navigation — l'utilisateur ne quitte pas son écran et ne perd rien.
/// PUBLIC depuis le cycle 005 : l'espace vendeur (`InterfaceVendeur`) la rend
/// en tête, comportement STRICTEMENT inchangé (FR-046).
class BasculeRoles extends ConsumerWidget {
  /// Crée la bascule.
  const BasculeRoles({super.key, required this.valides, required this.actif});

  /// Rôles validés du compte (la bascule ne s'affiche qu'à partir de deux).
  final List<RolePro> valides;

  /// Rôle dont l'interface est affichée.
  final RolePro actif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.proBasculeSemantique,
      child: SizedBox(
        height: MefaliTokens.tapMin,
        child: SegmentedButton<RolePro>(
          segments: [
            for (final role in valides)
              ButtonSegment<RolePro>(
                value: role,
                label: Text(l10n.role(role)),
                icon: Icon(pictoRole(role)),
              ),
          ],
          selected: {actif},
          // Aucun appel réseau, aucun jeton touché : c'est ce qui rend la
          // bascule instantanée et « sans reconnexion » (SC-006).
          onSelectionChanged: (choix) =>
              ref.read(etatRolesProvider.notifier).basculer(choix.first),
          showSelectedIcon: false,
        ),
      ),
    );
  }
}

/// Attente du chargement des rôles — squelettes, jamais un spinner plein écran
/// (planche de style §4).
class ChargementPro extends StatelessWidget {
  /// Crée l'écran d'attente.
  const ChargementPro({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Squelette(hauteur: MefaliTokens.tapMin),
              SizedBox(height: MefaliTokens.space4),
              Squelette(hauteur: 96),
              SizedBox(height: MefaliTokens.space3),
              Squelette(hauteur: 96),
            ],
          ),
        ),
      ),
    );
  }
}

/// Échec de lecture des rôles : on le DIT, et on offre de réessayer
/// (règle d'or 5 — chaque écran gère son erreur réseau).
class ErreurPro extends ConsumerWidget {
  /// Crée l'écran d'erreur.
  const ErreurPro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Symbols.wifi_off,
                        size: 48,
                        color: MefaliTokens.textMuted,
                      ),
                      const SizedBox(height: MefaliTokens.space3),
                      Text(
                        l10n.proErreurTitre,
                        style: textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: MefaliTokens.space2),
                      Text(
                        l10n.proErreurAide,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: MefaliTokens.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MefaliTokens.space3),
              BoutonPrincipal(
                libelle: l10n.proErreurAction,
                picto: Symbols.refresh,
                onPresse: () => ref.read(etatRolesProvider.notifier).charger(),
              ),
              const SizedBox(height: MefaliTokens.space2),
              const PiedPro(),
            ],
          ),
        ),
      ),
    );
  }
}
