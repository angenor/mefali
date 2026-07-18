import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for CreerArticleDto
void main() {
  final instance = CreerArticleDtoBuilder();
  // TODO add properties to the builder and call build()

  group(CreerArticleDto, () {
    // Étiquette libre de regroupement.
    // String categorieInterne
    test('to test the property `categorieInterne`', () async {
      // TODO
    });

    // Nom.
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

    // Prix barré optionnel (strictement supérieur — FR-023).
    // int prixBarreUnites
    test('to test the property `prixBarreUnites`', () async {
      // TODO
    });

    // Prix courant, entier en unités mineures — la devise est POSÉE PAR LE SERVEUR depuis la zone (constitution III).
    // int prixUnites
    test('to test the property `prixUnites`', () async {
      // TODO
    });

  });
}
