import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for LigneExposition
void main() {
  final instance = LigneExpositionBuilder();
  // TODO add properties to the builder and call build()

  group(LigneExposition, () {
    // Avance en cours (unités mineures, positif).
    // int avanceUnites
    test('to test the property `avanceUnites`', () async {
      // TODO
    });

    // Courses concernées.
    // int courses
    test('to test the property `courses`', () async {
      // TODO
    });

    // Coursier.
    // String coursierId
    test('to test the property `coursierId`', () async {
      // TODO
    });

    // Nom d'usage. **Vide** tant que le produit n'en porte aucun (cycle CPT 003 : « un numéro vérifié, rien d'autre ») — un nom fabriqué depuis le numéro serait pire qu'une absence.
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

  });
}
