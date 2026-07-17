import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for AdminApi
void main() {
  final instance = MefaliApiClient().getAdminApi();

  group(AdminApi, () {
    // Décision admin sur un rôle — machine à états de data-model §4, journalisée.
    //
    //Future<EtatRoleDto> deciderRole(String compteId, String role, DecisionRole decisionRole) async
    test('test deciderRole', () async {
      // TODO
    });

  });
}
