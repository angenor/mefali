import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import 'etat_course.dart';

/// La checklist d'achat d'un arrêt (K3-1a) : une ligne par article, sa coche,
/// et le bouton qui déclare l'indisponibilité.
///
/// Réf. `docs/design/png/K3-course-active.png` état 1a. La coche est **locale**
/// et ne part jamais au serveur (R11, FR-079) : c'est un aide-mémoire d'achat
/// dans une allée de marché, pas un fait métier.
///
/// Une ligne indisponible est **barrée en rouge avec sa raison** — Yao doit
/// savoir pourquoi il n'achète pas cet article, et le client ce qu'il ne
/// recevra pas.
class ChecklistArticles extends StatelessWidget {
  /// Crée la checklist d'un arrêt.
  const ChecklistArticles({
    super.key,
    required this.lignes,
    required this.devise,
    required this.onCocher,
    required this.onIndisponible,
  });

  /// Articles à acheter chez ce vendeur.
  final List<LigneChecklistVue> lignes;

  /// Devise ISO 4217.
  final String devise;

  /// Coche (ou décoche) un article — strictement local.
  final void Function(LigneChecklistVue ligne, bool cochee) onCocher;

  /// Déclare l'article indisponible : ouvre le chemin de substitution.
  final void Function(LigneChecklistVue ligne) onIndisponible;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final ligne in lignes)
            _LigneArticle(
              ligne: ligne,
              devise: devise,
              onCocher: (cochee) => onCocher(ligne, cochee),
              onIndisponible: () => onIndisponible(ligne),
            ),
        ],
      ),
    );
  }
}

class _LigneArticle extends StatelessWidget {
  const _LigneArticle({
    required this.ligne,
    required this.devise,
    required this.onCocher,
    required this.onIndisponible,
  });

  final LigneChecklistVue ligne;
  final String devise;
  final ValueChanged<bool> onCocher;
  final VoidCallback onIndisponible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final retiree = !ligne.aPayer;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MefaliTokens.space3,
        vertical: MefaliTokens.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cible de 48 dp — le minimum tactile des tokens, tenu même avec des
          // gants ou une main mouillée.
          SizedBox(
            width: MefaliTokens.tapMin,
            height: MefaliTokens.tapMin,
            child: retiree
                ? const Center(
                    child: Icon(Symbols.close_rounded,
                        color: MefaliTokens.danger, size: 24),
                  )
                : Checkbox.adaptive(
                    value: ligne.cochee,
                    onChanged: (v) => onCocher(v ?? false),
                  ),
          ),
          const SizedBox(width: MefaliTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ligne.libelle} — ${ligne.quantite}',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: MefaliTokens.weightSemiBold,
                    decoration: retiree ? TextDecoration.lineThrough : null,
                    color: retiree ? MefaliTokens.danger : null,
                  ),
                ),
                if (retiree)
                  Text(
                    _raison(l10n, ligne.preference),
                    style: textTheme.bodySmall
                        ?.copyWith(color: MefaliTokens.danger),
                  )
                else
                  Text(
                    formaterMontant(ligne.montantUnites, devise),
                    style: textTheme.bodySmall
                        ?.copyWith(color: MefaliTokens.textMuted),
                  ),
              ],
            ),
          ),
          if (!retiree) ...[
            const SizedBox(width: MefaliTokens.space2),
            // Compact et contraint : sur 360 dp — l'écran cible — la coche de
            // 48 dp, un libellé d'article un peu long et un bouton à taille
            // naturelle ne tiennent pas sur une ligne. Le bouton cède, pas le
            // libellé : c'est le nom de l'article que Yao cherche des yeux.
            Flexible(
              child: OutlinedButton.icon(
                onPressed: onIndisponible,
                icon: const Icon(Symbols.block_rounded, size: 18),
                label: Text(l10n.crsIndisponible, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MefaliTokens.space2,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// La raison affichée sous une ligne barrée dépend de ce que le CLIENT a
  /// choisi : c'est sa préférence qui décide de la suite, pas le coursier.
  static String _raison(AppLocalizations l10n, String preference) =>
      switch (preference) {
        'appeler' => l10n.crsLigneIndisponibleAppeler,
        'remplacer' => l10n.crsLigneIndisponibleRemplacer,
        _ => l10n.crsLigneIndisponibleRetiree,
      };
}

/// Le montant à payer à CE vendeur (K3-1a) : cadre danger, chiffre en display.
///
/// C'est le nombre le plus important de l'écran — celui que Yao sort de sa
/// poche. Il baisse **immédiatement** quand un article est déclaré
/// indisponible (FR-013, SC-002), sans attendre le serveur.
class MontantAPayer extends StatelessWidget {
  /// Crée le bloc de montant.
  const MontantAPayer({
    super.key,
    required this.nomVendeur,
    required this.montantUnites,
    required this.devise,
    this.articlesPris,
  });

  /// Nom du vendeur, affiché dans le libellé.
  final String nomVendeur;

  /// Montant à avancer (unités mineures).
  final int montantUnites;

  /// Devise ISO 4217.
  final String devise;

  /// Nombre d'articles effectivement pris — affiché seulement si une ligne a
  /// sauté, comme sur la maquette.
  final int? articlesPris;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final libelle = articlesPris == null
        ? l10n.crsPayezA(nomVendeur)
        : l10n.crsPayezAArticles(nomVendeur, articlesPris!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        border: Border.all(color: MefaliTokens.danger),
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            libelle,
            style: textTheme.bodyMedium?.copyWith(color: MefaliTokens.textMuted),
          ),
          const SizedBox(height: MefaliTokens.space1),
          Text(
            formaterMontant(montantUnites, devise),
            style: textTheme.displayMedium?.copyWith(
              color: MefaliTokens.danger,
              fontWeight: MefaliTokens.weightBold,
            ),
          ),
        ],
      ),
    );
  }
}
