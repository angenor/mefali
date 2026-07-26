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

import 'bloc_scission.dart';
import 'etat_panier.dart';

/// Écran du panier : cartes vendeur, récapitulatif chiffré, bloc de scission,
/// et bandeau hors ligne.
class EcranPanier extends ConsumerWidget {
  /// Crée l'écran du panier.
  const EcranPanier({
    this.onContinuer,
    this.onScinder,
    this.onAnnulerScission,
    super.key,
  });

  /// Passage à l'écran adresse et paiement (C3-3a′).
  final VoidCallback? onContinuer;

  /// Acceptation de la proposition de scission (C3-3d).
  final VoidCallback? onScinder;

  /// Retour à une seule commande, après acceptation.
  final VoidCallback? onAnnulerScission;

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
                // décision qui commande, pas le détail. Elle disparaît une fois
                // acceptée : le bloc suivant prend sa place.
                if (devis?.scission != null && !panier.scissionAcceptee) ...[
                  BandeauScission(
                    message: _messageScission(l10n, devis!.scission!.cause),
                    libelleAction: l10n.panierScissionAction(
                      devis.scission!.commandesProposees.length,
                    ),
                    avertissementFrais: l10n.panierScissionAvertissement(
                      devis.scission!.commandesProposees.length,
                    ),
                    commandesProposees: [
                      for (var i = 0;
                          i < devis.scission!.commandesProposees.length;
                          i++)
                        CommandeProposeeVue(
                          // Le serveur rend une CLÉ générique
                          // (`panier.scission.par_vendeur`) : la rendre telle
                          // quelle afficherait la clé. Le rang, lui, suffit à
                          // désigner chaque commande, et c'est le même que
                          // celui des codes de remise après création.
                          libelle: l10n.panierScissionCommandeNumero(i + 1),
                          totalArticlesUnites: devis
                              .scission!.commandesProposees[i]
                              .totalArticlesUnites,
                          nbArticles: devis
                              .scission!.commandesProposees[i].articles.length,
                        ),
                    ],
                    devise: devis.devise,
                    onScinder: onScinder,
                  ),
                  const SizedBox(height: MefaliTokens.space4),
                ],

                // C3-3d, accepté — les N commandes chiffrées une par une, donc
                // les N frais de déplacement VISIBLES avant toute confirmation.
                if (panier.scissionAPresenter) ...[
                  BlocScissionAcceptee(
                    troncons: panier.troncons,
                    detaille: true,
                    onAnnuler: onAnnulerScission,
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

                // Récapitulatif « Articles / Livraison / Effort ». Effacé quand
                // plusieurs commandes sont en jeu : il ne connaît qu'UN frais de
                // déplacement, et son total ne serait facturé par personne.
                if (devis != null && !panier.scissionAPresenter)
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
