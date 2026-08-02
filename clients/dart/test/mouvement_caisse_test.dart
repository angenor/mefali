import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for MouvementCaisse
void main() {
  final instance = MouvementCaisseBuilder();
  // TODO add properties to the builder and call build()

  group(MouvementCaisse, () {
    // Commande concernée — `null` pour un règlement ou un reversement, qui portent sur un solde et non sur une course.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Vrai si l'argent entre dans la poche du coursier.
    // bool entree
    test('to test the property `entree`', () async {
      // TODO
    });

    // Horodatage serveur de l'écriture.
    // DateTime heure
    test('to test the property `heure`', () async {
      // TODO
    });

    // Écriture.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Montant **signé** : négatif quand l'argent sort de la poche.  L'app dérive « entrée » ou « sortie » de ce SIGNE, jamais d'une table de types recopiée — une table qui divergerait le jour où une nature changerait de sens.
    // int montantUnites
    test('to test the property `montantUnites`', () async {
      // TODO
    });

    // Référence lisible de la commande, quand il y en a une.
    // String reference
    test('to test the property `reference`', () async {
      // TODO
    });

    // Nature : `avance` | `remboursement` | `indemnisation` | `correction` | `frais_encaisses` | `reglement` | `reversement`.
    // String typeEcriture
    test('to test the property `typeEcriture`', () async {
      // TODO
    });

  });
}
