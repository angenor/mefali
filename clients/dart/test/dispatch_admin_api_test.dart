import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for DispatchAdminApi
void main() {
  final instance = MefaliApiClient().getDispatchAdminApi();

  group(DispatchAdminApi, () {
    // `GET /admin/dispatch/alertes` — ce qui demande un humain.
    //
    //Future<AlertesDispatch> alertesDispatch() async
    test('test alertesDispatch', () async {
      // TODO
    });

    // `GET /admin/dispatch/pool` — les coursiers en ligne d'une zone.
    //
    // Matière de la « carte des coursiers » d'ADM-02. Le rôle `Admin` est la garde : c'est le seul endroit du cycle où une position sort du serveur.
    //
    //Future<PoolDeZone> poolDispatch(String zoneId) async
    test('test poolDispatch', () async {
      // TODO
    });

    // `POST /admin/dispatch/courses/{livraison_id}/reprendre` — la seule voie de reprise d'une course dont un arrêt est **déjà collecté**.
    //
    // L'automatisme s'y refuse par construction (FR-075), parce que le coursier a engagé ses fonds propres. Cet endpoint n'annule aucune dette et n'écrit aucune caisse : il émet `dispatch.reassignation` avec `acteur: admin` et laisse la caisse (CRS-06) et le litige (AVI-04) à leurs cycles.  `422` si aucun arrêt n'est collecté — dans ce cas l'automatisme suffit, et une action manuelle masquerait un défaut de pipeline.
    //
    //Future<RepriseFaite> reprendreCourseAdmin(String livraisonId, DemandeReprise demandeReprise) async
    test('test reprendreCourseAdmin', () async {
      // TODO
    });

  });
}
