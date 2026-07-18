import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ArticleVendeur
void main() {
  final instance = ArticleVendeurBuilder();
  // TODO add properties to the builder and call build()

  group(ArticleVendeur, () {
    // Étiquette libre de regroupement.
    // String categorieInterne
    test('to test the property `categorieInterne`', () async {
      // TODO
    });

    // Code ISO 4217 (posé par le serveur — R13).
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Faux = rupture.
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

    // Prix barré (strictement supérieur — FR-023).
    // int prixBarreUnites
    test('to test the property `prixBarreUnites`', () async {
      // TODO
    });

    // Prix courant, entier en unités mineures.
    // int prixUnites
    test('to test the property `prixUnites`', () async {
      // TODO
    });

    // Retiré du catalogue — remise possible sans ressaisie (FR-055).
    // bool retire
    test('to test the property `retire`', () async {
      // TODO
    });

    // Rupture posée par l'Admin — la bascule vendeur sera refusée (FR-041).
    // bool ruptureAdmin
    test('to test the property `ruptureAdmin`', () async {
      // TODO
    });

    // Source de la dernière bascule (FR-037).
    // SourceBascule sourceDerniereBascule
    test('to test the property `sourceDerniereBascule`', () async {
      // TODO
    });

  });
}
