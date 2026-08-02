import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for RegistreTransactions
void main() {
  final instance = RegistreTransactionsBuilder();
  // TODO add properties to the builder and call build()

  group(RegistreTransactions, () {
    // Somme des montants **réglés** de la sélection — ce que le fournisseur doit avoir encaissé.
    // int totalRegleUnites
    test('to test the property `totalRegleUnites`', () async {
      // TODO
    });

    // Lignes, la plus récente d'abord.
    // BuiltList<LigneRegistre> transactions
    test('to test the property `transactions`', () async {
      // TODO
    });

  });
}
