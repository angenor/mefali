import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for VendeurApi
void main() {
  final instance = MefaliApiClient().getVendeurApi();

  group(VendeurApi, () {
    // Geste V1 : ouvrir, fermer, pause, prolonger, fermer pour la journée.
    //
    //Future<BoutiqueVendeur> actionBoutique(String id, CorpsActionBoutique corpsActionBoutique) async
    test('test actionBoutique', () async {
      // TODO
    });

    // Bascule la disponibilité en UN geste (source vendeur — FR-037).
    //
    //Future<ArticleVendeur> basculerDisponibilite(String id, String articleId, BasculeDisponibiliteDto basculeDisponibiliteDto) async
    test('test basculerDisponibilite', () async {
      // TODO
    });

    // Ajoute un article au catalogue (V2 — « + Ajouter un article »).
    //
    //Future<ArticleVendeur> creerArticle(String id, CreerArticleDto creerArticleDto) async
    test('test creerArticle', () async {
      // TODO
    });

    // Déclare l'offre de livraison du vendeur (VND-08 minimal — FR-046).
    //
    //Future<OffreLivraisonReglee> definirOffreLivraison(String id, OffreLivraisonDeclaration offreLivraisonDeclaration) async
    test('test definirOffreLivraison', () async {
      // TODO
    });

    // Statut, échéance, horaires du jour et rappel de l'écran V1.
    //
    //Future<BoutiqueVendeur> maBoutique(String id) async
    test('test maBoutique', () async {
      // TODO
    });

    // Catalogue COMPLET du prestataire piloté (ruptures, retirés, verrou admin).
    //
    //Future<BuiltList<ArticleVendeur>> mesArticles(String id) async
    test('test mesArticles', () async {
      // TODO
    });

    // Prestataires que ce compte pilote (rattachements du cycle VND).
    //
    //Future<BuiltList<PrestatairePilotable>> mesPrestataires() async
    test('test mesPrestataires', () async {
      // TODO
    });

    // Modifie nom / prix / prix barré / étiquette (fiche article V2).
    //
    //Future<ArticleVendeur> modifierArticle(String id, String articleId, ModifierArticleDto modifierArticleDto) async
    test('test modifierArticle', () async {
      // TODO
    });

    // Remplace les horaires hebdomadaires (FR-034) — effet IMMÉDIAT.
    //
    //Future<BoutiqueVendeur> modifierHoraires(String id, HorairesSemaineDto horairesSemaineDto) async
    test('test modifierHoraires', () async {
      // TODO
    });

    // Dépose/remplace la photo de l'article (multipart, ≤ 5 Mo).
    //
    //Future<ArticleVendeur> photoArticle(String id, String articleId, MultipartFile fichier) async
    test('test photoArticle', () async {
      // TODO
    });

    // Reçu d'un arrêt collecté chez un prestataire piloté.
    //
    //Future<RecuArret> recuArret(String arretId) async
    test('test recuArret', () async {
      // TODO
    });

    // Remet un article retiré au catalogue, sans ressaisie (FR-055).
    //
    //Future<ArticleVendeur> remettreArticle(String id, String articleId) async
    test('test remettreArticle', () async {
      // TODO
    });

    // Retire l'article du catalogue — RÉVERSIBLE (FR-055).
    //
    //Future<ArticleVendeur> retirerArticle(String id, String articleId) async
    test('test retirerArticle', () async {
      // TODO
    });

  });
}
