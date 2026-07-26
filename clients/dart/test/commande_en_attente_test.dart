import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for CommandeEnAttente
void main() {
  final instance = CommandeEnAttenteBuilder();
  // TODO add properties to the builder and call build()

  group(CommandeEnAttente, () {
    // Ancienneté dans la file, en secondes — **c'est elle qui ordonne**.
    // int ageS
    test('to test the property `ageS`', () async {
      // TODO
    });

    // Commande concernée.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Montant total que le coursier devra avancer (unités mineures).
    // int montantAAvancer
    test('to test the property `montantAAvancer`', () async {
      // TODO
    });

    // Nombre d'arrêts de collecte à desservir.
    // int nbCollectes
    test('to test the property `nbCollectes`', () async {
      // TODO
    });

    // Latitude du premier site VENDEUR — donnée professionnelle. Aucune coordonnée du client n'est exposée ici (minimisation ARTCI).
    // double premiereCollecteLat
    test('to test the property `premiereCollecteLat`', () async {
      // TODO
    });

    // Longitude du premier site vendeur.
    // double premiereCollecteLon
    test('to test the property `premiereCollecteLon`', () async {
      // TODO
    });

    // Zone de la commande.
    // String zoneId
    test('to test the property `zoneId`', () async {
      // TODO
    });

  });
}
