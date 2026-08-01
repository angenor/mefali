import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DecisionIndemnisation
void main() {
  final instance = DecisionIndemnisationBuilder();
  // TODO add properties to the builder and call build()

  group(DecisionIndemnisation, () {
    // Clé i18n du motif — **obligatoire au refus** (FR-072). Un refus sans raison rend la promesse d'indemnisation invérifiable.
    // String motifCle
    test('to test the property `motifCle`', () async {
      // TODO
    });

  });
}
