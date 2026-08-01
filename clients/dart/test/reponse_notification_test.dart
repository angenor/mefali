import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ReponseNotification
void main() {
  final instance = ReponseNotificationBuilder();
  // TODO add properties to the builder and call build()

  group(ReponseNotification, () {
    // Pourquoi elle n'en a produit aucun : `rejeu`, `en_cours`, `orpheline`, `etat_incompatible`, `divergence`. Absent quand `traite` vaut `true`.
    // String motif
    test('to test the property `motif`', () async {
      // TODO
    });

    // Vrai si la notification a produit un effet.
    // bool traite
    test('to test the property `traite`', () async {
      // TODO
    });

  });
}
