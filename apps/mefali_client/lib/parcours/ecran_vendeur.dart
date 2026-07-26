/// Fiche publique d'un vendeur — le seul endroit d'où un panier se compose
/// (cycle CMD 008, T067).
///
/// `GET /prestataires/{id}` : fiche + catalogue, **sans authentification** —
/// c'est le canal d'acquisition du produit (FR-027, exception VIII documentée
/// au cycle VND). La découverte des vendeurs (recherche, tri par distance et
/// fiabilité) appartient au module VND ; ici on ouvre une fiche PAR SON LIEN,
/// exactement comme la plaque et la page `mefali.com/v/{id}` y mènent.
///
/// Cet écran n'invente aucune règle de commande : il ajoute des lignes au
/// `panierProvider`, et c'est le devis serveur qui chiffre (research R8).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
// `LignePanier` masquée : le client généré en a une (le DTO de la demande de
// devis), l'app en a une autre (la ligne que la cliente compose). Ce sont deux
// choses différentes, et c'est la seconde qu'on manipule ici.
import 'package:mefali_api_client/mefali_api_client.dart' hide LignePanier;
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_localizations.dart';
import '../panier/etat_panier.dart';

part 'ecran_vendeur.g.dart';

/// La fiche publique d'un vendeur. `@riverpod` nu (autoDispose) : écran de
/// consultation, rien à faire survivre à sa fermeture.
@Riverpod(retry: pasDeRetry)
Future<FichePublique> ficheVendeur(Ref ref, String prestataireId) async {
  // Client SANS `Authorization` : la fiche est publique, et l'y envoyer
  // n'apporterait rien qu'un jeton de plus dans les journaux (FR-027).
  final reponse = await ref
      .read(clientConfigProvider)
      .getPrestatairesApi()
      .consulterPrestataire(id: prestataireId);
  return reponse.data!;
}

/// Écran de la fiche d'un vendeur : catalogue et ajout au panier.
class EcranVendeur extends ConsumerWidget {
  /// Crée l'écran pour un vendeur donné.
  const EcranVendeur({required this.prestataireId, this.onVoirPanier, super.key});

  /// Vendeur consulté.
  final String prestataireId;

  /// Ouverture du panier depuis la fiche.
  final VoidCallback? onVoirPanier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = AppLocalizations.of(context)!;
    final fiche = ref.watch(ficheVendeurProvider(prestataireId));
    final panier = ref.watch(panierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(fiche.value?.nom ?? app.accueilOuvrirVendeur),
      ),
      body: fiche.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (_, _) => Center(child: Text(app.vendeurIntrouvable)),
        data: (fiche) => _Catalogue(fiche: fiche),
      ),
      bottomNavigationBar: panier.estVide
          ? null
          : Padding(
              padding: const EdgeInsets.all(MefaliTokens.space4),
              child: FilledButton.icon(
                onPressed: onVoirPanier,
                icon: const Icon(Symbols.shopping_basket_rounded),
                label: Text(app.accueilVoirPanier(panier.nbArticles)),
              ),
            ),
    );
  }
}

class _Catalogue extends ConsumerWidget {
  const _Catalogue({required this.fiche});

  final FichePublique fiche;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = AppLocalizations.of(context)!;

    if (fiche.articles.isEmpty) {
      return Center(child: Text(app.vendeurCatalogueVide));
    }

    return ListView(
      padding: const EdgeInsets.all(MefaliTokens.screenMargin),
      children: [
        // FR-028 — « commandable » est une décision du SERVEUR (agrément,
        // horaires, bascule manuelle) : l'app l'affiche, elle ne la recalcule
        // pas. Le bouton reste actif : c'est le devis qui refusera, avec sa
        // raison, plutôt qu'un panier bloqué sans explication.
        if (!fiche.commandable) ...[
          BandeauHorsLigne(message: app.vendeurFerme),
          const SizedBox(height: MefaliTokens.space3),
        ],
        for (final article in fiche.articles)
          _LigneArticle(article: article, prestataireId: fiche.id, fiche: fiche),
      ],
    );
  }
}

class _LigneArticle extends ConsumerWidget {
  const _LigneArticle({
    required this.article,
    required this.prestataireId,
    required this.fiche,
  });

  final ArticlePublic article;
  final String prestataireId;
  final FichePublique fiche;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        title: Text(article.nom),
        subtitle: Text(
          article.disponible
              ? formaterMontant(article.prixUnites, article.devise)
              : '${formaterMontant(article.prixUnites, article.devise)} · '
                  '${app.vendeurArticleIndisponible}',
        ),
        trailing: FilledButton.tonal(
          onPressed:
              article.disponible ? () => _ajouter(context, ref, app) : null,
          child: Text(app.vendeurAjouterAuPanier),
        ),
      ),
    );
  }

  void _ajouter(BuildContext context, WidgetRef ref, AppLocalizations app) {
    final notifier = ref.read(panierProvider.notifier);
    // Le premier article fixe la zone et la catégorie du panier. Un second
    // vendeur d'une AUTRE catégorie ne bloque rien ici : c'est le devis qui
    // proposera la scission, avec ses deux commandes chiffrées (C3-3d).
    if (ref.read(panierProvider).estVide) {
      notifier.demarrer(
        zoneId: zoneBootstrapTiassale,
        categorieSlug: fiche.categorie,
      );
    }
    notifier.ajouter(
      LignePanier(
        prestataireId: prestataireId,
        articleId: article.id,
        quantite: 1,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(app.vendeurArticleAjoute(article.nom))),
    );
  }
}
