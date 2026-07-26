import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ResultatDecisionSubstitution
void main() {
  final instance = ResultatDecisionSubstitutionBuilder();
  // TODO add properties to the builder and call build()

  group(ResultatDecisionSubstitution, () {
    // Prix client du devis de livraison — **inchangé** (FR-050). Servi pour que le client le VOIE ne pas bouger, pas seulement pour l'affichage.
    // int devisPrixClientUnites
    test('to test the property `devisPrixClientUnites`', () async {
      // TODO
    });

    // `acceptee` | `refusee`.
    // String issue
    test('to test the property `issue`', () async {
      // TODO
    });

    // Montant des articles après révision.
    // int montantArticlesUnites
    test('to test the property `montantArticlesUnites`', () async {
      // TODO
    });

    // Total à payer après révision.
    // int totalUnites
    test('to test the property `totalUnites`', () async {
      // TODO
    });

  });
}
