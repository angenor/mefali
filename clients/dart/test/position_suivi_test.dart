import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PositionSuivi
void main() {
  final instance = PositionSuiviBuilder();
  // TODO add properties to the builder and call build()

  group(PositionSuivi, () {
    // Ancienneté du relevé, en secondes. L'app affiche « il y a 12 s » et n'invente JAMAIS une position (FR-040, maquette C4-4d).
    // int ageS
    test('to test the property `ageS`', () async {
      // TODO
    });

    // Latitude.
    // double lat
    test('to test the property `lat`', () async {
      // TODO
    });

    // Longitude.
    // double lon
    test('to test the property `lon`', () async {
      // TODO
    });

  });
}
