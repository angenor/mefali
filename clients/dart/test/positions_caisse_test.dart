import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PositionsCaisse
void main() {
  final instance = PositionsCaisseBuilder();
  // TODO add properties to the builder and call build()

  group(PositionsCaisse, () {
    // Σ avances non compensées par un remboursement.
    // int avanceNonRecupereeUnites
    test('to test the property `avanceNonRecupereeUnites`', () async {
      // TODO
    });

    // Marge encaissée non reversée — **0 au MVP** (marge nulle jusqu'à M4). S'affiche quand même : une position absente se lirait comme une position oubliée.
    // int detenuPourMefaliUnites
    test('to test the property `detenuPourMefaliUnites`', () async {
      // TODO
    });

    // Σ créances dues.
    // int duParMefaliUnites
    test('to test the property `duParMefaliUnites`', () async {
      // TODO
    });

  });
}
