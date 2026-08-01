/// Le bloc **« combien encaisser »**, partagé par les deux écrans qui le posent
/// (cycle PAY 011, US4 — FR-093, SC-012).
///
/// Réf. `docs/design/png/K4-confirmation-livraison.png` et
/// `docs/design/png/K3-course-active.png` (bandeau de livraison).
///
/// # Pourquoi UN widget et non deux
///
/// Le bandeau de course et l'écran de confirmation affichaient chacun leur
/// version. Sur une commande prépayée, la moindre divergence entre les deux se
/// traduit par un coursier qui lit « 0 » à un endroit et un montant à l'autre —
/// et qui réclame, dans le doute, ce qu'Awa a déjà payé. SC-012 exige
/// justement qu'aucune formulation ne laisse d'ambiguïté ; la seule façon d'en
/// être sûr est qu'il n'y ait qu'une formulation.
///
/// # Ce que le zéro ne dit pas
///
/// Un « 0 FCFA » seul est ambigu : est-ce une commande gratuite ? un bug ? un
/// montant pas encore chargé ? Le bloc n'affiche donc **pas** un montant nul,
/// il affiche une **phrase** — « Rien à encaisser », et pourquoi.
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';

/// Bloc du montant à encaisser chez le client.
class BlocMontantAEncaisser extends StatelessWidget {
  /// Crée le bloc.
  const BlocMontantAEncaisser({
    required this.montantUnites,
    required this.devise,
    required this.modePaiement,
    super.key,
  });

  /// Montant servi par le SERVEUR — jamais recalculé localement : il inclut
  /// les frais de livraison, que l'app ne connaît pas.
  final int montantUnites;

  /// Devise ISO 4217.
  final String devise;

  /// `cash` | `mobile_money`. C'est LUI qui décide de la formulation, et non
  /// le montant : un montant nul peut avoir plusieurs causes, un mode n'en a
  /// qu'une.
  final String modePaiement;

  /// Vrai si le client doit encore payer sur place.
  bool get _aEncaisser => modePaiement == 'cash';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    // Le prépayé n'est pas une alerte : c'est une bonne nouvelle. Il prend donc
    // la couleur neutre, pas le vert de l'encaissement — qui signalerait un
    // geste à faire alors qu'il n'y en a aucun.
    final accent = _aEncaisser ? MefaliTokens.success : MefaliTokens.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        border: Border.all(color: accent),
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _aEncaisser
                    ? Symbols.payments_rounded
                    : Symbols.check_circle_rounded,
                color: accent,
              ),
              const SizedBox(width: MefaliTokens.space2),
              Text(
                _aEncaisser ? l10n.payAEncaisser : l10n.payRienAEncaisser,
                style: textTheme.bodyMedium?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space1),
          if (_aEncaisser)
            Text(
              formaterMontant(montantUnites, devise),
              style: textTheme.displayMedium?.copyWith(
                color: MefaliTokens.success,
                fontWeight: MefaliTokens.weightBold,
              ),
            )
          else
            // Une PHRASE, pas un « 0 FCFA » : le zéro se lit comme un bug, la
            // phrase se lit comme un fait.
            Text(
              l10n.payDejaRegleParLeClient,
              style: textTheme.titleMedium,
            ),
        ],
      ),
    );
  }
}
