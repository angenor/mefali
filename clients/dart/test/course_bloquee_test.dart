import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for CourseBloquee
void main() {
  final instance = CourseBloqueeBuilder();
  // TODO add properties to the builder and call build()

  group(CourseBloquee, () {
    // Commande concernée.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Coursier assigné.
    // String coursierId
    test('to test the property `coursierId`', () async {
      // TODO
    });

    // Livraison concernée.
    // String livraisonId
    test('to test the property `livraisonId`', () async {
      // TODO
    });

    // Critère constaté : `sans_mouvement` | `sans_scan`.
    // String motif
    test('to test the property `motif`', () async {
      // TODO
    });

    // Arrêts déjà collectés. **`> 0` ⇒ aucune reprise automatique possible.**
    // int nbArretsCollectes
    test('to test the property `nbArretsCollectes`', () async {
      // TODO
    });

    // Faux quand un arrêt est collecté : seule une décision humaine motivée peut alors trancher, parce que le coursier a engagé ses fonds propres.
    // bool repriseAutomatiquePossible
    test('to test the property `repriseAutomatiquePossible`', () async {
      // TODO
    });

    // Durée de stagnation constatée (secondes).
    // int stagnationS
    test('to test the property `stagnationS`', () async {
      // TODO
    });

  });
}
