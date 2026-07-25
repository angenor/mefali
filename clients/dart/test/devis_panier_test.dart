import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DevisPanier
void main() {
  final instance = DevisPanierBuilder();
  // TODO add properties to the builder and call build()

  group(DevisPanier, () {
    // Devis de livraison.
    // DevisLivraison devis
    test('to test the property `devis`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Regroupement par vendeur.
    // BuiltList<GroupeVendeur> groupes
    test('to test the property `groupes`', () async {
      // TODO
    });

    // Montant des ARTICLES seuls (unités mineures).
    // int montantArticlesUnites
    test('to test the property `montantArticlesUnites`', () async {
      // TODO
    });

    // Décision d'encaissement.
    // PaiementPanier paiement
    test('to test the property `paiement`', () async {
      // TODO
    });

    // Proposition de scission, ou `null`.
    // ScissionProposee scission
    test('to test the property `scission`', () async {
      // TODO
    });

    // Total à payer = articles + prix client du devis.
    // int totalUnites
    test('to test the property `totalUnites`', () async {
      // TODO
    });

  });
}
