import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ExpositionCash
void main() {
  final instance = ExpositionCashBuilder();
  // TODO add properties to the builder and call build()

  group(ExpositionCash, () {
    // Instant de la lecture — l'exposition est vraie **à quelques secondes** près (délai du worker outbox, SC-010 l'accepte explicitement).
    // DateTime au
    test('to test the property `au`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Détail, du plus exposé au moins exposé.
    // BuiltList<LigneExposition> parCoursier
    test('to test the property `parCoursier`', () async {
      // TODO
    });

    // Total en circulation.
    // int totalUnites
    test('to test the property `totalUnites`', () async {
      // TODO
    });

  });
}
