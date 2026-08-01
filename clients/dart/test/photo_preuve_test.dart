import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PhotoPreuve
void main() {
  final instance = PhotoPreuveBuilder();
  // TODO add properties to the builder and call build()

  group(PhotoPreuve, () {
    // Photo.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Prise le.
    // DateTime priseLe
    test('to test the property `priseLe`', () async {
      // TODO
    });

    // Purgée le — la preuve reste **datée**, ses octets sont partis.
    // DateTime purgeeLe
    test('to test the property `purgeeLe`', () async {
      // TODO
    });

    // URL présignée de courte durée. Absente si purgée ou indisponible.
    // String url
    test('to test the property `url`', () async {
      // TODO
    });

  });
}
