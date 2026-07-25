import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeDevisPanier
void main() {
  final instance = DemandeDevisPanierBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeDevisPanier, () {
    // Catégorie de service (`marche`, `restauration`…).
    // String categorieSlug
    test('to test the property `categorieSlug`', () async {
      // TODO
    });

    // Lieu de prestation — destination de la course.
    // Lieu lieu
    test('to test the property `lieu`', () async {
      // TODO
    });

    // Lignes du panier, dans l'ordre de composition.
    // BuiltList<LignePanier> lignes
    test('to test the property `lignes`', () async {
      // TODO
    });

    // Véhicule demandé (`moto`, `velo`…).
    // String transportSlug
    test('to test the property `transportSlug`', () async {
      // TODO
    });

    // Zone de la commande (résout mixage, plafonds, devise).
    // String zoneId
    test('to test the property `zoneId`', () async {
      // TODO
    });

  });
}
