import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PublicationPosition
void main() {
  final instance = PublicationPositionBuilder();
  // TODO add properties to the builder and call build()

  group(PublicationPosition, () {
    // Horodatage de l'appareil. **Observation seulement** : le serveur écrit le sien (FR-055).
    // DateTime horodatageLocal
    test('to test the property `horodatageLocal`', () async {
      // TODO
    });

    // Latitude.
    // double lat
    test('to test the property `lat`', () async {
      // TODO
    });

    // Longitude.
    // double lon
    test('to test the property `lon`', () async {
      // TODO
    });

    // Précision annoncée par le téléphone (mètres), informative.
    // int precisionM
    test('to test the property `precisionM`', () async {
      // TODO
    });

    // Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
    // String uuidClient
    test('to test the property `uuidClient`', () async {
      // TODO
    });

  });
}
