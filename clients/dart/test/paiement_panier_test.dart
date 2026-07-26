import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PaiementPanier
void main() {
  final instance = PaiementPanierBuilder();
  // TODO add properties to the builder and call build()

  group(PaiementPanier, () {
    // Le paiement en espèces est possible.
    // bool cashAutorise
    test('to test the property `cashAutorise`', () async {
      // TODO
    });

    // Clé i18n de la RAISON du refus (`null` si autorisé) — le client voit pourquoi le cash est grisé, jamais un bouton mort.
    // String motifCle
    test('to test the property `motifCle`', () async {
      // TODO
    });

    // Plafond appliqué (unités mineures).
    // int plafondUnites
    test('to test the property `plafondUnites`', () async {
      // TODO
    });

  });
}
