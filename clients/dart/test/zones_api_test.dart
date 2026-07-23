import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for ZonesApi
void main() {
  final instance = MefaliApiClient().getZonesApi();

  group(ZonesApi, () {
    // Configuration produit publique d'une zone (ZON-04). PUBLIC en lecture seule (clarification Q1), liste blanche de namespaces (R4), versionnée par ETag (304 sur If-None-Match — polling horaire économe).
    //
    //Future<ConfigZone> config(String zone) async
    test('test config', () async {
      // TODO
    });

    // Force l'état d'une catégorie dans une ville (ZON-02). Journalisé via outbox (categorie.forcage_change + categorie.activation_changee si bascule) dans la même transaction.
    //
    //Future<EtatCategorie> forcerCategorie(String zoneId, String categorieSlug, CorpsForcage corpsForcage) async
    test('test forcerCategorie', () async {
      // TODO
    });

  });
}
