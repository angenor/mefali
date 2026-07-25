import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PaiementCommande
void main() {
  final instance = PaiementCommandeBuilder();
  // TODO add properties to the builder and call build()

  group(PaiementCommande, () {
    // Appoint exact à préparer (cash) — le total, en une fois. Aucun chemin de règlement fractionné n'existe (constitution III).
    // int appointExactUnites
    test('to test the property `appointExactUnites`', () async {
      // TODO
    });

    // `du` | `en_attente` | `regle` | `rembourse`.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Mode retenu.
    // String mode
    test('to test the property `mode`', () async {
      // TODO
    });

  });
}
