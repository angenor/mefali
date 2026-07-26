import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for CoursierSuivi
void main() {
  final instance = CoursierSuiviBuilder();
  // TODO add properties to the builder and call build()

  group(CoursierSuivi, () {
    // Vrai si l'app peut proposer d'appeler.
    // bool appelPossible
    test('to test the property `appelPossible`', () async {
      // TODO
    });

    // Identifiant du coursier.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Note moyenne — **toujours `null` ce cycle** : les avis appartiennent au cycle AVI, qui n'existe pas encore.
    // double note
    test('to test the property `note`', () async {
      // TODO
    });

    // Prénom — **toujours `null` ce cycle** : `comptes.compte` ne porte aucun nom (cycle CPT), et rien ne sera inventé pour remplir un champ.
    // String prenom
    test('to test the property `prenom`', () async {
      // TODO
    });

  });
}
