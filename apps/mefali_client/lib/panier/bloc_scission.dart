/// Les deux blocs de la scission **acceptée** (cycle CMD 008, C3-3d).
///
/// La maquette ne montre que la PROPOSITION (`BandeauScission`, mefali_core) :
/// ce qui suit l'acceptation n'y figure pas, et ces blocs vivent donc dans
/// l'app, composés de widgets Material 3 thémés et des tokens
/// (`docs/design/tokens.md`, constitution XI) — jamais d'une structure recopiée
/// d'un export HTML.
///
/// Deux vérités qu'ils tiennent, et dont dépend l'honnêteté de l'écran :
///
/// - **N livraisons = N frais de déplacement.** Chaque tronçon porte SON devis
///   serveur, obtenu pour lui seul. Le total affiché est la somme des N, pas le
///   devis d'une tournée unique qui ne sera jamais facturée.
/// - **Un échec partiel se dit.** Une commande créée reste due ; celle qui a
///   manqué se reprend seule. Aucun des deux ne se devine.
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import 'etat_panier.dart';

/// Prévisualisation d'une scission ACCEPTÉE : une ligne (ou un récapitulatif
/// complet) par commande à venir, et l'avertissement des N frais.
class BlocScissionAcceptee extends StatelessWidget {
  /// Crée le bloc.
  const BlocScissionAcceptee({
    required this.troncons,
    this.detaille = false,
    this.onAnnuler,
    super.key,
  });

  /// Les N commandes acceptées, dans l'ordre proposé par le serveur.
  final List<TronconScission> troncons;

  /// Détaille chaque commande (Articles / Livraison / Total) au lieu de n'en
  /// donner que le total. Vrai sur le panier, où la décision se prend ; faux à
  /// l'adresse, où le détail des frais est déjà connu.
  final bool detaille;

  /// Revient à une seule commande. Absent, la scission n'est pas révocable
  /// depuis ce bloc.
  final VoidCallback? onAnnuler;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final theme = Theme.of(context);
    final devise = troncons.first.devis.devise;

    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space4),
      decoration: BoxDecoration(
        color: MefaliTokens.primaryTint,
        border: Border.all(color: MefaliTokens.primary),
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Symbols.call_split_rounded, color: MefaliTokens.primaryDark),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  l10n.panierScissionAcceptee(troncons.length),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: MefaliTokens.primaryDark,
                    fontWeight: MefaliTokens.weightSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space3),

          for (var i = 0; i < troncons.length; i++) ...[
            Text(
              l10n.panierScissionCommandeNumero(i + 1),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: MefaliTokens.weightSemiBold),
            ),
            const SizedBox(height: MefaliTokens.space1),
            if (detaille)
              // Le frais de déplacement de CETTE commande, chiffré par le
              // serveur pour ses vendeurs seuls : c'est la seule façon de
              // montrer les N frais au lieu de les annoncer (research R8).
              RecapitulatifFrais(
                devise: devise,
                libelleTotal: l10n.panierRecapTotal,
                totalUnites: troncons[i].devis.totalUnites,
                lignes: [
                  LigneRecapitulatif(
                    libelle: l10n.panierRecapArticles,
                    montantUnites: troncons[i].devis.montantArticlesUnites,
                  ),
                  LigneRecapitulatif(
                    libelle: l10n.panierRecapLivraison,
                    montantUnites: troncons[i].devis.prixLivraisonUnites,
                  ),
                  if (troncons[i].devis.effortUnites > 0)
                    LigneRecapitulatif(
                      libelle: l10n.panierRecapEffort,
                      montantUnites: troncons[i].devis.effortUnites,
                    ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.panierRecapTotal,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    formaterMontant(troncons[i].devis.totalUnites, devise),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: MefaliTokens.weightSemiBold),
                  ),
                ],
              ),
            const SizedBox(height: MefaliTokens.space3),
          ],

          Text(
            l10n.panierScissionAvertissement(troncons.length),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: MefaliTokens.textMuted),
          ),
          if (onAnnuler != null) ...[
            const SizedBox(height: MefaliTokens.space2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: onAnnuler,
                child: Text(l10n.panierScissionAnnuler),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Échec partiel d'une scission : ce qui a été créé, ce qui ne l'a pas été, et
/// la reprise du seul reste.
///
/// Placé AVANT les codes de remise : ce que le client doit savoir d'abord n'est
/// pas le code de la commande qui est passée, c'est qu'une autre ne l'est pas.
class BlocRepriseScission extends StatelessWidget {
  /// Crée le bloc de reprise.
  const BlocRepriseScission({
    required this.creees,
    required this.restants,
    this.onReprendre,
    super.key,
  });

  /// Nombre de commandes créées — elles sont valides et dues.
  final int creees;

  /// Nombre de commandes qui restent à créer.
  final int restants;

  /// Relance les seules commandes restantes, avec leurs clés d'idempotence
  /// inchangées : un doublon est impossible (R7).
  final VoidCallback? onReprendre;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space4),
      decoration: BoxDecoration(
        color: MefaliTokens.warningTint,
        border: Border.all(color: MefaliTokens.warning),
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Symbols.warning_rounded, color: MefaliTokens.warning),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  l10n.commandeScissionCreees(creees, creees + restants),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MefaliTokens.warning,
                    fontWeight: MefaliTokens.weightSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          Text(
            l10n.commandeScissionReste(restants),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: MefaliTokens.textMuted),
          ),
          const SizedBox(height: MefaliTokens.space3),
          FilledButton.icon(
            onPressed: onReprendre,
            icon: const Icon(Symbols.refresh_rounded),
            label: Text(l10n.commandeScissionReprendre),
          ),
        ],
      ),
    );
  }
}
