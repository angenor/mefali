import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for RegleUpsert
void main() {
  final instance = RegleUpsertBuilder();
  // TODO add properties to the builder and call build()

  group(RegleUpsert, () {
    // Règle active à l'évaluation.
    // bool actif
    test('to test the property `actif`', () async {
      // TODO
    });

    // Slug de catégorie, `null` = toutes catégories.
    // String categorieSlug
    test('to test the property `categorieSlug`', () async {
      // TODO
    });

    // Devise ISO 4217 — DOIT égaler celle de la zone (FR-023).
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Borne haute INCLUSE, `null` = +∞.
    // int distanceMaxM
    test('to test the property `distanceMaxM`', () async {
      // TODO
    });

    // Borne basse de la tranche de distance routière (mètres).
    // int distanceMinM
    test('to test the property `distanceMinM`', () async {
      // TODO
    });

    // Masque de jours (bit 0 = lundi … bit 6 = dimanche), `null` = tous.
    // int joursMasque
    test('to test the property `joursMasque`', () async {
      // TODO
    });

    // Marge Mefali — DOIT être dans les bornes de la zone (FR-009).
    // int marge
    test('to test the property `marge`', () async {
      // TODO
    });

    // Part coursier de base (unités mineures).
    // int partCoursierBase
    test('to test the property `partCoursierBase`', () async {
      // TODO
    });

    // Début de plage horaire (minutes depuis minuit, fuseau de la zone).
    // int plageDebutMin
    test('to test the property `plageDebutMin`', () async {
      // TODO
    });

    // Fin de plage horaire (exclue).
    // int plageFinMin
    test('to test the property `plageFinMin`', () async {
      // TODO
    });

    // Priorité de départage.
    // int priorite
    test('to test the property `priorite`', () async {
      // TODO
    });

    // Prix par kilomètre au-delà du seuil (abonde client ET coursier).
    // int prixParKm
    test('to test the property `prixParKm`', () async {
      // TODO
    });

    // Plafond du prix client, `null` = aucun.
    // int prixPlafond
    test('to test the property `prixPlafond`', () async {
      // TODO
    });

    // Seuil (mètres) au-delà duquel le kilométrage est facturé.
    // int seuilKmM
    test('to test the property `seuilKmM`', () async {
      // TODO
    });

    // Slug du véhicule (référentiel `zones.type_transport`).
    // String transportSlug
    test('to test the property `transportSlug`', () async {
      // TODO
    });

  });
}
