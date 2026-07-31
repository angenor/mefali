import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for LigneHistoriqueCaisse
void main() {
  final instance = LigneHistoriqueCaisseBuilder();
  // TODO add properties to the builder and call build()

  group(LigneHistoriqueCaisse, () {
    // Ce que le coursier a avancé (positif).
    // int avanceUnites
    test('to test the property `avanceUnites`', () async {
      // TODO
    });

    // Commande concernée.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Avance NON SOLDÉE parce que la commande était prépayée (R10, FR-117).
    // bool enAttenteReglement
    test('to test the property `enAttenteReglement`', () async {
      // TODO
    });

    // Sa part sur cette course (devis figé du cycle 007).
    // int gainUnites
    test('to test the property `gainUnites`', () async {
      // TODO
    });

    // Heure de la première écriture (horodatage serveur).
    // DateTime heure
    test('to test the property `heure`', () async {
      // TODO
    });

    // Livraison concernée.
    // String livraisonId
    test('to test the property `livraisonId`', () async {
      // TODO
    });

    // Référence lisible (`#418`) — de quoi se parler au téléphone.
    // String reference
    test('to test the property `reference`', () async {
      // TODO
    });

    // Ce qu'il a récupéré (positif).
    // int rembourseUnites
    test('to test the property `rembourseUnites`', () async {
      // TODO
    });

    // La course est-elle terminée ?
    // bool terminee
    test('to test the property `terminee`', () async {
      // TODO
    });

  });
}
