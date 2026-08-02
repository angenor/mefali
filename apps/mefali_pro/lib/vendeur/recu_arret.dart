import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_localizations.dart';
import '../roles/composants.dart';

part 'recu_arret.g.dart';

/// Le reçu d'un arrêt **collecté** — les trois montants qui font le versement
/// du coursier au vendeur (FR-071).
///
/// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.
@riverpod
Future<RecuArret> recuArret(Ref ref, String arretId) async {
  final reponse =
      await ref.read(clientSessionProvider).getVendeurApi().recuArret(
            arretId: arretId,
          );
  return reponse.data!;
}

/// Écran « Reçu de collecte » — ce que le coursier a versé, et pourquoi ce
/// n'est pas le prix des articles quand le vendeur offre la livraison.
///
/// Réf. `docs/design/png/V3-commande-entrante.png` (structure de carte, blocs
/// de montants). ⚠ **Deux écarts assumés** :
///
/// 1. aucune planche de reçu n'existe (plan.md, Complexity Tracking) ;
/// 2. **aucun point d'entrée dans l'app** : la liste des commandes entrantes
///    relève de VAP-01, non construit (cadrage §11). L'écran s'ouvre par
///    `MaterialPageRoute` depuis l'appelant — aujourd'hui les tests, demain la
///    notification de collecte. Le livrer maintenant évite qu'un vendeur, le
///    jour où VAP arrive, n'ait aucun moyen de vérifier un versement contesté.
class EcranRecuArret extends ConsumerWidget {
  /// Crée l'écran pour un arrêt collecté.
  const EcranRecuArret({super.key, required this.arretId});

  /// Arrêt dont on affiche le reçu.
  final String arretId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recu = ref.watch(recuArretProvider(arretId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.payRecuVendeurTitre)),
      body: recu.when(
        loading: () => const SqueletteListe(),
        error: (_, _) => MessageEtat(
          texte: l10n.proBoutiqueErreur,
          picto: Symbols.wifi_off,
          action: () => ref.invalidate(recuArretProvider(arretId)),
          libelleAction: l10n.proErreurAction,
        ),
        data: (r) => _Contenu(recu: r),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.recu});

  final RecuArret recu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final devise = recu.devise;

    return ListView(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      children: [
        // Les lignes, retirées comprises : c'est ce qui explique pourquoi le
        // total a bougé, plutôt que de le faire bouger en silence.
        CarteMefali(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final ligne in recu.lignes) ...[
                _LigneRecu(ligne: ligne, devise: devise),
                if (ligne != recu.lignes.last)
                  const Divider(height: MefaliTokens.space3),
              ],
            ],
          ),
        ),
        const SizedBox(height: MefaliTokens.space3),

        // Les TROIS montants — identiques au franc près à ceux du reçu client
        // (FR-053, SC-009).
        CarteMefali(
          child: Column(
            children: [
              _LigneMontant(
                libelle: l10n.payRecuVendeurArticles,
                montant: formaterMontant(recu.montantArticlesUnites, devise),
              ),
              if (recu.retenueLivraisonOfferteUnites > 0)
                _LigneMontant(
                  libelle: l10n.payRecuVendeurRetenue,
                  montant:
                      '− ${formaterMontant(recu.retenueLivraisonOfferteUnites, devise)}',
                ),
              const Divider(height: MefaliTokens.space3),
              _LigneMontant(
                libelle: l10n.payRecuVendeurNetVerse,
                montant: formaterMontant(recu.netVerseUnites, devise),
                fort: true,
              ),
            ],
          ),
        ),

        // Le motif de la retenue, en clair. Sans lui, le vendeur voit un
        // versement plus bas que sa facture et croit à une erreur.
        if (recu.retenueLivraisonOfferteUnites > 0) ...[
          const SizedBox(height: MefaliTokens.space3),
          Row(
            children: [
              const Icon(Symbols.info, size: 20, color: MefaliTokens.textMuted),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  l10n.payRecuVendeurMotifRetenue,
                  style: textTheme.labelSmall
                      ?.copyWith(color: MefaliTokens.textMuted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LigneRecu extends StatelessWidget {
  const _LigneRecu({required this.ligne, required this.devise});

  final LigneRecu ligne;
  final String devise;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final retiree = ligne.statut == 'retiree';

    return Row(
      children: [
        Expanded(
          child: Text(
            '${ligne.libelle} — ${ligne.quantite}',
            style: textTheme.bodyMedium?.copyWith(
              decoration: retiree ? TextDecoration.lineThrough : null,
              color: retiree ? MefaliTokens.textMuted : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: MefaliTokens.space2),
        Text(
          formaterMontant(ligne.sousTotalUnites, devise),
          style: textTheme.bodyMedium?.copyWith(
            color: retiree ? MefaliTokens.textMuted : null,
          ),
        ),
      ],
    );
  }
}

class _LigneMontant extends StatelessWidget {
  const _LigneMontant({
    required this.libelle,
    required this.montant,
    this.fort = false,
  });

  final String libelle;
  final String montant;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = fort
        ? textTheme.titleMedium?.copyWith(fontWeight: MefaliTokens.weightBold)
        : textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MefaliTokens.space1),
      child: Row(
        children: [
          // Le libellé se tronque, jamais le chiffre : un montant à l'ellipse
          // ferait douter d'un versement.
          Expanded(
            child: Text(
              libelle,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: MefaliTokens.space2),
          Text(montant, style: style),
        ],
      ),
    );
  }
}
