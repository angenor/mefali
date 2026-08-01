import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_localizations.dart';

part 'recu_commande.g.dart';

/// Le reçu d'une commande — ce qui a été commandé, ce qui en est sorti, et ce
/// qui reste dû (FR-070, FR-073).
///
/// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.
@riverpod
Future<RecuCommande> recuCommande(Ref ref, String commandeId) async {
  final reponse =
      await ref.read(clientSessionProvider).getPaiementsApi().recuCommande(
            id: commandeId,
          );
  return reponse.data!;
}

/// Écran « Reçu » — la pièce qu'Awa relit quand elle se demande pourquoi le
/// total a bougé, ou si elle doit encore quelque chose au coursier.
///
/// Réf. `docs/design/png/C4-suivi-commande.png` (cartes de montants, blocs
/// d'information). ⚠ **Écart assumé** : aucune planche de reçu n'existe
/// (plan.md, Complexity Tracking ligne 3) — la page emprunte ses motifs au
/// suivi voisin plutôt que d'inventer une identité visuelle.
class PageRecu extends ConsumerWidget {
  /// Crée la page de reçu d'une commande.
  const PageRecu({required this.commandeId, super.key});

  /// Commande dont on lit le reçu.
  final String commandeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = AppLocalizations.of(context)!;
    final l10n = MefaliCoreLocalizations.of(context)!;
    final recu = ref.watch(recuCommandeProvider(commandeId));

    return Scaffold(
      appBar: AppBar(title: Text(app.recuTitre)),
      body: recu.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (_, _) => Center(child: Text(l10n.commandeErreurInterne)),
        data: (r) => _Contenu(recu: r),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.recu});

  final RecuCommande recu;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final devise = recu.devise;

    return ListView(
      padding: const EdgeInsets.all(MefaliTokens.screenMargin),
      children: [
        // Les lignes, retirées comprises : le reçu EXPLIQUE pourquoi le total a
        // bougé, au lieu de le faire bouger en silence.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(MefaliTokens.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final ligne in recu.lignes) ...[
                  _Ligne(ligne: ligne, devise: devise),
                  if (ligne != recu.lignes.last)
                    const Divider(height: MefaliTokens.space3),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: MefaliTokens.space3),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(MefaliTokens.space3),
            child: Column(
              children: [
                _Montant(
                  libelle: app.recuArticles,
                  montant: formaterMontant(recu.montantArticlesUnites, devise),
                ),
                _Montant(
                  libelle: app.recuFraisLivraison,
                  montant: formaterMontant(recu.fraisLivraisonUnites, devise),
                ),
                // La retenue n'apparaît que si elle joue : un « 0 FCFA » ferait
                // chercher à Awa une remise qu'elle n'a pas eue.
                if (recu.retenueVendeurUnites > 0)
                  _Montant(
                    libelle: app.recuRetenueLivraisonOfferte,
                    montant:
                        '− ${formaterMontant(recu.retenueVendeurUnites, devise)}',
                  ),
                const Divider(height: MefaliTokens.space3),
                _Montant(
                  libelle: app.recuTotalDu,
                  montant: formaterMontant(recu.totalDuUnites, devise),
                  fort: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MefaliTokens.space3),

        // Le mode, et surtout : reste-t-il quelque chose à sortir de sa poche ?
        Card(
          child: Padding(
            padding: const EdgeInsets.all(MefaliTokens.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      recu.dejaRegle
                          ? Symbols.check_circle_rounded
                          : Symbols.payments_rounded,
                      size: 20,
                      color: recu.dejaRegle
                          ? MefaliTokens.success
                          : MefaliTokens.textMuted,
                    ),
                    const SizedBox(width: MefaliTokens.space2),
                    Expanded(
                      child: Text(
                        recu.modePaiement == 'cash'
                            ? app.recuModeCash
                            : app.recuModeMobileMoney,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MefaliTokens.space2),
                if (recu.dejaRegle)
                  Text(
                    app.recuDejaRegle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: MefaliTokens.success,
                      fontWeight: MefaliTokens.weightBold,
                    ),
                  )
                else
                  _Montant(
                    libelle: app.recuAremettreAuCoursier,
                    montant: formaterMontant(
                      recu.montantARemettreAuCoursierUnites,
                      devise,
                    ),
                    fort: true,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.ligne, required this.devise});

  final LigneRecu ligne;
  final String devise;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final retiree = ligne.statut == 'retiree';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${ligne.libelle} × ${ligne.quantite}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: retiree ? TextDecoration.lineThrough : null,
                  color: retiree ? MefaliTokens.textMuted : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (retiree)
                Text(
                  app.recuLigneRetiree,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: MefaliTokens.textMuted),
                ),
            ],
          ),
        ),
        const SizedBox(width: MefaliTokens.space2),
        Text(
          formaterMontant(ligne.sousTotalUnites, devise),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: retiree ? MefaliTokens.textMuted : null),
        ),
      ],
    );
  }
}

class _Montant extends StatelessWidget {
  const _Montant({
    required this.libelle,
    required this.montant,
    this.fort = false,
  });

  final String libelle;
  final String montant;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = fort
        ? theme.textTheme.titleMedium
            ?.copyWith(fontWeight: MefaliTokens.weightBold)
        : theme.textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MefaliTokens.space1),
      child: Row(
        children: [
          // Le libellé se tronque, jamais le chiffre.
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
