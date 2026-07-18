import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for VendeurApi
void main() {
  final instance = MefaliApiClient().getVendeurApi();

  group(VendeurApi, () {
    // Prestataires que ce compte pilote (rattachements du cycle VND).
    //
    //Future<BuiltList<PrestatairePilotable>> mesPrestataires() async
    test('test mesPrestataires', () async {
      // TODO
    });

  });
}
