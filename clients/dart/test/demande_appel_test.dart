import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeAppel
void main() {
  final instance = DemandeAppelBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeAppel, () {
    // Issue DÉCLARÉE : `inconnue` | `sans_reponse` | `repondu`. Facultative — le serveur ne voit pas l'appel, il ne peut que la recevoir (R19).
    // String issue
    test('to test the property `issue`', () async {
      // TODO
    });

    // `suivi` | `substitution` | `client_absent`. **Seul `client_absent` compte** pour la preuve d'échec (FR-035).
    // String motif
    test('to test the property `motif`', () async {
      // TODO
    });

    // Horodatage de l'appareil — observation seulement.
    // DateTime passeLeLocal
    test('to test the property `passeLeLocal`', () async {
      // TODO
    });

    // Prestataire appelé — obligatoire si `vers = vendeur`.
    // String prestataireId
    test('to test the property `prestataireId`', () async {
      // TODO
    });

    // Clé d'idempotence (UUIDv7 client, constitution V).
    // String uuidClient
    test('to test the property `uuidClient`', () async {
      // TODO
    });

    // `client` | `vendeur`.
    // String vers
    test('to test the property `vers`', () async {
      // TODO
    });

  });
}
