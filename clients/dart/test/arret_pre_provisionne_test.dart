import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ArretPreProvisionne
void main() {
  final instance = ArretPreProvisionneBuilder();
  // TODO add properties to the builder and call build()

  group(ArretPreProvisionne, () {
    // Arrêt à collecter.
    // String arretId
    test('to test the property `arretId`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Rayon max de scan (m) — validation de proximité hors-ligne.
    // int distanceMaxM
    test('to test the property `distanceMaxM`', () async {
      // TODO
    });

    // base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
    // String empreinteCode
    test('to test the property `empreinteCode`', () async {
      // TODO
    });

    // base16(sha256(jeton)) — match hors-ligne du QR scanné.
    // String empreinteJeton
    test('to test the property `empreinteJeton`', () async {
      // TODO
    });

    // Montant avancé (unités mineures).
    // int montantAvance
    test('to test the property `montantAvance`', () async {
      // TODO
    });

    // Nom du prestataire (affiché sur la carte K3).
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

    // Photo exigée (politique résolue).
    // bool photoExigee
    test('to test the property `photoExigee`', () async {
      // TODO
    });

    // Prestataire visé.
    // String prestataireId
    test('to test the property `prestataireId`', () async {
      // TODO
    });

    // Position attendue du site.
    // double siteLat
    test('to test the property `siteLat`', () async {
      // TODO
    });

    // Position attendue du site.
    // double siteLon
    test('to test the property `siteLon`', () async {
      // TODO
    });

  });
}
