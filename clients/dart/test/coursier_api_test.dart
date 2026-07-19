import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for CoursierApi
void main() {
  final instance = MefaliApiClient().getCoursierApi();

  group(CoursierApi, () {
    // Signale un article introuvable — REFUSÉ (et compté nulle part) sans commande active comportant un arrêt chez ce prestataire (FR-038).
    //
    //Future<SignalementRecuDto> signalerRupture(String idempotencyKey, SignalerRuptureDto signalerRuptureDto) async
    test('test signalerRupture', () async {
      // TODO
    });

  });
}
