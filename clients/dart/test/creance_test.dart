import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for Creance
void main() {
  final instance = CreanceBuilder();
  // TODO add properties to the builder and call build()

  group(Creance, () {
    // Commande d'origine.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Naissance — automatique, à la livraison (FR-063).
    // DateTime creeLe
    test('to test the property `creeLe`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // `due` | `reglee`.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Identifiant.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Montant dû (unités mineures).
    // int montantUnites
    test('to test the property `montantUnites`', () async {
      // TODO
    });

    // `avance_prepayee` | `part_course`.
    // String nature
    test('to test the property `nature`', () async {
      // TODO
    });

    // Instant du règlement, `null` tant qu'elle est due.
    // DateTime regleLe
    test('to test the property `regleLe`', () async {
      // TODO
    });

  });
}
