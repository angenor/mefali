import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for CoursierDuPool
void main() {
  final instance = CoursierDuPoolBuilder();
  // TODO add properties to the builder and call build()

  group(CoursierDuPool, () {
    // Âge de la dernière publication (secondes) — l'exploitation doit savoir si elle regarde une position fraîche ou un point figé.
    // int ageS
    test('to test the property `ageS`', () async {
      // TODO
    });

    // Capacités déclarées (slugs).
    // BuiltList<String> capacites
    test('to test the property `capacites`', () async {
      // TODO
    });

    // Course en cours, s'il y en a une.
    // String courseActive
    test('to test the property `courseActive`', () async {
      // TODO
    });

    // Compte du coursier.
    // String coursierId
    test('to test the property `coursierId`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Dernière latitude publiée.
    // double lat
    test('to test the property `lat`', () async {
      // TODO
    });

    // Dernière longitude publiée.
    // double lon
    test('to test the property `lon`', () async {
      // TODO
    });

    // Plafond d'avance RETENU du jour — `min(palier de la grille, déclaré)`.
    // int plafondUnites
    test('to test the property `plafondUnites`', () async {
      // TODO
    });

  });
}
