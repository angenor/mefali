import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for Inscription
void main() {
  final instance = InscriptionBuilder();
  // TODO add properties to the builder and call build()

  group(Inscription, () {
    // Version du texte ARTCI accepté — servie par la config de zone.
    // String consentementVersion
    test('to test the property `consentementVersion`', () async {
      // TODO
    });

    // Émis par `/auth/otp/verifier`, usage unique, TTL 10 min.
    // String jetonInscription
    test('to test the property `jetonInscription`', () async {
      // TODO
    });

  });
}
