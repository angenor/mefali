import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for MoiApi
void main() {
  final instance = MefaliApiClient().getMoiApi();

  group(MoiApi, () {
    // Appareils/sessions actifs du compte (FR-008).
    //
    //Future<BuiltList<SessionAppareil>> mesSessions() async
    test('test mesSessions', () async {
      // TODO
    });

    // Compte courant et états de TOUS ses rôles.
    //
    //Future<CompteMoi> moi() async
    test('test moi', () async {
      // TODO
    });

    // Déconnexion à distance d'un appareil (SC-004).
    //
    //Future revoquerSession(String sessionId) async
    test('test revoquerSession', () async {
      // TODO
    });

  });
}
