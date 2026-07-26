import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ResultatAnnulation
void main() {
  final instance = ResultatAnnulationBuilder();
  // TODO add properties to the builder and call build()

  group(ResultatAnnulation, () {
    // Commande annulée.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Montant déjà avancé chez les vendeurs.
    // int montantAvance
    test('to test the property `montantAvance`', () async {
      // TODO
    });

    // Part due au coursier (unités mineures) — 0 si sans frais.
    // int partCoursierDue
    test('to test the property `partCoursierDue`', () async {
      // TODO
    });

    // Vrai si la commande était prépayée : un remboursement est dû.
    // bool remboursementDu
    test('to test the property `remboursementDu`', () async {
      // TODO
    });

    // Vrai si rien n'avait encore été acheté : annulation SANS FRAIS.
    // bool sansFrais
    test('to test the property `sansFrais`', () async {
      // TODO
    });

  });
}
