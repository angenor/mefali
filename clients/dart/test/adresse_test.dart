import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for Adresse
void main() {
  final instance = AdresseBuilder();
  // TODO add properties to the builder and call build()

  group(Adresse, () {
    // `false` après purge (12 mois sans utilisation — FR-022).
    // bool aRepereVocal
    test('to test the property `aRepereVocal`', () async {
      // TODO
    });

    // Enregistrement.
    // DateTime creeLe
    test('to test the property `creeLe`', () async {
      // TODO
    });

    // Base de la purge.
    // DateTime derniereUtilisationLe
    test('to test the property `derniereUtilisationLe`', () async {
      // TODO
    });

    // Identifiant = `Idempotency-Key` du POST créateur (R14).
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Latitude du pin GPS.
    // double lat
    test('to test the property `lat`', () async {
      // TODO
    });

    // « Maison », « Bureau » ou libre.
    // String libelle
    test('to test the property `libelle`', () async {
      // TODO
    });

    // Longitude du pin GPS.
    // double lng
    test('to test the property `lng`', () async {
      // TODO
    });

    // Repère écrit.
    // String repereTexte
    test('to test the property `repereTexte`', () async {
      // TODO
    });

    // Durée du repère vocal.
    // int repereVocalDureeS
    test('to test the property `repereVocalDureeS`', () async {
      // TODO
    });

    // Zone de l'adresse.
    // String zoneId
    test('to test the property `zoneId`', () async {
      // TODO
    });

  });
}
