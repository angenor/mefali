import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ActionArret
void main() {
  final instance = ActionArretBuilder();
  // TODO add properties to the builder and call build()

  group(ActionArret, () {
    // Horodatage de l'appareil. **Observation seulement** : le serveur écrit le sien, parce que `arrive_le` fonde une prime (TRF-06).
    // DateTime horodatageLocal
    test('to test the property `horodatageLocal`', () async {
      // TODO
    });

    // Pour `indisponible` : `vendeur_ferme` (défaut) ou `toutes_lignes_retirees`. Ignoré par les autres actions.
    // String motif
    test('to test the property `motif`', () async {
      // TODO
    });

    // Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
    // String uuidClient
    test('to test the property `uuidClient`', () async {
      // TODO
    });

  });
}
