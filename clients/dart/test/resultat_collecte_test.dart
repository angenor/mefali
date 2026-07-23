import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ResultatCollecte
void main() {
  final instance = ResultatCollecteBuilder();
  // TODO add properties to the builder and call build()

  group(ResultatCollecte, () {
    // Statut de l'arrêt (`collecte`).
    // String arretStatut
    test('to test the property `arretStatut`', () async {
      // TODO
    });

    // Vrai si la livraison vient de basculer EN_LIVRAISON.
    // bool enLivraison
    test('to test the property `enLivraison`', () async {
      // TODO
    });

    // État de la livraison (`en_collecte` | `en_livraison`).
    // String livraisonEtat
    test('to test the property `livraisonEtat`', () async {
      // TODO
    });

    // Total d'arrêts.
    // int nbArrets
    test('to test the property `nbArrets`', () async {
      // TODO
    });

    // Arrêts collectés.
    // int nbCollectes
    test('to test the property `nbCollectes`', () async {
      // TODO
    });

  });
}
