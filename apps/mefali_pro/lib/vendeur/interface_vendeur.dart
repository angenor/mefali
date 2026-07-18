import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../l10n/app_localizations.dart';
import '../roles/etat_roles_data.dart';
import '../roles/interface_pro.dart';
import '../roles/pied_pro.dart';

/// Coquille de l'espace VENDEUR (cycle 005) : deux onglets — Boutique (V1) et
/// Articles (V2) — sous le sélecteur de rôles.
///
/// PAS d'onglet « Commandes » ni de compteur du jour : ils dépendent du module
/// commandes et sont HORS périmètre de ce cycle (spec, Hors périmètre). La
/// porte, le routeur, la bascule de rôles et le pied de page du cycle 003 ne
/// sont pas altérés (FR-046) : la bascule est rendue en tête, `PiedPro` reste
/// accessible en fin de contenu de l'onglet Boutique.
class InterfaceVendeur extends StatefulWidget {
  /// Crée l'espace vendeur.
  const InterfaceVendeur({super.key, required this.etat});

  /// Rôles du compte connecté (pour la bascule).
  final EtatRolesData etat;

  @override
  State<InterfaceVendeur> createState() => _InterfaceVendeurState();
}

class _InterfaceVendeurState extends State<InterfaceVendeur> {
  /// Onglet courant — état STRICTEMENT LOCAL (constitution XII : la sélection
  /// d'onglet est éphémère, jamais providerifiée).
  int _onglet = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final valides = widget.etat.rolesValides;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.proInterfaceVendeurTitre)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (valides.length > 1) ...[
                BasculeRoles(valides: valides, actif: RolePro.vendeur),
                const SizedBox(height: MefaliTokens.space3),
              ],
              Expanded(
                child: switch (_onglet) {
                  0 => const _OngletBoutique(),
                  _ => const _OngletArticles(),
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (index) => setState(() => _onglet = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Symbols.storefront),
            label: l10n.proOngletBoutique,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.description),
            label: l10n.proOngletArticles,
          ),
        ],
      ),
    );
  }
}

/// Onglet Boutique — l'écran V1 (statut de boutique) le remplace dans ce même
/// cycle ; le pied de page du cycle 003 reste accessible ici (FR-046).
class _OngletBoutique extends StatelessWidget {
  const _OngletBoutique();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.storefront,
                  size: 48,
                  color: MefaliTokens.textMuted,
                ),
                const SizedBox(height: MefaliTokens.space3),
                Text(
                  l10n.proInterfaceVendeurAide,
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
    );
  }
}

/// Onglet Articles — l'écran V2 (catalogue & stock) le remplace dans ce même
/// cycle.
class _OngletArticles extends StatelessWidget {
  const _OngletArticles();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.description,
            size: 48,
            color: MefaliTokens.textMuted,
          ),
          const SizedBox(height: MefaliTokens.space3),
          Text(
            l10n.proInterfaceVendeurAide,
            style:
                textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
