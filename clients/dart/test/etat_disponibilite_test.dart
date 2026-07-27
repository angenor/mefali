import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for EtatDisponibilite
void main() {
  final instance = EtatDisponibiliteBuilder();
  // TODO add properties to the builder and call build()

  group(EtatDisponibilite, () {
    // Capacités déclarées au dossier coursier.
    // BuiltList<CapaciteCoursier> capacites
    test('to test the property `capacites`', () async {
      // TODO
    });

    // Vrai seulement après une position publiée : l'intention ne suffit pas.
    // bool dansLePool
    test('to test the property `dansLePool`', () async {
      // TODO
    });

    // Devise ISO 4217 de la zone.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Intention déclarée aujourd'hui.
    // bool enLigne
    test('to test the property `enLigne`', () async {
      // TODO
    });

    // Jour civil de la déclaration.
    // String jour
    test('to test the property `jour`', () async {
      // TODO
    });

    // Note du coursier, ou `null` tant qu'AVI n'existe pas.
    // int noteCentiemes
    test('to test the property `noteCentiemes`', () async {
      // TODO
    });

    // Clé i18n du palier appliqué.
    // String palierNoteCle
    test('to test the property `palierNoteCle`', () async {
      // TODO
    });

    // Période de publication attendue (paramètre de zone du cycle 008).
    // int periodePositionS
    test('to test the property `periodePositionS`', () async {
      // TODO
    });

    // Plafond déclaré du jour, ou `null` si rien n'a été déclaré (FR-011 : jamais reporté — l'app le redemande au nouveau jour).
    // int plafondDeclareUnites
    test('to test the property `plafondDeclareUnites`', () async {
      // TODO
    });

    // Ce qui s'applique : `min(déclaré, palier de la grille)`.
    // int plafondRetenuUnites
    test('to test the property `plafondRetenuUnites`', () async {
      // TODO
    });

    // `grille_note` | `declaration`.
    // String plafondSource
    test('to test the property `plafondSource`', () async {
      // TODO
    });

  });
}
