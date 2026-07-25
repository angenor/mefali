import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for LivraisonCommande
void main() {
  final instance = LivraisonCommandeBuilder();
  // TODO add properties to the builder and call build()

  group(LivraisonCommande, () {
    // Devis FIGÉ copié à la création — jamais recalculé (R11).
    // DevisLivraison devis
    test('to test the property `devis`', () async {
      // TODO
    });

    // État logistique initial.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Identifiant.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Nombre d'arrêts (collectes + remise).
    // int nbArrets
    test('to test the property `nbArrets`', () async {
      // TODO
    });

  });
}
