import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for HealthResponse
void main() {
  final instance = HealthResponseBuilder();
  // TODO add properties to the builder and call build()

  group(HealthResponse, () {
    // Toujours `\"ok\"` quand le processus répond.
    // String status
    test('to test the property `status`', () async {
      // TODO
    });

    // Version du binaire (`CARGO_PKG_VERSION`).
    // String version
    test('to test the property `version`', () async {
      // TODO
    });

  });
}
