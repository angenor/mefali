import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for FichePublique
void main() {
  final instance = FichePubliqueBuilder();
  // TODO add properties to the builder and call build()

  group(FichePublique, () {
    // Mode de rendu des ruptures, résolu pour la catégorie.
    // AffichageRupture affichageRupture
    test('to test the property `affichageRupture`', () async {
      // TODO
    });

    // Catalogue servi (retirés absents ; ruptures selon le mode).
    // BuiltList<ArticlePublic> articles
    test('to test the property `articles`', () async {
      // TODO
    });

    // État effectif de la boutique.
    // EtatEffectifBoutique boutique
    test('to test the property `boutique`', () async {
      // TODO
    });

    // Slug de la catégorie de service.
    // String categorie
    test('to test the property `categorie`', () async {
      // TODO
    });

    // FR-028 — la SEULE définition de « commandable ».
    // bool commandable
    test('to test the property `commandable`', () async {
      // TODO
    });

    // Délai de préparation moyen déclaré (minutes).
    // int delaiPreparationMin
    test('to test the property `delaiPreparationMin`', () async {
      // TODO
    });

    // Horaires hebdomadaires.
    // HorairesSemaineDto horaires
    test('to test the property `horaires`', () async {
      // TODO
    });

    // Identifiant du prestataire.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Nom public.
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

    // URLs présignées des photos de fiche.
    // BuiltList<String> photos
    test('to test the property `photos`', () async {
      // TODO
    });

  });
}
