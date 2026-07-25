import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for Commande
void main() {
  final instance = CommandeBuilder();
  // TODO add properties to the builder and call build()

  group(Commande, () {
    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // État de très haut niveau.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Identifiant (= `Idempotency-Key`).
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Livraison.
    // LivraisonCommande livraison
    test('to test the property `livraison`', () async {
      // TODO
    });

    // Montant des articles.
    // int montantArticlesUnites
    test('to test the property `montantArticlesUnites`', () async {
      // TODO
    });

    // Paiement.
    // PaiementCommande paiement
    test('to test the property `paiement`', () async {
      // TODO
    });

    // Code et jeton de remise.
    // SecretsRemise remise
    test('to test the property `remise`', () async {
      // TODO
    });

    // Total à payer.
    // int totalUnites
    test('to test the property `totalUnites`', () async {
      // TODO
    });

  });
}
