import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DossierCoursier
void main() {
  final instance = DossierCoursierBuilder();
  // TODO add properties to the builder and call build()

  group(DossierCoursier, () {
    // Motif de la dernière décision admin.
    // String motif
    test('to test the property `motif`', () async {
      // TODO
    });

    // Référent local (« caution morale », cadrage §7.1).
    // String referentNom
    test('to test the property `referentNom`', () async {
      // TODO
    });

    // Téléphone du référent, normalisé E.164.
    // String referentTelephoneE164
    test('to test the property `referentTelephoneE164`', () async {
      // TODO
    });

    // Dernier dépôt.
    // DateTime soumisLe
    test('to test the property `soumisLe`', () async {
      // TODO
    });

    // Statut = celui de l'attribution `coursier` (R9).
    // String statut
    test('to test the property `statut`', () async {
      // TODO
    });

    // Véhicules déclarés.
    // BuiltList<VehiculeDeclare> vehicules
    test('to test the property `vehicules`', () async {
      // TODO
    });

  });
}
