import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeSimulation
void main() {
  final instance = DemandeSimulationBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeSimulation, () {
    // Attentes constatées, `null` = aucune.
    // BuiltList<Attente> attentes
    test('to test the property `attentes`', () async {
      // TODO
    });

    // Catégorie de service, `null` = aucune contrainte.
    // String categorieSlug
    test('to test the property `categorieSlug`', () async {
      // TODO
    });

    // Destination client.
    // Point destination
    test('to test the property `destination`', () async {
      // TODO
    });

    // Instant d'évaluation (plages horaires, jours, dates d'effet).
    // DateTime instant
    test('to test the property `instant`', () async {
      // TODO
    });

    // Commande mono-vendeur — condition NÉCESSAIRE de VND-08.
    // bool monoVendeur
    test('to test the property `monoVendeur`', () async {
      // TODO
    });

    // Montant du panier (unités mineures) — seuil VND-08.
    // int montantPanier
    test('to test the property `montantPanier`', () async {
      // TODO
    });

    // Nombre total d'articles de la commande (paliers d'effort).
    // int nbArticles
    test('to test the property `nbArticles`', () async {
      // TODO
    });

    // Offre de livraison du vendeur, `null` = aucune.
    // OffreLivraisonVendeur offreLivraisonVendeur
    test('to test the property `offreLivraisonVendeur`', () async {
      // TODO
    });

    // Véhicule.
    // String transportSlug
    test('to test the property `transportSlug`', () async {
      // TODO
    });

    // Points de retrait (1..n), dans un ordre quelconque — le moteur optimise.
    // BuiltList<Point> vendeurs
    test('to test the property `vendeurs`', () async {
      // TODO
    });

  });
}
