import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ResultatRemise
void main() {
  final instance = ResultatRemiseBuilder();
  // TODO add properties to the builder and call build()

  group(ResultatRemise, () {
    // Commande close.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Essais de code consommés (consolidés serveur + hors ligne).
    // int essaisCode
    test('to test the property `essaisCode`', () async {
      // TODO
    });

    // Livraison close.
    // String livraisonId
    test('to test the property `livraisonId`', () async {
      // TODO
    });

    // Mode retenu.
    // String modeRemise
    test('to test the property `modeRemise`', () async {
      // TODO
    });

    // `true` si l'appel n'était qu'un **rejeu** du même `uuid_client` : rien n'a été réécrit ni ré-émis (R4).
    // bool rejeu
    test('to test the property `rejeu`', () async {
      // TODO
    });

  });
}
