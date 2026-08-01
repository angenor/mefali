import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for QrApi
void main() {
  final instance = MefaliApiClient().getQrApi();

  group(QrApi, () {
    // QRC-02/03/04 — collecte un arrêt (multipart : `demande` JSON + `photo`).
    //
    //Future<ResultatCollecte> collecter(String arretId, DemandeCollecte demande, { MultipartFile photo }) async
    test('test collecter', () async {
      // TODO
    });

    // QRC-01 — télécharge (génère au besoin) le PDF de plaque d'un prestataire.
    //
    //Future<PlaqueUrl> telechargerPlaque(String id) async
    test('test telechargerPlaque', () async {
      // TODO
    });

  });
}
