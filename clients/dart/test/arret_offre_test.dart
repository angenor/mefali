import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ArretOffre
void main() {
  final instance = ArretOffreBuilder();
  // TODO add properties to the builder and call build()

  group(ArretOffre, () {
    // Distance INTER-ARRÊTS (mètres) — « + 40 m » de la maquette.
    // int distanceM
    test('to test the property `distanceM`', () async {
      // TODO
    });

    // Nom affiché sur la carte.
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

    // Rang d'affichage (1 = premier arrêt).
    // int ordre
    test('to test the property `ordre`', () async {
      // TODO
    });

    // Prestataire visé.
    // String prestataireId
    test('to test the property `prestataireId`', () async {
      // TODO
    });

  });
}
