import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for CommandesAdminApi
void main() {
  final instance = MefaliApiClient().getCommandesAdminApi();

  group(CommandesAdminApi, () {
    // CMD-10 — file FIFO des commandes sans coursier d'une zone.
    //
    // L'ordre est l'âge, du plus ancien au plus récent : c'est la promesse produite au client qui attend (« la plus ancienne repart en premier »), et c'est le contrat que **DSP** consommera tel quel.
    //
    //Future<FileAttenteCoursier> fileAttente(String zoneId) async
    test('test fileAttente', () async {
      // TODO
    });

  });
}
