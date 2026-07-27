import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for EscaladeDispatch
void main() {
  final instance = EscaladeDispatchBuilder();
  // TODO add properties to the builder and call build()

  group(EscaladeDispatch, () {
    // Ancienneté au moment de l'escalade (secondes).
    // int ageS
    test('to test the property `ageS`', () async {
      // TODO
    });

    // Par quel chemin elle est arrivée là : `file` | `pipeline`.
    // String chemin
    test('to test the property `chemin`', () async {
      // TODO
    });

    // Commande concernée.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // État courant du tronc.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Nombre d'offres déjà émises pour elle.
    // int nbOffresEmises
    test('to test the property `nbOffresEmises`', () async {
      // TODO
    });

    // Seuil de zone franchi (secondes).
    // int seuilS
    test('to test the property `seuilS`', () async {
      // TODO
    });

    // Zone de la commande.
    // String zoneId
    test('to test the property `zoneId`', () async {
      // TODO
    });

  });
}
