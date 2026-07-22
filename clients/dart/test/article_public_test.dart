import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ArticlePublic
void main() {
  final instance = ArticlePublicBuilder();
  // TODO add properties to the builder and call build()

  group(ArticlePublic, () {
    // Étiquette libre de regroupement.
    // String categorieInterne
    test('to test the property `categorieInterne`', () async {
      // TODO
    });

    // Code ISO 4217 de la zone.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Faux = rupture (servi seulement si le mode de la catégorie est `grise`).
    // bool disponible
    test('to test the property `disponible`', () async {
      // TODO
    });

    // Identifiant.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Nom.
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

    // URL présignée de la photo (TTL 10 min).
    // String photoUrl
    test('to test the property `photoUrl`', () async {
      // TODO
    });

    // Prix barré (présent ⇒ promotion, strictement supérieur — FR-023).
    // int prixBarreUnites
    test('to test the property `prixBarreUnites`', () async {
      // TODO
    });

    // Prix courant — ENTIER en unités mineures (constitution III).
    // int prixUnites
    test('to test the property `prixUnites`', () async {
      // TODO
    });

  });
}
