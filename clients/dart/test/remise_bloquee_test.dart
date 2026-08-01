import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for RemiseBloquee
void main() {
  final instance = RemiseBloqueeBuilder();
  // TODO add properties to the builder and call build()

  group(RemiseBloquee, () {
    // Instant du blocage — **l'ordre de la liste**, le plus ancien d'abord.
    // DateTime bloqueLe
    test('to test the property `bloqueLe`', () async {
      // TODO
    });

    // Commande verrouillée.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Coursier assigné, s'il l'est encore.
    // String coursierId
    test('to test the property `coursierId`', () async {
      // TODO
    });

    // Essais consommés au blocage.
    // int essaisCode
    test('to test the property `essaisCode`', () async {
      // TODO
    });

    // Livraison portée — celle où le coursier est resté devant la porte.
    // String livraisonId
    test('to test the property `livraisonId`', () async {
      // TODO
    });

    // Référence courte, pour se parler au téléphone.
    // String reference
    test('to test the property `reference`', () async {
      // TODO
    });

    // Zone de la commande.
    // String zoneId
    test('to test the property `zoneId`', () async {
      // TODO
    });

  });
}
