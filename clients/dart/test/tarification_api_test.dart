import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for TarificationApi
void main() {
  final instance = MefaliApiClient().getTarificationApi();

  group(TarificationApi, () {
    // Crée (ou rend) le brouillon de la zone — **idempotent**.
    //
    //Future<Grille> creerBrouillon(String zoneId) async
    test('test creerBrouillon', () async {
      // TODO
    });

    // Crée ou met à jour une règle du brouillon — **réarme la simulation**.
    //
    //Future<Regle> ecrireRegle(String grilleId, String regleId, RegleUpsert regleUpsert) async
    test('test ecrireRegle', () async {
      // TODO
    });

    // Grille en vigueur ET brouillon d'une zone.
    //
    //Future<GrillesZone> grilleDeZone(String zoneId) async
    test('test grilleDeZone', () async {
      // TODO
    });

    // Supprime une règle du brouillon — **réarme la simulation**.
    //
    //Future supprimerRegle(String grilleId, String regleId) async
    test('test supprimerRegle', () async {
      // TODO
    });

  });
}
