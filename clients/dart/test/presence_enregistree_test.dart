import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PresenceEnregistree
void main() {
  final instance = PresenceEnregistreeBuilder();
  // TODO add properties to the builder and call build()

  group(PresenceEnregistree, () {
    // Présence **recalculée par le serveur**, en secondes (FR-060).
    // int presenceS
    test('to test the property `presenceS`', () async {
      // TODO
    });

    // Durée exigée par la zone.
    // int requisS
    test('to test the property `requisS`', () async {
      // TODO
    });

    // Relevés du lot connus du serveur — identique au rejeu (constitution V).
    // int retenus
    test('to test the property `retenus`', () async {
      // TODO
    });

  });
}
