import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for IndemnisationVue
void main() {
  final instance = IndemnisationVueBuilder();
  // TODO add properties to the builder and call build()

  group(IndemnisationVue, () {
    // Commande d'origine.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Référence lisible de la commande.
    // String commandeReference
    test('to test the property `commandeReference`', () async {
      // TODO
    });

    // Naissance de la demande.
    // DateTime creeLe
    test('to test the property `creeLe`', () async {
      // TODO
    });

    // Quand la décision a été prise.
    // DateTime decideLe
    test('to test the property `decideLe`', () async {
      // TODO
    });

    // Clé i18n du motif de décision (refus surtout).
    // String decisionMotifCle
    test('to test the property `decisionMotifCle`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // `demandee` | `validee` | `refusee`.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Indemnisation.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Litige rattaché — **absent** tant qu'AVI-04 n'existe pas (R16).
    // String litigeId
    test('to test the property `litigeId`', () async {
      // TODO
    });

    // Montant (unités mineures, positif).
    // int montantUnites
    test('to test the property `montantUnites`', () async {
      // TODO
    });

    // Clé i18n du motif.
    // String motifCle
    test('to test the property `motifCle`', () async {
      // TODO
    });

  });
}
