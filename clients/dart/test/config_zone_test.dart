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

    // Version du texte de consentement ARTCI en vigueur — l'app l'affiche et la renvoie telle quelle à l'inscription (FR-006). `null` si non résolue.
    // String consentementArtciVersion
    test('to test the property `consentementArtciVersion`', () async {
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

    // Durée maximale d'une note vocale, en secondes — borne l'enregistreur des apps (FR-019). `null` si la zone ne la résout pas.
    // int noteVocaleDureeMaxS
    test('to test the property `noteVocaleDureeMaxS`', () async {
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
