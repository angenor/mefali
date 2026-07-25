/// Récapitulatif « Articles / Livraison / Effort de préparation / Total » et
/// bandeau de proposition de scission (cycle CMD 008).
///
/// Réf. `docs/design/png/C3-panier-multi-vendeurs.png`, cadres **3a** et **3d**.
/// Widgets Material 3 thémés depuis `docs/design/tokens.md` (constitution XI).
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../format/montant.dart';
import '../theme/tokens.dart';

/// Une ligne du récapitulatif : un libellé, un montant, et son détail.
class LigneRecapitulatif {
  /// Crée une ligne de récapitulatif.
  const LigneRecapitulatif({
    required this.libelle,
    required this.montantUnites,
    this.detail,
  });

  /// Libellé i18n résolu (« Articles », « Livraison »…).
  final String libelle;

  /// Montant en unités mineures.
  final int montantUnites;

  /// Détail affiché en petit dessous (« Déplacement 200 + 2 arrêts +50 »).
  final String? detail;
}

/// Récapitulatif des frais, avec son total mis en avant (maquette C3-3a).
///
/// Le détail de chaque poste est affiché : un client qui voit « Livraison
/// 250 FCFA » sans savoir d'où ça sort ne fait pas confiance au prix.
class RecapitulatifFrais extends StatelessWidget {
  /// Crée le récapitulatif.
  const RecapitulatifFrais({
    required this.lignes,
    required this.libelleTotal,
    required this.totalUnites,
    required this.devise,
    this.totalEstime = false,
    super.key,
  });

  /// Postes du récapitulatif, dans l'ordre d'affichage.
  final List<LigneRecapitulatif> lignes;

  /// Libellé du total (« Total », ou « Total estimé » hors ligne).
  final String libelleTotal;

  /// Total en unités mineures.
  final int totalUnites;

  /// Code ISO 4217.
  final String devise;

  /// Hors ligne, le total est ESTIMÉ : l'app ne connaît pas les frais réels,
  /// et le dire est plus honnête que d'afficher un chiffre faux (C3-3c).
  final bool totalEstime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space4),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        border: Border.all(color: MefaliTokens.border),
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final ligne in lignes) ...[
            Row(
              children: [
                Expanded(
                  child: Text(ligne.libelle, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  formaterMontant(ligne.montantUnites, devise),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (ligne.detail != null)
              Padding(
                padding: const EdgeInsets.only(top: MefaliTokens.space1),
                child: Text(
                  ligne.detail!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: MefaliTokens.textMuted),
                ),
              ),
            const SizedBox(height: MefaliTokens.space3),
          ],
          const Divider(height: MefaliTokens.space4),
          Row(
            children: [
              Expanded(
                child: Text(
                  libelleTotal,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                formaterMontant(totalUnites, devise),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: MefaliTokens.weightBold,
                  color: totalEstime
                      ? MefaliTokens.textMuted
                      : MefaliTokens.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une commande telle qu'elle sortirait de la scission (prévisualisation).
class CommandeProposeeVue {
  /// Crée la vue d'une commande proposée.
  const CommandeProposeeVue({
    required this.libelle,
    required this.totalArticlesUnites,
    required this.nbArticles,
  });

  /// Libellé i18n résolu.
  final String libelle;

  /// Total des ARTICLES de cette commande.
  final int totalArticlesUnites;

  /// Nombre d'articles.
  final int nbArticles;
}

/// Bandeau de proposition de scission : la règle expliquée simplement, le
/// bouton d'action, et la **prévisualisation chiffrée** des commandes
/// résultantes (maquette C3-3d).
///
/// Le serveur ne scinde JAMAIS d'office (FR-010) : ce bandeau est une
/// proposition, et l'avertissement « deux commandes, deux frais de
/// déplacement » est affiché AVANT la décision, pas découvert après.
class BandeauScission extends StatelessWidget {
  /// Crée le bandeau de scission.
  const BandeauScission({
    required this.message,
    required this.libelleAction,
    required this.avertissementFrais,
    required this.commandesProposees,
    required this.devise,
    this.onScinder,
    super.key,
  });

  /// Message i18n résolu de la cause (mixage, ou éclatement).
  final String message;

  /// Libellé du bouton (« Scinder en 2 commandes »).
  final String libelleAction;

  /// « Deux commandes, deux frais de déplacement. »
  final String avertissementFrais;

  /// Prévisualisation des commandes résultantes.
  final List<CommandeProposeeVue> commandesProposees;

  /// Code ISO 4217.
  final String devise;

  /// Rappelé quand le client accepte la scission.
  final VoidCallback? onScinder;

  @override
  Widget build(BuildContext context) {
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
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MefaliTokens.warning,
                    fontWeight: MefaliTokens.weightSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space3),
          FilledButton.icon(
            onPressed: onScinder,
            icon: const Icon(Symbols.call_split_rounded),
            label: Text(libelleAction),
          ),
          const SizedBox(height: MefaliTokens.space3),
          for (final commande in commandesProposees)
            Padding(
              padding: const EdgeInsets.only(bottom: MefaliTokens.space2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      commande.libelle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    formaterMontant(commande.totalArticlesUnites, devise),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: MefaliTokens.weightSemiBold),
                  ),
                ],
              ),
            ),
          Text(
            avertissementFrais,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: MefaliTokens.textMuted),
          ),
        ],
      ),
    );
  }
}
