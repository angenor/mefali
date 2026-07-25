import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for EtatArretCourse
void main() {
  final instance = EtatArretCourseBuilder();
  // TODO add properties to the builder and call build()

  group(EtatArretCourse, () {
    // Arrêt concerné.
    // String arretId
    test('to test the property `arretId`', () async {
      // TODO
    });

    // Collectes déjà faites (la remise n'en est pas une).
    // int collectesFaites
    test('to test the property `collectesFaites`', () async {
      // TODO
    });

    // Nombre total de COLLECTES de la course.
    // int collectesTotal
    test('to test the property `collectesTotal`', () async {
      // TODO
    });

    // Commande ancre.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Vrai si la course vient de basculer EN_LIVRAISON.
    // bool enLivraison
    test('to test the property `enLivraison`', () async {
      // TODO
    });

    // État de la livraison : `assignee` | `en_collecte` | `en_livraison`.
    // String livraisonEtat
    test('to test the property `livraisonEtat`', () async {
      // TODO
    });

    // Livraison porteuse.
    // String livraisonId
    test('to test the property `livraisonId`', () async {
      // TODO
    });

    // Vrai si l'appel était un rejeu du même `uuid_client` : rien n'a été réécrit, aucun événement n'a été ré-émis.
    // bool rejeu
    test('to test the property `rejeu`', () async {
      // TODO
    });

    // Statut de l'arrêt : `en_route` | `arrive` | `indisponible`.
    // String statut
    test('to test the property `statut`', () async {
      // TODO
    });

  });
}
