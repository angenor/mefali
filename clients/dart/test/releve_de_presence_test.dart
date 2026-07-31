import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ReleveDePresence
void main() {
  final instance = ReleveDePresenceBuilder();
  // TODO add properties to the builder and call build()

  group(ReleveDePresence, () {
    // Éloignement du point de livraison, en mètres **arrondis**.  ⚠ Une distance, **jamais une position** : le serveur ne stocke aucune coordonnée, donc n'en fuite aucune (R8, patron ARTCI du cycle 006).
    // int distanceM
    test('to test the property `distanceM`', () async {
      // TODO
    });

    // Horodatage de l'échantillon sur l'appareil.
    // DateTime releveLeLocal
    test('to test the property `releveLeLocal`', () async {
      // TODO
    });

    // Clé d'idempotence du relevé (UUIDv7 client, constitution V).
    // String uuidClient
    test('to test the property `uuidClient`', () async {
      // TODO
    });

  });
}
