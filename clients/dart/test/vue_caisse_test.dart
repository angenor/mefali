import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for VueCaisse
void main() {
  final instance = VueCaisseBuilder();
  // TODO add properties to the builder and call build()

  group(VueCaisse, () {
    // Argent avancé et non encore récupéré (FR-067) — toujours positif.
    // int avanceEnCoursUnites
    test('to test the property `avanceEnCoursUnites`', () async {
      // TODO
    });

    // Part que le cash ne soldera jamais (commandes prépayées, R10, FR-117).
    // int avancesEnAttenteReglementUnites
    test('to test the property `avancesEnAttenteReglementUnites`', () async {
      // TODO
    });

    // Combien de courses portent cette avance.
    // int coursesConcernees
    test('to test the property `coursesConcernees`', () async {
      // TODO
    });

    // Devise ISO 4217 de la zone.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Les avances en cours dépassent le plafond déclaré du jour (FR-078).
    // bool ecartPlafond
    test('to test the property `ecartPlafond`', () async {
      // TODO
    });

    // Historique du jour civil **de la zone**.
    // BuiltList<LigneHistoriqueCaisse> historiqueDuJour
    test('to test the property `historiqueDuJour`', () async {
      // TODO
    });

    // Indemnisations rattachées.
    // BuiltList<IndemnisationVue> indemnisations
    test('to test the property `indemnisations`', () async {
      // TODO
    });

    // Litiges en cours — vide tant qu'AVI-04 n'existe pas.
    // BuiltList<LitigeVu> litigesEnCours
    test('to test the property `litigesEnCours`', () async {
      // TODO
    });

    // Mouvements du livre du jour, du plus récent au plus ancien.
    // BuiltList<MouvementCaisse> mouvements
    test('to test the property `mouvements`', () async {
      // TODO
    });

  });
}
