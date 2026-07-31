import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for AppelJournalise
void main() {
  final instance = AppelJournaliseBuilder();
  // TODO add properties to the builder and call build()

  group(AppelJournalise, () {
    // Appel.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Issue DÉCLARÉE par le coursier — affichée, jamais un critère (R19).
    // String issue
    test('to test the property `issue`', () async {
      // TODO
    });

    // `suivi` | `substitution` | `client_absent`.
    // String motif
    test('to test the property `motif`', () async {
      // TODO
    });

    // Horodatage **serveur** — celui qui fonde l'espacement.
    // DateTime passeLe
    test('to test the property `passeLe`', () async {
      // TODO
    });

    // Horodatage de l'appareil — observation seulement.
    // DateTime passeLeLocal
    test('to test the property `passeLeLocal`', () async {
      // TODO
    });

    // Prestataire appelé (si `vers = vendeur`).
    // String prestataireId
    test('to test the property `prestataireId`', () async {
      // TODO
    });

    // `client` | `vendeur`. **Aucun numéro** — le serveur n'en a jamais vu.
    // String vers
    test('to test the property `vers`', () async {
      // TODO
    });

  });
}
