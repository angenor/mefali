import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeCollecte
void main() {
  final instance = DemandeCollecteBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeCollecte, () {
    // Code à 4 chiffres saisi (mode `code_secours`).
    // String code
    test('to test the property `code`', () async {
      // TODO
    });

    // Horodatage local de l'action.
    // DateTime horodatageLocal
    test('to test the property `horodatageLocal`', () async {
      // TODO
    });

    // Jeton lu dans le QR (mode `scan_qr`).
    // String jeton
    test('to test the property `jeton`', () async {
      // TODO
    });

    // Scan du QR ou saisie du code de secours.
    // ModeCollecte mode
    test('to test the property `mode`', () async {
      // TODO
    });

    // Position capturée du coursier.
    // double positionLat
    test('to test the property `positionLat`', () async {
      // TODO
    });

    // Position capturée du coursier.
    // double positionLon
    test('to test the property `positionLon`', () async {
      // TODO
    });

    // Clé d'idempotence (UUIDv7 client, V).
    // String uuidClient
    test('to test the property `uuidClient`', () async {
      // TODO
    });

  });
}
