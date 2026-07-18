import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ModifierArticleDto
void main() {
  final instance = ModifierArticleDtoBuilder();
  // TODO add properties to the builder and call build()

  group(ModifierArticleDto, () {
    // Nouvelle étiquette — `null` l'efface.
    // String categorieInterne
    test('to test the property `categorieInterne`', () async {
      // TODO
    });

    // Nouveau nom.
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

    // Nouveau prix barré — `null` retire la promotion EXPLICITEMENT (jamais en silence : un prix barré devenu ≤ prix fait échouer l'opération).
    // int prixBarreUnites
    test('to test the property `prixBarreUnites`', () async {
      // TODO
    });

    // Nouveau prix courant.
    // int prixUnites
    test('to test the property `prixUnites`', () async {
      // TODO
    });

  });
}
