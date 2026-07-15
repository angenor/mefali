import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../l10n/app_localizations.dart';
import 'etat_roles.dart';
import 'libelles_roles.dart';
import 'pied_pro.dart';

/// Interface du rôle actif, et bascule vers l'autre rôle validé (FR-013).
///
/// La bascule n'apparaît QUE si le compte porte deux rôles validés — un
/// coursier seul ne doit pas voir un sélecteur à une case.
///
/// Les interfaces elles-mêmes sont des placeholders : les vrais écrans coursier
/// (K1..K5) et vendeur (V1..V3) sont les cibles des cycles CRS et VND. Ce cycle
/// ne livre que la porte et le routeur — construire les écrans ici sortirait du
/// périmètre (constitution IX).
class InterfacePro extends StatelessWidget {
  /// Crée l'interface du rôle actif.
  const InterfacePro({super.key, required this.etat});

  /// Rôles du compte connecté.
  final EtatRoles etat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final valides = etat.rolesValides;
    final actif = etat.actif;

    // Défensif : ce widget n'est construit qu'avec au moins un rôle validé.
    if (actif == null) return const SizedBox.shrink();

    final (titre, aide) = switch (actif) {
      RolePro.coursier => (
          l10n.proInterfaceCoursierTitre,
          l10n.proInterfaceCoursierAide,
        ),
      RolePro.vendeur => (
          l10n.proInterfaceVendeurTitre,
          l10n.proInterfaceVendeurAide,
        ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (valides.length > 1) ...[
                _Bascule(etat: etat, valides: valides, actif: actif),
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
              PiedPro(session: etat.session),
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
class _Bascule extends StatelessWidget {
  const _Bascule({required this.etat, required this.valides, required this.actif});

  final EtatRoles etat;
  final List<RolePro> valides;
  final RolePro actif;

  @override
  Widget build(BuildContext context) {
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
          onSelectionChanged: (choix) => etat.basculer(choix.first),
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
class ErreurPro extends StatelessWidget {
  /// Crée l'écran d'erreur.
  const ErreurPro({super.key, required this.etat});

  /// Rôles du compte connecté (pour relancer la lecture).
  final EtatRoles etat;

  @override
  Widget build(BuildContext context) {
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
                onPresse: etat.charger,
              ),
              const SizedBox(height: MefaliTokens.space2),
              PiedPro(session: etat.session),
            ],
          ),
        ),
      ),
    );
  }
}
