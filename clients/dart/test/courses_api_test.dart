import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for CoursesApi
void main() {
  final instance = MefaliApiClient().getCoursesApi();

  group(CoursesApi, () {
    // CMD-04 — le coursier déclare son ARRIVÉE sur un arrêt.
    //
    // `arrive_le` est posé par le serveur : c'est la borne de départ de l'attente facturable (prime TRF-06). C'est pour cela que `en_route → collecte` n'existe pas — on ne saute pas une déclaration qui vaut de l'argent.
    //
    //Future<EtatArretCourse> arretArrive(String livraisonId, String arretId, ActionArret actionArret) async
    test('test arretArrive', () async {
      // TODO
    });

    // CMD-04 — le coursier déclare partir vers un arrêt.
    //
    // Le PREMIER départ d'une course la fait passer EN_COLLECTE (data-model §3.2).
    //
    //Future<EtatArretCourse> arretEnRoute(String livraisonId, String arretId, ActionArret actionArret) async
    test('test arretEnRoute', () async {
      // TODO
    });

    // CMD-04/CMD-06 — arrêt entièrement indisponible (FR-051).
    //
    // Vendeur fermé, ou plus une seule ligne à collecter. L'arrêt est compté **résolu** (la course continue), son montant avancé retombe à zéro, et ses lignes sont retirées de la commande — les frais de livraison, eux, ne bougent pas (FR-050).
    //
    //Future<EtatArretCourse> arretIndisponible(String livraisonId, String arretId, ActionArret actionArret) async
    test('test arretIndisponible', () async {
      // TODO
    });

  });
}
