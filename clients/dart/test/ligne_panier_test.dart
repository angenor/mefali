import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for LignePanier
void main() {
  final instance = LignePanierBuilder();
  // TODO add properties to the builder and call build()

  group(LignePanier, () {
    // Article demandé.
    // String articleId
    test('to test the property `articleId`', () async {
      // TODO
    });

    // Que faire si l'article manque : `remplacer` | `appeler` | `retirer`. Absent = `appeler`, le défaut produit (CMD-01).
    // String preference
    test('to test the property `preference`', () async {
      // TODO
    });

    // Vendeur chez qui l'article est pris.
    // String prestataireId
    test('to test the property `prestataireId`', () async {
      // TODO
    });

    // Quantité (> 0).
    // int quantite
    test('to test the property `quantite`', () async {
      // TODO
    });

  });
}
