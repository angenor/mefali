import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ArretCourse
void main() {
  final instance = ArretCourseBuilder();
  // TODO add properties to the builder and call build()

  group(ArretCourse, () {
    // Arrêt de la course.
    // String arretId
    test('to test the property `arretId`', () async {
      // TODO
    });

    // Arrivée sur l'arrêt.
    // DateTime arriveLe
    test('to test the property `arriveLe`', () async {
      // TODO
    });

    // Collecte validée.
    // DateTime collecteLe
    test('to test the property `collecteLe`', () async {
      // TODO
    });

    // Rayon max de scan (m).
    // int distanceMaxM
    test('to test the property `distanceMaxM`', () async {
      // TODO
    });

    // Distance depuis l'arrêt précédent (m). **Absente** : le tronçon n'est pas figé au devis et ce cycle ne recalcule aucun itinéraire (FR-009).
    // int distancePrecedentM
    test('to test the property `distancePrecedentM`', () async {
      // TODO
    });

    // base16(sha256(prestataire ‖ code)) — mode dégradé hors-ligne.
    // String empreinteCode
    test('to test the property `empreinteCode`', () async {
      // TODO
    });

    // base16(sha256(jeton)) — match hors-ligne du QR de plaque.
    // String empreinteJeton
    test('to test the property `empreinteJeton`', () async {
      // TODO
    });

    // Départ déclaré vers l'arrêt.
    // DateTime enRouteLe
    test('to test the property `enRouteLe`', () async {
      // TODO
    });

    // Articles à acheter chez ce vendeur.
    // BuiltList<LigneArret> lignes
    test('to test the property `lignes`', () async {
      // TODO
    });

    // Articles bruts, AVANT retenue — ce que le vendeur facture. Égal à `montant_avance` quand aucune livraison n'est offerte.
    // int montantArticlesUnites
    test('to test the property `montantArticlesUnites`', () async {
      // TODO
    });

    // Montant à avancer à CE vendeur, lignes retirées exclues (FR-013) et **retenue vendeur déduite** (VND-08, FR-092). C'est le chiffre que K3 affiche en gros : ce que Yao sort de sa poche au comptoir.
    // int montantAvance
    test('to test the property `montantAvance`', () async {
      // TODO
    });

    // Nom du vendeur.
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

    // Rang dans l'ordre optimisé.
    // int ordre
    test('to test the property `ordre`', () async {
      // TODO
    });

    // Photo de récupération exigée (politique résolue).
    // bool photoExigee
    test('to test the property `photoExigee`', () async {
      // TODO
    });

    // Prestataire visé.
    // String prestataireId
    test('to test the property `prestataireId`', () async {
      // TODO
    });

    // Part prise en charge par le vendeur (VND-08), `0` sinon. Non nulle, l'app affiche l'explication de l'écart plutôt qu'un net inexpliqué.
    // int retenueAppliqueeUnites
    test('to test the property `retenueAppliqueeUnites`', () async {
      // TODO
    });

    // Position attendue du site.
    // double siteLat
    test('to test the property `siteLat`', () async {
      // TODO
    });

    // Position attendue du site.
    // double siteLon
    test('to test the property `siteLon`', () async {
      // TODO
    });

    // `a_collecter` | `en_route` | `arrive` | `collecte` | `indisponible`.
    // String statut
    test('to test the property `statut`', () async {
      // TODO
    });

    // Contact du vendeur — appel HORS LIGNE (R6). Jamais journalisé.
    // String telephoneVendeur
    test('to test the property `telephoneVendeur`', () async {
      // TODO
    });

  });
}
