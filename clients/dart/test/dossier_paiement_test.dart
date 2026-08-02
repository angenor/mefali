import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DossierPaiement
void main() {
  final instance = DossierPaiementBuilder();
  // TODO add properties to the builder and call build()

  group(DossierPaiement, () {
    // Arrêt concerné (retenue écrêtée).
    // String arretId
    test('to test the property `arretId`', () async {
      // TODO
    });

    // Clôture.
    // DateTime closLe
    test('to test the property `closLe`', () async {
      // TODO
    });

    // Motif de clôture — clé i18n également.
    // String closMotifCle
    test('to test the property `closMotifCle`', () async {
      // TODO
    });

    // Commande concernée.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // `ouvert` | `clos`.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Dossier.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Montant attendu.
    // int montantAttendu
    test('to test the property `montantAttendu`', () async {
      // TODO
    });

    // Montant constaté.
    // int montantConstate
    test('to test the property `montantConstate`', () async {
      // TODO
    });

    // Motif — **clé i18n**, jamais un texte libre.
    // String motifCle
    test('to test the property `motifCle`', () async {
      // TODO
    });

    // Ouverture.
    // DateTime ouvertLe
    test('to test the property `ouvertLe`', () async {
      // TODO
    });

    // Transaction concernée.
    // String transactionId
    test('to test the property `transactionId`', () async {
      // TODO
    });

    // Famille d'anomalie.
    // String type
    test('to test the property `type`', () async {
      // TODO
    });

  });
}
