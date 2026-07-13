import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for SocleApi
void main() {
  final instance = MefaliApiClient().getSocleApi();

  group(SocleApi, () {
    // Sonde de vie du service. Répond `200 {status:\"ok\", version}`.
    //
    //Future<HealthResponse> health() async
    test('test health', () async {
      // TODO
    });

  });
}
