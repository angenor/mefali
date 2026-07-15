import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DossierCoursierAdmin
void main() {
  final instance = DossierCoursierAdminBuilder();
  // TODO add properties to the builder and call build()

  group(DossierCoursierAdmin, () {
    // Compte du coursier.
    // String compteId
    test('to test the property `compteId`', () async {
      // TODO
    });

    // Motif de la dernière décision admin.
    // String motif
    test('to test the property `motif`', () async {
      // TODO
    });

    // URL présignée de la pièce (TTL 10 min) — DÉTAIL uniquement, absente en liste : présigner N pièces pour un tableau serait du gaspillage, et autant de liens vivants qu'aucun œil n'ouvrira.
    // String pieceUrl
    test('to test the property `pieceUrl`', () async {
      // TODO
    });

    // Référent local.
    // String referentNom
    test('to test the property `referentNom`', () async {
      // TODO
    });

    // Téléphone du référent.
    // String referentTelephoneE164
    test('to test the property `referentTelephoneE164`', () async {
      // TODO
    });

    // Dernier dépôt.
    // DateTime soumisLe
    test('to test the property `soumisLe`', () async {
      // TODO
    });

    // Statut = celui de l'attribution `coursier`.
    // String statut
    test('to test the property `statut`', () async {
      // TODO
    });

    // Numéro du coursier — l'admin doit pouvoir le rappeler (FR-017).
    // String telephoneE164
    test('to test the property `telephoneE164`', () async {
      // TODO
    });

    // Véhicules déclarés.
    // BuiltList<VehiculeDeclare> vehicules
    test('to test the property `vehicules`', () async {
      // TODO
    });

  });
}
