import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeEchec
void main() {
  final instance = DemandeEchecBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeEchec, () {
    // Arrêt concerné — absent = à la remise.
    // String arretId
    test('to test the property `arretId`', () async {
      // TODO
    });

    // Clé i18n du motif — jamais du texte libre.
    // String motifCle
    test('to test the property `motifCle`', () async {
      // TODO
    });

    // Ligne de l'arbre §7.5 (`refus_perissable`, `faux_billet`…).
    // String typeIssue
    test('to test the property `typeIssue`', () async {
      // TODO
    });

    // Clé d'idempotence (UUIDv7 produit par l'app, constitution V).  **Obligatoire** depuis CRS 010 : un échec déclaré sans réseau se rejoue jusqu'à acquittement, et sans elle l'arbre §7.5 se déroulait deux fois — deux sanctions, deux indemnisations, deux litiges (R4).
    // String uuidClient
    test('to test the property `uuidClient`', () async {
      // TODO
    });

  });
}
