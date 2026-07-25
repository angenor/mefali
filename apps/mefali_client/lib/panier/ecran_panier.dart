/// Écran **panier multi-vendeurs** (CMD-01, US1).
///
/// Réf. `docs/design/png/C3-panier-multi-vendeurs.png` — cadres **3a** (normal),
/// **3c** (hors ligne) et **3d** (mixte restauration + courses).
///
/// Widgets Material 3 thémés par `mefali_core` depuis `docs/design/tokens.md` ;
/// aucune chaîne utilisateur en dur — tout passe par `MefaliCoreLocalizations`
/// (constitution VII et XI). L'état vient du provider GÉNÉRÉ `panierProvider`
/// (constitution XII).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import 'etat_panier.dart';

/// Écran du panier : cartes vendeur, récapitulatif chiffré, bloc de scission,
/// et bandeau hors ligne.
class EcranPanier extends ConsumerWidget {
  /// Crée l'écran du panier.
  const EcranPanier({this.onContinuer, this.onScinder, super.key});

  /// Passage à l'écran adresse et paiement (C3-3a′).
  final VoidCallback? onContinuer;

  /// Acceptation de la proposition de scission (C3-3d).
  final VoidCallback? onScinder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final panier = ref.watch(panierProvider);
    final devis = panier.devis;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.panierTitre),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MefaliTokens.space4),
            child: Center(
              child: Text(
                '${panier.nbArticles} · ${panier.nbVendeurs}',
                semanticsLabel:
                    '${panier.nbArticles} articles, ${panier.nbVendeurs} vendeurs',
              ),
            ),
          ),
        ],
      ),
      body: panier.estVide
          ? Center(child: Text(l10n.panierVide))
          : ListView(
              padding: const EdgeInsets.all(MefaliTokens.space4),
              children: [
                // C3-3c — hors connexion : le panier reste composable, et
                // l'écran le DIT plutôt que d'afficher des montants faux.
                if (panier.horsLigne) ...[
                  BandeauHorsLigne(message: l10n.panierHorsLigne),
                  const SizedBox(height: MefaliTokens.space2),
                  Text(l10n.panierHorsLigneAide),
                  const SizedBox(height: MefaliTokens.space4),
                ],

                // C3-3d — proposition de scission, AVANT les cartes : c'est la
                // décision qui commande, pas le détail.
                if (devis?.scission != null) ...[
                  BandeauScission(
                    message: _messageScission(l10n, devis!.scission!.cause),
                    libelleAction: l10n.panierScissionAction,
                    avertissementFrais: l10n.panierScissionAvertissement,
                    commandesProposees: devis.scission!.commandesProposees,
                    devise: devis.devise,
                    onScinder: onScinder,
                  ),
                  const SizedBox(height: MefaliTokens.space4),
                ],

                // C3-3a — une carte par vendeur, la première dépliée.
                if (devis != null)
                  for (var i = 0; i < devis.groupes.length; i++)
                    CarteVendeur(
                      groupe: devis.groupes[i],
                      devise: devis.devise,
                      deplieeParDefaut: i == 0,
                      libelleArticles: (n) => '$n',
                      libellesPreference: LibellesPreference(
                        titre: l10n.panierPreferenceTitre,
                        remplacer: l10n.panierPreferenceRemplacer,
                        appeler: l10n.panierPreferenceAppeler,
                        retirer: l10n.panierPreferenceRetirer,
                      ),
                      onPreferenceChangee: (articleId, preference) => ref
                          .read(panierProvider.notifier)
                          .changerPreference(articleId, preference),
                    ),

                const SizedBox(height: MefaliTokens.space3),

                // Récapitulatif « Articles / Livraison / Effort ».
                if (devis != null)
                  RecapitulatifFrais(
                    devise: devis.devise,
                    totalEstime: panier.horsLigne,
                    libelleTotal: panier.horsLigne
                        ? l10n.panierTotalEstime
                        : l10n.panierRecapTotal,
                    totalUnites: devis.totalUnites,
                    lignes: [
                      LigneRecapitulatif(
                        libelle: l10n.panierRecapArticles,
                        montantUnites: devis.montantArticlesUnites,
                      ),
                      LigneRecapitulatif(
                        libelle: l10n.panierRecapLivraison,
                        montantUnites: devis.prixLivraisonUnites,
                      ),
                      // L'effort n'apparaît que s'il y en a : une ligne à zéro
                      // n'explique rien et alourdit l'écran.
                      if (devis.effortUnites > 0)
                        LigneRecapitulatif(
                          libelle: l10n.panierRecapEffort,
                          montantUnites: devis.effortUnites,
                        ),
                    ],
                  ),
              ],
            ),
      bottomNavigationBar: panier.estVide
          ? null
          : Padding(
              padding: const EdgeInsets.all(MefaliTokens.space4),
              child: FilledButton.icon(
                // Hors ligne, on n'engage rien : la commande partira au retour
                // du réseau, en UNE action de file (C3-3c).
                onPressed: panier.horsLigne ? null : onContinuer,
                icon: const Icon(Symbols.arrow_forward_rounded),
                label: Text(l10n.panierCommander),
              ),
            ),
    );
  }

  /// Résout la clé i18n de la cause de scission. Les deux causes ont le même
  /// écran mais pas le même message : le client doit comprendre CE QUI se passe.
  String _messageScission(MefaliCoreLocalizations l10n, String cause) =>
      switch (cause) {
        'plafond_eclatement' => l10n.panierScissionPlafondEclatement,
        _ => l10n.panierScissionCategorieNonMixable,
      };
}
