import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

/// Ton d'une [PuceStatut] — les 4 variantes de `.mf-chip` (tokens §Composants).
enum TonPuce {
  /// Neutre, contour seul : un état ni bon ni mauvais (« à collecter »).
  contour,

  /// Vert : ouvert, confirmé, validé.
  succes,

  /// Rouge : fermé, refusé, rompu.
  danger,

  /// Ambre : à surveiller, en attente, hors-ligne.
  avertissement,
}

/// Puce de statut : fond teinté, texte foncé (`.mf-chip`).
///
/// Le texte reste foncé sur teinte claire — jamais de texte clair sur fond
/// clair (règle absolue de la planche de style : AAA sur les statuts).
class PuceStatut extends StatelessWidget {
  /// Crée une puce de statut.
  const PuceStatut({super.key, required this.texte, this.ton = TonPuce.contour});

  /// Libellé affiché (déjà localisé).
  final String texte;

  /// Ton de la puce.
  final TonPuce ton;

  @override
  Widget build(BuildContext context) {
    final (fond, contour) = switch (ton) {
      TonPuce.contour => (MefaliTokens.surface, MefaliTokens.border),
      TonPuce.succes => (MefaliTokens.successTint, MefaliTokens.successTint),
      TonPuce.danger => (MefaliTokens.dangerTint, MefaliTokens.dangerTint),
      TonPuce.avertissement => (
          MefaliTokens.warningTint,
          MefaliTokens.warningTint,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MefaliTokens.space2,
        vertical: MefaliTokens.space1,
      ),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusChip),
        border: Border.all(color: contour),
      ),
      child: Text(
        texte,
        style: const TextStyle(
          fontSize: MefaliTokens.bodySize,
          color: MefaliTokens.text,
          fontWeight: MefaliTokens.weightMedium,
        ),
      ),
    );
  }
}

/// Carte de contenu : surface, rayon 16, contour, sans ombre (`.mf-card`).
class CarteMefali extends StatelessWidget {
  /// Crée une carte.
  const CarteMefali({super.key, required this.child});

  /// Contenu de la carte.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        border: Border.all(color: MefaliTokens.border),
      ),
      child: child,
    );
  }
}

// `Squelette` a déménagé dans mefali_core (src/theme/squelette.dart) : les deux
// apps en ont besoin, et c'est un composant de TOKEN, pas un composant de rôle.
