import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for BasculeDisponibilite
void main() {
  final instance = BasculeDisponibiliteBuilder();
  // TODO add properties to the builder and call build()

  group(BasculeDisponibilite, () {
    // Vrai pour entrer dans le pool, faux pour en sortir **immédiatement**.
    // bool enLigne
    test('to test the property `enLigne`', () async {
      // TODO
    });

    // Ce que le coursier peut avancer aujourd'hui (unités mineures). Obligatoire pour se mettre en ligne, ignoré pour en sortir.
    // int plafondDeclareUnites
    test('to test the property `plafondDeclareUnites`', () async {
      // TODO
    });

  });
}
