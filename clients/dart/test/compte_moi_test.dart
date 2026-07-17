import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for CompteMoi
void main() {
  final instance = CompteMoiBuilder();
  // TODO add properties to the builder and call build()

  group(CompteMoi, () {
    // Création du compte.
    // DateTime creeLe
    test('to test the property `creeLe`', () async {
      // TODO
    });

    // Identifiant du compte.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Rôles et leurs statuts (tous, pas seulement les valides).
    // BuiltList<EtatRoleDto> roles
    test('to test the property `roles`', () async {
      // TODO
    });

    // Identité Mefali — aucune donnée nominative au MVP.
    // String telephoneE164
    test('to test the property `telephoneE164`', () async {
      // TODO
    });

    // Zone de rattachement.
    // String zoneId
    test('to test the property `zoneId`', () async {
      // TODO
    });

  });
}
