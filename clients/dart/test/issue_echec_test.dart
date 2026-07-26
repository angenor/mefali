import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for IssueEchec
void main() {
  final instance = IssueEchecBuilder();
  // TODO add properties to the builder and call build()

  group(IssueEchec, () {
    // Commande concernée.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Qui détient l'ARGENT.
    // String detenteurArgent
    test('to test the property `detenteurArgent`', () async {
      // TODO
    });

    // Qui détient la MARCHANDISE — axe indépendant du précédent (R14).
    // String detenteurMarchandise
    test('to test the property `detenteurMarchandise`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Le coursier doit être indemnisé (contrat CRS-06).
    // bool indemnisationDue
    test('to test the property `indemnisationDue`', () async {
      // TODO
    });

    // Identifiant de l'issue.
    // String issueId
    test('to test the property `issueId`', () async {
      // TODO
    });

    // Un litige est ouvert (contrat AVI-04).
    // bool litigeOuvert
    test('to test the property `litigeOuvert`', () async {
      // TODO
    });

    // Montant en jeu (unités mineures).
    // int montantEnJeuUnites
    test('to test the property `montantEnJeuUnites`', () async {
      // TODO
    });

    // Commande de re-livraison créée (§7.5-10 seulement).
    // String relivraisonId
    test('to test the property `relivraisonId`', () async {
      // TODO
    });

    // Sanction effectivement posée sur le compte client.
    // String sanction
    test('to test the property `sanction`', () async {
      // TODO
    });

  });
}
