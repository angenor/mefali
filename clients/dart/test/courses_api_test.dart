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

    // CMD-08 — le coursier déclare l'échec ; le serveur déroule l'arbre §7.5.
    //
    // **Refusé sans preuves** (`409 preuves_incompletes`, FR-056) : « le coursier ne perd jamais » suppose une trace — appels via l'app espacés, présence géolocalisée, photo sur place. Sans elle, la promesse deviendrait une invitation.
    //
    //Future<IssueEchec> declarerEchec(String livraisonId, DemandeEchec demandeEchec) async
    test('test declarerEchec', () async {
      // TODO
    });

    // CMD-06 — le coursier déclare un article indisponible et applique la préférence du client (FR-044/045).
    //
    // Trois chemins, deux invariants : le **devis de livraison ne bouge jamais** (FR-050) et le total reste payé **en une fois** (FR-049). La proposition de remplacement est refusée si l'article vient d'un **autre vendeur** (FR-048) ou si l'écart de prix dépasse le plafond de zone (FR-047).
    //
    //Future<IssueRupture> declarerRupture(String livraisonId, DemandeRupture demande, { MultipartFile photo }) async
    test('test declarerRupture', () async {
      // TODO
    });

    // CMD-08 — remise au client : QR, code de secours, ou dépôt convenu.
    //
    // ⚠ Le coursier ne reçoit **JAMAIS** le code (research R6) : il en a l'empreinte, et c'est le client qui le lui dicte. La comparaison a lieu côté serveur, sur la valeur stockée.  Trois codes faux et le code est **verrouillé** (`423`) jusqu'à intervention admin : quatre chiffres se devinent en quelques minutes sans plafond.
    //
    //Future<ResultatRemise> remise(String livraisonId, DemandeRemise demandeRemise) async
    test('test remise', () async {
      // TODO
    });

  });
}
