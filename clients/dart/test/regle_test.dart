import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for Regle
void main() {
  final instance = RegleBuilder();
  // TODO add properties to the builder and call build()

  group(Regle, () {
    // Active.
    // bool actif
    test('to test the property `actif`', () async {
      // TODO
    });

    // Catégorie, `null` = toutes.
    // String categorieSlug
    test('to test the property `categorieSlug`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Borne haute incluse.
    // int distanceMaxM
    test('to test the property `distanceMaxM`', () async {
      // TODO
    });

    // Borne basse de tranche (mètres).
    // int distanceMinM
    test('to test the property `distanceMinM`', () async {
      // TODO
    });

    // Identifiant.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Masque de jours.
    // int joursMasque
    test('to test the property `joursMasque`', () async {
      // TODO
    });

    // Marge Mefali.
    // int marge
    test('to test the property `marge`', () async {
      // TODO
    });

    // Part coursier de base.
    // int partCoursierBase
    test('to test the property `partCoursierBase`', () async {
      // TODO
    });

    // Début de plage horaire.
    // int plageDebutMin
    test('to test the property `plageDebutMin`', () async {
      // TODO
    });

    // Fin de plage horaire.
    // int plageFinMin
    test('to test the property `plageFinMin`', () async {
      // TODO
    });

    // Priorité.
    // int priorite
    test('to test the property `priorite`', () async {
      // TODO
    });

    // Prix client de base DÉRIVÉ (`part_coursier_base + marge`) — jamais stocké, servi pour que l'admin lise le tarif sans le recalculer.
    // int prixClientBase
    test('to test the property `prixClientBase`', () async {
      // TODO
    });

    // Prix par km au-delà du seuil.
    // int prixParKm
    test('to test the property `prixParKm`', () async {
      // TODO
    });

    // Plafond du prix client.
    // int prixPlafond
    test('to test the property `prixPlafond`', () async {
      // TODO
    });

    // Seuil de kilométrage facturé (mètres).
    // int seuilKmM
    test('to test the property `seuilKmM`', () async {
      // TODO
    });

    // Véhicule.
    // String transportSlug
    test('to test the property `transportSlug`', () async {
      // TODO
    });

  });
}
