import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for Devis
void main() {
  final instance = DevisBuilder();
  // TODO add properties to the builder and call build()

  group(Devis, () {
    // Distance issue du mode dégradé.
    // bool degraded
    test('to test the property `degraded`', () async {
      // TODO
    });

    // Devise ISO 4217 de la zone.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Distance routière totale (mètres).
    // int distanceM
    test('to test the property `distanceM`', () async {
      // TODO
    });

    // Durée estimée (secondes).
    // int etaS
    test('to test the property `etaS`', () async {
      // TODO
    });

    // Marge Mefali.
    // int marge
    test('to test the property `marge`', () async {
      // TODO
    });

    // Part reversée au coursier.
    // int partCoursier
    test('to test the property `partCoursier`', () async {
      // TODO
    });

    // Prix payé par le client (unités mineures).
    // int prixClient
    test('to test the property `prixClient`', () async {
      // TODO
    });

    // Le détour dépasse le plafond de zone : CMD proposera de scinder.
    // bool proposerScission
    test('to test the property `proposerScission`', () async {
      // TODO
    });

  });
}
