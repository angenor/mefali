import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ConfigZone
void main() {
  final instance = ConfigZoneBuilder();
  // TODO add properties to the builder and call build()

  group(ConfigZone, () {
    // Catégories actives dans la zone.
    // BuiltList<CategorieDto> categories
    test('to test the property `categories`', () async {
      // TODO
    });

    // Devise résolue.
    // DeviseDto devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Drapeaux (clés `drapeau.*` sans préfixe).
    // BuiltMap<String, bool> drapeaux
    test('to test the property `drapeaux`', () async {
      // TODO
    });

    // Paramètres client (clés `client.*` sans préfixe).
    // JsonObject parametres
    test('to test the property `parametres`', () async {
      // TODO
    });

    // Textes (clés `texte.*` sans préfixe) — clés i18n fr.
    // BuiltMap<String, String> textes
    test('to test the property `textes`', () async {
      // TODO
    });

    // Slugs des types de transport actifs.
    // BuiltList<String> transportsActifs
    test('to test the property `transportsActifs`', () async {
      // TODO
    });

    // Empreinte SHA-256 hex du document canonique (= ETag).
    // String version
    test('to test the property `version`', () async {
      // TODO
    });

    // Zone servie.
    // String zone
    test('to test the property `zone`', () async {
      // TODO
    });

  });
}
