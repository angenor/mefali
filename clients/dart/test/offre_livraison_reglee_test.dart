import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for OffreLivraisonReglee
void main() {
  final instance = OffreLivraisonRegleeBuilder();
  // TODO add properties to the builder and call build()

  group(OffreLivraisonReglee, () {
    // Rappel en clair que les commandes en cours ne bougent pas (FR-048).
    // String messageCle
    test('to test the property `messageCle`', () async {
      // TODO
    });

    // `jamais` | `toujours` | `au_dela`.
    // String offre
    test('to test the property `offre`', () async {
      // TODO
    });

    // Seuil déclaré (`null` hors `au_dela`).
    // int seuilUnites
    test('to test the property `seuilUnites`', () async {
      // TODO
    });

  });
}
