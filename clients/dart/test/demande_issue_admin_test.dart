import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeIssueAdmin
void main() {
  final instance = DemandeIssueAdminBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeIssueAdmin, () {
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

  });
}
