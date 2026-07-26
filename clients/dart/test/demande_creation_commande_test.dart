import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeCreationCommande
void main() {
  final instance = DemandeCreationCommandeBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeCreationCommande, () {
    // Adresse du carnet (CPT-05) — ou `lieu` + repère fournis en clair.
    // String adresseId
    test('to test the property `adresseId`', () async {
      // TODO
    });

    // Catégorie de service.
    // String categorieSlug
    test('to test the property `categorieSlug`', () async {
      // TODO
    });

    // Pin GPS, si aucune adresse du carnet n'est utilisée.
    // Lieu lieu
    test('to test the property `lieu`', () async {
      // TODO
    });

    // Lignes du panier.
    // BuiltList<LignePanier> lignes
    test('to test the property `lignes`', () async {
      // TODO
    });

    // `cash` | `mobile_money`.
    // String modePaiement
    test('to test the property `modePaiement`', () async {
      // TODO
    });

    // Repère écrit.
    // String repereTexte
    test('to test the property `repereTexte`', () async {
      // TODO
    });

    // Clé S3 du repère vocal.
    // String repereVocalCle
    test('to test the property `repereVocalCle`', () async {
      // TODO
    });

    // Véhicule demandé.
    // String transportSlug
    test('to test the property `transportSlug`', () async {
      // TODO
    });

    // Zone de la commande.
    // String zoneId
    test('to test the property `zoneId`', () async {
      // TODO
    });

  });
}
