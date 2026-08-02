import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for LigneRecu
void main() {
  final instance = LigneRecuBuilder();
  // TODO add properties to the builder and call build()

  group(LigneRecu, () {
    // Libellé de l'article (celui du remplaçant si un remplacement a été accepté).
    // String libelle
    test('to test the property `libelle`', () async {
      // TODO
    });

    // Prix unitaire figé à la création (unités mineures).
    // int prixUnitaire
    test('to test the property `prixUnitaire`', () async {
      // TODO
    });

    // Quantité commandée.
    // int quantite
    test('to test the property `quantite`', () async {
      // TODO
    });

    // Sous-total — **0** sur une ligne retirée.
    // int sousTotalUnites
    test('to test the property `sousTotalUnites`', () async {
      // TODO
    });

    // `presente` | `remplacee` | `retiree`.
    // String statut
    test('to test the property `statut`', () async {
      // TODO
    });

  });
}
