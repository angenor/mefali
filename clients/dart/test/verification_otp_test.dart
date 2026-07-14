import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for VerificationOtp
void main() {
  final instance = VerificationOtpBuilder();
  // TODO add properties to the builder and call build()

  group(VerificationOtp, () {
    // Appareil — capté ici, conservé jusqu'à l'inscription (R3).
    // AppareilDto appareil
    test('to test the property `appareil`', () async {
      // TODO
    });

    // Code à 6 chiffres.
    // String code
    test('to test the property `code`', () async {
      // TODO
    });

    // Le MÊME numéro que celui de la demande.
    // String telephone
    test('to test the property `telephone`', () async {
      // TODO
    });

    // Zone de l'app.
    // String zone
    test('to test the property `zone`', () async {
      // TODO
    });

  });
}
