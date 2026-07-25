/// Composants partagés du panier multi-vendeurs (cycle CMD 008).
///
/// Widgets Material 3 thémés depuis `docs/design/tokens.md` — jamais de
/// transposition DOM/CSS des exports HTML (constitution XI).
/// Réf. `docs/design/png/C3-panier-multi-vendeurs.png`, cadre **3a**.
///
/// Les textes sont fournis par l'appelant (clés i18n résolues côté écran) :
/// aucun de ces widgets ne contient de chaîne utilisateur en dur.
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../format/montant.dart';
import '../theme/tokens.dart';

/// Une ligne d'article telle que la carte vendeur l'affiche.
class LigneArticleVue {
  /// Crée la vue d'une ligne.
  const LigneArticleVue({
    required this.articleId,
    required this.nom,
    required this.quantite,
    required this.sousTotalUnites,
    required this.preference,
  });

  /// Article (clé de la ligne).
  final String articleId;

  /// Nom affiché.
  final String nom;

  /// Quantité commandée.
  final int quantite;

  /// Sous-total de la ligne (unités mineures).
  final int sousTotalUnites;

  /// `remplacer` | `appeler` | `retirer`.
  final String preference;
}

/// Un vendeur et ses lignes, tels que la carte les affiche.
class GroupeVendeurVue {
  /// Crée la vue d'un groupe.
  const GroupeVendeurVue({
    required this.prestataireId,
    required this.nom,
    required this.nbArticles,
    required this.sousTotalUnites,
    required this.lignes,
  });

  /// Vendeur.
  final String prestataireId;

  /// Nom affiché sur l'en-tête de la carte.
  final String nom;

  /// Nombre d'articles du groupe.
  final int nbArticles;

  /// Sous-total du vendeur (unités mineures).
  final int sousTotalUnites;

  /// Lignes du vendeur.
  final List<LigneArticleVue> lignes;
}

/// Libellés du sélecteur de préférence de substitution, résolus par l'appelant.
class LibellesPreference {
  /// Crée le jeu de libellés.
  const LibellesPreference({
    required this.titre,
    required this.remplacer,
    required this.appeler,
    required this.retirer,
  });

  /// « Si absent : » — titre du sélecteur.
  final String titre;

  /// Libellé de `remplacer`.
  final String remplacer;

  /// Libellé de `appeler` (le DÉFAUT produit).
  final String appeler;

  /// Libellé de `retirer`.
  final String retirer;

  /// Libellé d'une valeur de préférence.
  String pour(String preference) => switch (preference) {
        'remplacer' => remplacer,
        'retirer' => retirer,
        _ => appeler,
      };
}

/// Carte d'un vendeur : nom, nombre d'articles, sous-total, et ses lignes avec
/// leur sélecteur de préférence (maquette C3-3a).
///
/// La carte est **dépliable** : la maquette montre le premier vendeur ouvert et
/// les suivants repliés — un panier de trois étals reste lisible sur un écran
/// de téléphone.
class CarteVendeur extends StatelessWidget {
  /// Crée la carte d'un vendeur.
  const CarteVendeur({
    required this.groupe,
    required this.devise,
    required this.libellesPreference,
    required this.libelleArticles,
    this.onPreferenceChangee,
    this.deplieeParDefaut = false,
    super.key,
  });

  /// Le vendeur et ses lignes.
  final GroupeVendeurVue groupe;

  /// Code ISO 4217 des montants.
  final String devise;

  /// Libellés du sélecteur de préférence.
  final LibellesPreference libellesPreference;

  /// « 5 articles » — résolu par l'appelant (pluriel i18n).
  final String Function(int nbArticles) libelleArticles;

  /// Rappelé quand le client change la préférence d'une ligne.
  final void Function(String articleId, String preference)? onPreferenceChangee;

  /// Carte ouverte au premier rendu (le premier vendeur de la maquette).
  final bool deplieeParDefaut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: MefaliTokens.space3),
      child: Theme(
        // L'ExpansionTile de Material trace ses propres séparateurs : on les
        // efface pour retrouver la carte pleine de la maquette.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: deplieeParDefaut,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: MefaliTokens.space4,
            vertical: MefaliTokens.space1,
          ),
          childrenPadding: const EdgeInsets.only(
            left: MefaliTokens.space4,
            right: MefaliTokens.space4,
            bottom: MefaliTokens.space3,
          ),
          leading: const Icon(Symbols.storefront_rounded),
          title: Text(groupe.nom, style: theme.textTheme.titleMedium),
          subtitle: Text(
            libelleArticles(groupe.nbArticles),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: MefaliTokens.textMuted),
          ),
          trailing: Text(
            formaterMontant(groupe.sousTotalUnites, devise),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: MefaliTokens.weightSemiBold),
          ),
          children: [
            for (final ligne in groupe.lignes)
              _LigneArticle(
                ligne: ligne,
                devise: devise,
                libelles: libellesPreference,
                onPreferenceChangee: onPreferenceChangee,
              ),
          ],
        ),
      ),
    );
  }
}

class _LigneArticle extends StatelessWidget {
  const _LigneArticle({
    required this.ligne,
    required this.devise,
    required this.libelles,
    this.onPreferenceChangee,
  });

  final LigneArticleVue ligne;
  final String devise;
  final LibellesPreference libelles;
  final void Function(String articleId, String preference)? onPreferenceChangee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MefaliTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${ligne.nom} · ${ligne.quantite}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                formaterMontant(ligne.sousTotalUnites, devise),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: MefaliTokens.weightMedium),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          Row(
            children: [
              Text(
                libelles.titre,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: MefaliTokens.textMuted),
              ),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: SegmentedButton<String>(
                  showSelectedIcon: true,
                  segments: [
                    ButtonSegment(
                      value: 'remplacer',
                      label: Text(libelles.remplacer),
                    ),
                    ButtonSegment(
                      value: 'appeler',
                      label: Text(libelles.appeler),
                    ),
                    ButtonSegment(
                      value: 'retirer',
                      label: Text(libelles.retirer),
                    ),
                  ],
                  selected: {ligne.preference},
                  onSelectionChanged: onPreferenceChangee == null
                      ? null
                      : (choix) =>
                          onPreferenceChangee!(ligne.articleId, choix.first),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
