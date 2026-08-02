import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for PaiementsAdminApi
void main() {
  final instance = MefaliApiClient().getPaiementsAdminApi();

  group(PaiementsAdminApi, () {
    // Clôt un dossier, avec motif (FR-082).
    //
    //Future<DossierPaiement> cloreDossier(String id, CloreDossierDto cloreDossierDto) async
    test('test cloreDossier', () async {
      // TODO
    });

    // File des créances de coursiers (FR-083).
    //
    //Future<FileCreances> fileCreances({ String etat, String coursierId }) async
    test('test fileCreances', () async {
      // TODO
    });

    // File des anomalies d'argent (FR-082).
    //
    //Future<FileDossiers> fileDossiers({ String etat, String type }) async
    test('test fileDossiers', () async {
      // TODO
    });

    // Registre filtrable des transactions de paiement (FR-080, FR-081).
    //
    //Future<RegistreTransactions> registreTransactions({ String etat, String moyen, String commandeId, DateTime depuis, DateTime jusquA }) async
    test('test registreTransactions', () async {
      // TODO
    });

    // Marque une créance réglée et écrit son mouvement de caisse (FR-067).
    //
    //Future<Creance> reglerCreance(String id, ReglerCreanceDto reglerCreanceDto) async
    test('test reglerCreance', () async {
      // TODO
    });

  });
}
