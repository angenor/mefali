/// État du panier client — porteur de PROCESSUS (cycle CMD 008, US1).
///
/// Moule **`Notifier`** de la constitution XII : le panier n'est pas un
/// chargement, c'est un objet que le client construit au fil de ses gestes.
/// L'uniformiser derrière un `AsyncNotifier` détruirait cette sémantique — un
/// panier n'a pas d'état « en cours de chargement », il a un contenu.
///
/// `keepAlive` : le panier survit à la navigation entre la fiche vendeur et le
/// panier lui-même. Sans cela, revenir en arrière le viderait.
library;

import 'package:flutter/foundation.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'etat_panier.g.dart';

/// Une ligne du panier, telle que le client l'a composée.
@immutable
class LignePanier {
  /// Crée une ligne de panier.
  const LignePanier({
    required this.prestataireId,
    required this.articleId,
    required this.quantite,
    this.preference = 'appeler',
  });

  /// Vendeur.
  final String prestataireId;

  /// Article.
  final String articleId;

  /// Quantité (> 0).
  final int quantite;

  /// `remplacer` | `appeler` | `retirer`. Défaut produit : « m'appeler ».
  final String preference;

  /// Copie avec une préférence différente.
  LignePanier avecPreference(String preference) => LignePanier(
        prestataireId: prestataireId,
        articleId: articleId,
        quantite: quantite,
        preference: preference,
      );

  /// Corps JSON attendu par `POST /paniers/devis` et `POST /commandes`.
  Map<String, Object?> versJson() => {
        'prestataire_id': prestataireId,
        'article_id': articleId,
        'quantite': quantite,
        'preference': preference,
      };

  /// Relit une ligne depuis le brouillon local.
  static LignePanier depuisJson(Map<String, Object?> json) => LignePanier(
        prestataireId: json['prestataire_id']! as String,
        articleId: json['article_id']! as String,
        quantite: json['quantite']! as int,
        preference: (json['preference'] as String?) ?? 'appeler',
      );
}

/// Contenu du panier + le dernier devis serveur connu.
///
/// Classe IMMUABLE volontairement SANS `operator ==` : deux paniers au même
/// contenu restent deux valeurs distinctes, et une réémission ne doit jamais
/// être avalée (même raison qu'`EtatSession`, cycle 004).
@immutable
class EtatPanier {
  /// Crée un état de panier.
  const EtatPanier({
    required this.zoneId,
    required this.categorieSlug,
    required this.lignes,
    this.devis,
    this.horsLigne = false,
  });

  /// Panier vide d'une zone et d'une catégorie.
  const EtatPanier.vide({required this.zoneId, required this.categorieSlug})
      : lignes = const [],
        devis = null,
        horsLigne = false;

  /// Zone de la commande.
  final String zoneId;

  /// Catégorie de service en cours de composition.
  final String categorieSlug;

  /// Lignes composées, dans l'ordre d'ajout.
  final List<LignePanier> lignes;

  /// Dernier devis serveur (`null` tant qu'aucun n'a été obtenu, ou hors ligne).
  final DevisPanierVue? devis;

  /// Le dernier recalcul a échoué faute de réseau : les montants affichés sont
  /// ESTIMÉS, et l'écran doit le dire (maquette C3-3c).
  final bool horsLigne;

  /// Le panier ne contient rien.
  bool get estVide => lignes.isEmpty;

  /// Nombre total d'articles (quantités cumulées).
  int get nbArticles => lignes.fold(0, (n, l) => n + l.quantite);

  /// Nombre de vendeurs distincts.
  int get nbVendeurs =>
      lignes.map((l) => l.prestataireId).toSet().length;

  /// Total des ARTICLES estimé localement — utilisé HORS LIGNE seulement, quand
  /// aucun devis serveur n'est disponible. Les frais, eux, ne s'estiment pas :
  /// ils sortent du moteur tarifaire, jamais de l'app (research R8).
  int totalArticlesEstime(Map<String, int> prixParArticle) => lignes.fold(
        0,
        (total, l) => total + (prixParArticle[l.articleId] ?? 0) * l.quantite,
      );

  /// Copie avec de nouvelles lignes.
  EtatPanier avecLignes(List<LignePanier> lignes) => EtatPanier(
        zoneId: zoneId,
        categorieSlug: categorieSlug,
        lignes: lignes,
        devis: devis,
        horsLigne: horsLigne,
      );

  /// Copie avec un nouveau devis serveur (remet le panier « en ligne »).
  EtatPanier avecDevis(DevisPanierVue devis) => EtatPanier(
        zoneId: zoneId,
        categorieSlug: categorieSlug,
        lignes: lignes,
        devis: devis,
        horsLigne: false,
      );

  /// Copie marquée hors ligne : le devis connu est CONSERVÉ mais ne fait plus
  /// autorité — le total affiché devient « estimé ».
  EtatPanier marqueHorsLigne() => EtatPanier(
        zoneId: zoneId,
        categorieSlug: categorieSlug,
        lignes: lignes,
        devis: devis,
        horsLigne: true,
      );
}

/// Le devis serveur, réduit à ce que l'écran affiche.
@immutable
class DevisPanierVue {
  /// Crée la vue d'un devis.
  const DevisPanierVue({
    required this.groupes,
    required this.montantArticlesUnites,
    required this.prixLivraisonUnites,
    required this.effortUnites,
    required this.totalUnites,
    required this.devise,
    required this.cashAutorise,
    required this.plafondUnites,
    this.motifCashCle,
    this.scission,
  });

  /// Regroupement par vendeur, tel que le serveur l'a rendu.
  final List<GroupeVendeurVue> groupes;

  /// Montant des articles (unités mineures).
  final int montantArticlesUnites;

  /// Prix client de la livraison.
  final int prixLivraisonUnites;

  /// Total de la grille d'effort (paliers + attente + arrêts).
  final int effortUnites;

  /// Total à payer.
  final int totalUnites;

  /// Code ISO 4217.
  final String devise;

  /// Le paiement en espèces est possible.
  final bool cashAutorise;

  /// Plafond appliqué.
  final int plafondUnites;

  /// Clé i18n de la raison du refus du cash (`null` s'il est autorisé).
  final String? motifCashCle;

  /// Proposition de scission, ou `null`.
  final ScissionVue? scission;

  /// Construit la vue depuis le corps JSON de `POST /paniers/devis`.
  factory DevisPanierVue.depuisJson(Map<String, Object?> json) {
    final devis = json['devis']! as Map<String, Object?>;
    final composantes = devis['composantes']! as Map<String, Object?>;
    final paiement = json['paiement']! as Map<String, Object?>;
    final scission = json['scission'] as Map<String, Object?>?;
    return DevisPanierVue(
      groupes: [
        for (final g in json['groupes']! as List<Object?>)
          _groupeDepuisJson(g! as Map<String, Object?>),
      ],
      montantArticlesUnites: json['montant_articles_unites']! as int,
      prixLivraisonUnites: devis['prix_client_unites']! as int,
      effortUnites: (composantes['effort_paliers']! as int) +
          (composantes['effort_attente']! as int) +
          (composantes['effort_arrets']! as int),
      totalUnites: json['total_unites']! as int,
      devise: json['devise']! as String,
      cashAutorise: paiement['cash_autorise']! as bool,
      plafondUnites: paiement['plafond_unites']! as int,
      motifCashCle: paiement['motif_cle'] as String?,
      scission: scission == null ? null : ScissionVue.depuisJson(scission),
    );
  }
}

GroupeVendeurVue _groupeDepuisJson(Map<String, Object?> json) =>
    GroupeVendeurVue(
      prestataireId: json['prestataire_id']! as String,
      nom: json['nom']! as String,
      nbArticles: json['nb_articles']! as int,
      sousTotalUnites: json['sous_total_unites']! as int,
      lignes: [
        for (final l in json['lignes']! as List<Object?>)
          _ligneDepuisJson(l! as Map<String, Object?>),
      ],
    );

LigneArticleVue _ligneDepuisJson(Map<String, Object?> json) => LigneArticleVue(
      articleId: json['article_id']! as String,
      nom: json['nom']! as String,
      quantite: json['quantite']! as int,
      sousTotalUnites: json['sous_total_unites']! as int,
      preference: json['preference']! as String,
    );

/// Proposition de scission, réduite à ce que l'écran affiche (C3-3d).
@immutable
class ScissionVue {
  /// Crée la vue d'une proposition.
  const ScissionVue({
    required this.cause,
    required this.messageCle,
    required this.commandesProposees,
  });

  /// `categorie_non_mixable` | `plafond_eclatement`.
  final String cause;

  /// Clé i18n du message.
  final String messageCle;

  /// Prévisualisation chiffrée.
  final List<CommandeProposeeVue> commandesProposees;

  /// Construit la vue depuis le bloc `scission` du devis.
  factory ScissionVue.depuisJson(Map<String, Object?> json) => ScissionVue(
        cause: json['cause']! as String,
        messageCle: json['message_cle']! as String,
        commandesProposees: [
          for (final c in json['commandes_proposees']! as List<Object?>)
            _commandeProposeeDepuisJson(c! as Map<String, Object?>),
        ],
      );
}

CommandeProposeeVue _commandeProposeeDepuisJson(Map<String, Object?> json) {
  final articles = json['articles']! as List<Object?>;
  return CommandeProposeeVue(
    libelle: json['libelle_cle']! as String,
    totalArticlesUnites: json['total_articles_unites']! as int,
    nbArticles: articles.length,
  );
}

/// Porteur du panier en cours de composition.
///
/// `keepAlive` explicite (constitution XII) : le panier traverse la navigation.
@Riverpod(keepAlive: true)
class Panier extends _$Panier {
  @override
  EtatPanier build() =>
      const EtatPanier.vide(zoneId: '', categorieSlug: '');

  /// Démarre (ou redémarre) un panier dans une zone et une catégorie.
  void demarrer({required String zoneId, required String categorieSlug}) {
    state = EtatPanier.vide(zoneId: zoneId, categorieSlug: categorieSlug);
  }

  /// Ajoute une ligne, ou cumule la quantité si l'article y est déjà.
  void ajouter(LignePanier ligne) {
    final lignes = [...state.lignes];
    final index = lignes.indexWhere((l) => l.articleId == ligne.articleId);
    if (index >= 0) {
      final existante = lignes[index];
      lignes[index] = LignePanier(
        prestataireId: existante.prestataireId,
        articleId: existante.articleId,
        quantite: existante.quantite + ligne.quantite,
        preference: existante.preference,
      );
    } else {
      lignes.add(ligne);
    }
    state = state.avecLignes(lignes);
  }

  /// Retire un article du panier.
  void retirer(String articleId) {
    state = state
        .avecLignes(state.lignes.where((l) => l.articleId != articleId).toList());
  }

  /// Change la préférence de substitution d'un article (CMD-01).
  void changerPreference(String articleId, String preference) {
    state = state.avecLignes([
      for (final l in state.lignes)
        if (l.articleId == articleId) l.avecPreference(preference) else l,
    ]);
  }

  /// Enregistre le devis serveur fraîchement obtenu.
  void poserDevis(DevisPanierVue devis) => state = state.avecDevis(devis);

  /// Le recalcul a échoué faute de réseau : le panier reste composable, les
  /// montants deviennent estimés (C3-3c). Rien n'est perdu.
  void marquerHorsLigne() => state = state.marqueHorsLigne();

  /// Vide le panier (commande créée, ou abandon).
  void vider() => state = EtatPanier.vide(
        zoneId: state.zoneId,
        categorieSlug: state.categorieSlug,
      );
}
