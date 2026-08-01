import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for LigneRegistre
void main() {
  final instance = LigneRegistreBuilder();
  // TODO add properties to the builder and call build()

  group(LigneRegistre, () {
    // Commande rapprochée — le rapprochement se lit sans jointure manuelle.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // État de la transaction.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Fournisseur qui a encaissé.
    // String fournisseur
    test('to test the property `fournisseur`', () async {
      // TODO
    });

    // Transaction.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Issue définitive.
    // DateTime issueLe
    test('to test the property `issueLe`', () async {
      // TODO
    });

    // Montant figé.
    // int montantUnites
    test('to test the property `montantUnites`', () async {
      // TODO
    });

    // Moyen employé — `inconnu` tant que le fournisseur ne l'a pas dit.
    // String moyen
    test('to test the property `moyen`', () async {
      // TODO
    });

    // De l'argent encaissé qu'aucune commande vivante n'attend (FR-082).
    // bool orpheline
    test('to test the property `orpheline`', () async {
      // TODO
    });

    // Ouverture.
    // DateTime ouverteLe
    test('to test the property `ouverteLe`', () async {
      // TODO
    });

    // Référence côté fournisseur — le rapprochement dans l'AUTRE sens.
    // String referenceFournisseur
    test('to test the property `referenceFournisseur`', () async {
      // TODO
    });

  });
}
