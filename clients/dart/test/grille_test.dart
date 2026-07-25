import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for Grille
void main() {
  final instance = GrilleBuilder();
  // TODO add properties to the builder and call build()

  group(Grille, () {
    // Entrée en vigueur (posée à la publication).
    // DateTime effetLe
    test('to test the property `effetLe`', () async {
      // TODO
    });

    // `brouillon` | `en_vigueur` | `historique`.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Identifiant.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Règles, triées par identifiant (ordre stable).
    // BuiltList<Regle> regles
    test('to test the property `regles`', () async {
      // TODO
    });

    // **Publiable** : la simulation porte sur le contenu EXACT du brouillon. Repasse à `false` dès qu'une règle est éditée (FR-021).
    // bool simulee
    test('to test the property `simulee`', () async {
      // TODO
    });

    // Dernière simulation réussie.
    // DateTime simuleeLe
    test('to test the property `simuleeLe`', () async {
      // TODO
    });

    // Version.
    // int version
    test('to test the property `version`', () async {
      // TODO
    });

    // Zone tarifée.
    // String zoneId
    test('to test the property `zoneId`', () async {
      // TODO
    });

  });
}
