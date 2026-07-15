import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ModifierAdresse
void main() {
  final instance = ModifierAdresseBuilder();
  // TODO add properties to the builder and call build()

  group(ModifierAdresse, () {
    // Nouveau libellé — absent = inchangé.
    // String libelle
    test('to test the property `libelle`', () async {
      // TODO
    });

    // Nouveau repère écrit — absent = inchangé, `null` = effacé.  Le double `Option` porte cette nuance : sans lui, « ne touche pas » et « efface » seraient le même corps JSON.
    // String repereTexte
    test('to test the property `repereTexte`', () async {
      // TODO
    });

  });
}
