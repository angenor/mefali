import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import '../../roles/composants.dart';
import '../pilotage.dart';
import 'fiche_article.dart';
import 'mes_articles.dart';

/// Écran V2 · « Mes articles » — catalogue & stock
/// (`docs/design/png/V2-catalogue-stock.png`, vue 1a ; FR-045).
///
/// Recherche locale, compteur « N articles · M en rupture », badge PROMO avec
/// prix barré, ligne de rupture GRISÉE à bordure danger, section repliée des
/// articles retirés (remise sans ressaisie — FR-055). La bascule En
/// stock/Rupture en un geste arrive avec la story 5 (T039) ; le bandeau
/// « N clients seront prévenus » de la maquette appartient à VND-09 (hors
/// périmètre) et n'est PAS construit.
class EcranArticles extends ConsumerStatefulWidget {
  /// Crée l'écran.
  const EcranArticles({super.key});

  @override
  ConsumerState<EcranArticles> createState() => _EcranArticlesState();
}

class _EcranArticlesState extends ConsumerState<EcranArticles> {
  /// Saisie de recherche — état STRICTEMENT LOCAL (constitution XII).
  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pilotage = ref.watch(pilotageProvider);

    return pilotage.when(
      loading: () => const SqueletteListe(),
      error: (_, _) => MessageEtat(
        texte: l10n.proArticlesErreur,
        picto: Symbols.wifi_off,
        action: () => ref.read(pilotageProvider.notifier).recharger(),
        libelleAction: l10n.proErreurAction,
      ),
      data: (pilote) {
        if (pilote == null) {
          return MessageEtat(
            texte: l10n.proArticlesSansPrestataire,
            picto: Symbols.storefront,
          );
        }
        return _Catalogue(
          prestataireId: pilote.id,
          recherche: _recherche,
          onRechercheChangee: () => setState(() {}),
        );
      },
    );
  }
}

class _Catalogue extends ConsumerWidget {
  const _Catalogue({
    required this.prestataireId,
    required this.recherche,
    required this.onRechercheChangee,
  });

  final String prestataireId;
  final TextEditingController recherche;
  final VoidCallback onRechercheChangee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final articles = ref.watch(mesArticlesProvider(prestataireId));

    return articles.when(
      loading: () => const SqueletteListe(),
      error: (_, _) => MessageEtat(
        texte: l10n.proArticlesErreur,
        picto: Symbols.wifi_off,
        action: () =>
            ref.read(mesArticlesProvider(prestataireId).notifier).recharger(),
        libelleAction: l10n.proErreurAction,
      ),
      data: (tous) {
        final filtre = recherche.text.trim().toLowerCase();
        final visibles = tous
            .where((a) =>
                filtre.isEmpty || a.nom.toLowerCase().contains(filtre))
            .toList(growable: false);
        final auCatalogue =
            visibles.where((a) => !a.retire).toList(growable: false);
        final retires = visibles.where((a) => a.retire).toList(growable: false);
        final ruptures = auCatalogue.where((a) => !a.disponible).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: recherche,
              onChanged: (_) => onRechercheChangee(),
              decoration: InputDecoration(
                hintText: l10n.proArticlesRecherche,
                prefixIcon: const Icon(Symbols.search),
              ),
            ),
            const SizedBox(height: MefaliTokens.space2),
            Text(
              l10n.proArticlesCompte(auCatalogue.length, ruptures),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: MefaliTokens.textMuted),
            ),
            const SizedBox(height: MefaliTokens.space2),
            Expanded(
              child: auCatalogue.isEmpty && retires.isEmpty
                  ? MessageEtat(
                      texte: l10n.proArticlesVide,
                      picto: Symbols.description,
                    )
                  : ListView(
                      children: [
                        for (final article in auCatalogue) ...[
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              MefaliTokens.radiusCard,
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => FicheArticle(
                                  prestataireId: prestataireId,
                                  article: article,
                                ),
                              ),
                            ),
                            child: _LigneArticle(
                              article: article,
                              prestataireId: prestataireId,
                            ),
                          ),
                          const SizedBox(height: MefaliTokens.space2),
                        ],
                        if (retires.isNotEmpty)
                          ExpansionTile(
                            title: Text(
                              '${l10n.proArticlesRetires} (${retires.length})',
                            ),
                            children: [
                              for (final article in retires)
                                ListTile(
                                  title: Text(article.nom),
                                  subtitle: Text(formaterMontant(
                                    article.prixUnites,
                                    article.devise,
                                  )),
                                  trailing: TextButton(
                                    onPressed: () => ref
                                        .read(mesArticlesProvider(prestataireId)
                                            .notifier)
                                        .remettre(article.id),
                                    child: Text(l10n.proArticleRemettre),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: MefaliTokens.space3),
            // Bouton principal EN BAS (usage une main — règle d'or 3).
            BoutonPrincipal(
              libelle: l10n.proArticleAjouter,
              picto: Symbols.add,
              onPresse: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FicheArticle(prestataireId: prestataireId),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Ligne d'article de la maquette V2 1a : vignette + nom + prix (promo barrée),
/// GRISÉE à bordure danger quand l'article est en rupture.
class _LigneArticle extends ConsumerWidget {
  const _LigneArticle({required this.article, required this.prestataireId});

  final ArticleVendeur article;
  final String prestataireId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final enRupture = !article.disponible;

    final contenu = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: MefaliTokens.background,
            borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
          ),
          child: const Icon(Symbols.image, color: MefaliTokens.textMuted),
        ),
        const SizedBox(width: MefaliTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      article.nom,
                      style: textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (article.prixBarreUnites != null) ...[
                    const SizedBox(width: MefaliTokens.space2),
                    PuceStatut(
                      texte: l10n.proArticlesPromo,
                      ton: TonPuce.avertissement,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: MefaliTokens.space1),
              Row(
                children: [
                  Text(
                    formaterMontant(article.prixUnites, article.devise),
                    style: textTheme.bodyLarge,
                  ),
                  if (article.prixBarreUnites != null) ...[
                    const SizedBox(width: MefaliTokens.space2),
                    Text(
                      formaterMontant(
                        article.prixBarreUnites!,
                        article.devise,
                      ),
                      style: textTheme.labelSmall?.copyWith(
                        color: MefaliTokens.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: MefaliTokens.space2),
        // La BASCULE en un geste (84×44) arrive avec la story 5 (T039) —
        // d'ici là, l'état est annoncé par une puce.
        PuceStatut(
          texte: enRupture ? l10n.proArticleRupture : l10n.proArticleEnStock,
          ton: enRupture ? TonPuce.danger : TonPuce.succes,
        ),
      ],
    );

    // Rupture : ligne grisée + bordure danger (maquette V2 1a).
    if (enRupture) {
      return Container(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        decoration: BoxDecoration(
          color: MefaliTokens.surface,
          borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
          border: Border.all(color: MefaliTokens.danger),
        ),
        child: Opacity(opacity: 0.55, child: contenu),
      );
    }
    return CarteMefali(child: contenu);
  }
}
