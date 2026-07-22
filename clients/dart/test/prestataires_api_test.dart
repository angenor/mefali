import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for PrestatairesApi
void main() {
  final instance = MefaliApiClient().getPrestatairesApi();

  group(PrestatairesApi, () {
    // Fiche + catalogue, lecture seule, SANS authentification — la plaque est un canal d'acquisition (FR-027 ; exception VIII documentée au plan, R9).
    //
    //Future<FichePublique> consulterPrestataire(String id) async
    test('test consulterPrestataire', () async {
      // TODO
    });

    // Résout un jeton de plaque — sous SESSION valide, AUCUN rôle particulier (analyse C1 : seule la consultation de la fiche échappe au principe VIII).
    //
    //Future<ResolutionPlaque> resoudrePlaque(String jeton) async
    test('test resoudrePlaque', () async {
      // TODO
    });

  });
}
