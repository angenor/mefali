import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeRemise
void main() {
  final instance = DemandeRemiseBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeRemise, () {
    // Code à 4 chiffres dicté par le client (mode `code`).
    // String code
    test('to test the property `code`', () async {
      // TODO
    });

    // Jeton lu dans le QR de réception (mode `qr`).
    // String jeton
    test('to test the property `jeton`', () async {
      // TODO
    });

    // `qr` | `code` | `depot`.
    // String mode
    test('to test the property `mode`', () async {
      // TODO
    });

    // Clé de la photo déposée sur place (mode `depot`).
    // String photoCle
    test('to test the property `photoCle`', () async {
      // TODO
    });

  });
}
