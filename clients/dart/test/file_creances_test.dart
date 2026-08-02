import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for FileCreances
void main() {
  final instance = FileCreancesBuilder();
  // TODO add properties to the builder and call build()

  group(FileCreances, () {
    // Créances, la plus récente d'abord.
    // BuiltList<Creance> creances
    test('to test the property `creances`', () async {
      // TODO
    });

    // Somme des créances **dues** de la sélection — l'exposition de Mefali envers ses coursiers (FR-065).
    // int totalDuUnites
    test('to test the property `totalDuUnites`', () async {
      // TODO
    });

  });
}
