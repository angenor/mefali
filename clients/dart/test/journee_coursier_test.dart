import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for JourneeCoursier
void main() {
  final instance = JourneeCoursierBuilder();
  // TODO add properties to the builder and call build()

  group(JourneeCoursier, () {
    // Argent encore dehors, à l'origine de l'amputation ci-dessus.
    // int avancesEnCoursUnites
    test('to test the property `avancesEnCoursUnites`', () async {
      // TODO
    });

    // Courses dont la remise est validée dans le jour civil **de la zone**.
    // int coursesLivrees
    test('to test the property `coursesLivrees`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Somme des parts coursier de ces courses (devis FIGÉ du cycle 007).
    // int gainsUnites
    test('to test the property `gainsUnites`', () async {
      // TODO
    });

    // **Toujours `null`** tant qu'AVI n'est pas construit (FR-094) : l'absence vaut mieux qu'un chiffre inventé.
    // int noteCentiemes
    test('to test the property `noteCentiemes`', () async {
      // TODO
    });

    // Plafond d'avance qui s'applique — `min(déclaré, palier de la grille)`.
    // int plafondRetenuUnites
    test('to test the property `plafondRetenuUnites`', () async {
      // TODO
    });

    // Ce qu'il reste engageable : plafond retenu **moins** avances en cours (FR-095). Jamais négatif — un « reste » négatif ne veut rien dire à l'écran ; l'écart, lui, est signalé par la caisse (FR-078).
    // int resteDisponibleUnites
    test('to test the property `resteDisponibleUnites`', () async {
      // TODO
    });

    // Taux d'acceptation tenu par le dispatch, ou `null` si aucune offre décidable n'a été émise sur la fenêtre (FR-093).
    // int tauxAcceptationPourcent
    test('to test the property `tauxAcceptationPourcent`', () async {
      // TODO
    });

  });
}
