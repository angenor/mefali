import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeRupture
void main() {
  final instance = DemandeRuptureBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeRupture, () {
    // Article proposé — obligatoire pour `remplacer`, **du même vendeur**.
    // String articleProposeId
    test('to test the property `articleProposeId`', () async {
      // TODO
    });

    // Ligne de commande devenue indisponible.
    // String ligneId
    test('to test the property `ligneId`', () async {
      // TODO
    });

    // Prix unitaire proposé (unités mineures) — obligatoire pour `remplacer`.
    // int prixProposeUnites
    test('to test the property `prixProposeUnites`', () async {
      // TODO
    });

    // `retirer` | `remplacer`. Absent = suivre la préférence du client, dont le défaut sûr est le retrait : on ne fait jamais payer par défaut.
    // String resolution
    test('to test the property `resolution`', () async {
      // TODO
    });

    // Clé d'idempotence (UUIDv7 client, constitution V).
    // String uuidClient
    test('to test the property `uuidClient`', () async {
      // TODO
    });

  });
}
