import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PreuvePresence
void main() {
  final instance = PreuvePresenceBuilder();
  // TODO add properties to the builder and call build()

  group(PreuvePresence, () {
    // Pourquoi elle ne l'est pas — clé i18n.
    // String motifCle
    test('to test the property `motifCle`', () async {
      // TODO
    });

    // Preuve réunie.
    // bool ok
    test('to test the property `ok`', () async {
      // TODO
    });

    // Durée exigée par la zone.
    // int requis
    test('to test the property `requis`', () async {
      // TODO
    });

    // Durée retenue (s), recalculée par le serveur.
    // int secondes
    test('to test the property `secondes`', () async {
      // TODO
    });

  });
}
