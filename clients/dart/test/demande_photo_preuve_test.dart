import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandePhotoPreuve
void main() {
  final instance = DemandePhotoPreuveBuilder();
  // TODO add properties to the builder and call build()

  group(DemandePhotoPreuve, () {
    // Horodatage de la prise de vue sur l'appareil. **Observation** — retenu comme date de prise pour que l'ordre des photos reste celui du terrain.
    // DateTime priseLeLocal
    test('to test the property `priseLeLocal`', () async {
      // TODO
    });

    // Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
    // String uuidClient
    test('to test the property `uuidClient`', () async {
      // TODO
    });

  });
}
