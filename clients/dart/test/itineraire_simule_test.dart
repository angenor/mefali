import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ItineraireSimule
void main() {
  final instance = ItineraireSimuleBuilder();
  // TODO add properties to the builder and call build()

  group(ItineraireSimule, () {
    // Vrai si la distance vient du repli vol d'oiseau × facteur de zone.
    // bool degraded
    test('to test the property `degraded`', () async {
      // TODO
    });

    // Distance routière totale (mètres).
    // int distanceM
    test('to test the property `distanceM`', () async {
      // TODO
    });

    // Durée estimée (secondes).
    // int etaS
    test('to test the property `etaS`', () async {
      // TODO
    });

    // Vrai si l'ordre est le meilleur de TOUTES les permutations (≤ 4 arrêts) ; faux si l'heuristique bornée a tranché (FR-031).
    // bool exhaustif
    test('to test the property `exhaustif`', () async {
      // TODO
    });

    // Indices des vendeurs dans l'ordre de passage.
    // BuiltList<int> ordre
    test('to test the property `ordre`', () async {
      // TODO
    });

  });
}
