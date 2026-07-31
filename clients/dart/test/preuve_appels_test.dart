import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PreuveAppels
void main() {
  final instance = PreuveAppelsBuilder();
  // TODO add properties to the builder and call build()

  group(PreuveAppels, () {
    // Faux dès qu'un appel a été écarté pour cause d'espacement.
    // bool espacementOk
    test('to test the property `espacementOk`', () async {
      // TODO
    });

    // Appels `client_absent` **retenus** (espacement respecté).
    // int faits
    test('to test the property `faits`', () async {
      // TODO
    });

    // Horodatages **serveur** des appels retenus (affichage K4-1e).
    // BuiltList<DateTime> horodatages
    test('to test the property `horodatages`', () async {
      // TODO
    });

    // Issues DÉCLARÉES par le coursier — affichées, jamais un critère (R19).
    // BuiltList<String> issues
    test('to test the property `issues`', () async {
      // TODO
    });

    // Pourquoi elle ne l'est pas — clé i18n.
    // String motifCle
    test('to test the property `motifCle`', () async {
      // TODO
    });

    // Preuve réunie.
    // bool ok
    test('to test the property `ok`', () async {
      // TODO
    });

    // Appels exigés par la zone.
    // int requis
    test('to test the property `requis`', () async {
      // TODO
    });

  });
}
