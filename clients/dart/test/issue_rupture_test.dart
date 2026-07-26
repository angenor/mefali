import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for IssueRupture
void main() {
  final instance = IssueRuptureBuilder();
  // TODO add properties to the builder and call build()

  group(IssueRupture, () {
    // Écart de prix en pourcent (signé).
    // int ecartPourcent
    test('to test the property `ecartPourcent`', () async {
      // TODO
    });

    // `ligne_retiree` | `proposition_ouverte`.
    // String issue
    test('to test the property `issue`', () async {
      // TODO
    });

    // Montant des articles après révision.
    // int montantArticlesUnites
    test('to test the property `montantArticlesUnites`', () async {
      // TODO
    });

    // Montant sorti du total (`null` si une proposition a été ouverte).
    // int montantRetire
    test('to test the property `montantRetire`', () async {
      // TODO
    });

    // Secondes dont dispose le client pour décider.
    // int resteS
    test('to test the property `resteS`', () async {
      // TODO
    });

    // Proposition créée (`null` si l'article a été retiré).
    // String substitutionId
    test('to test the property `substitutionId`', () async {
      // TODO
    });

    // Total après révision — **le devis de livraison n'a pas bougé** (FR-050).
    // int totalUnites
    test('to test the property `totalUnites`', () async {
      // TODO
    });

  });
}
