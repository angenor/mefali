import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for AuthApi
void main() {
  final instance = MefaliApiClient().getAuthApi();

  group(AuthApi, () {
    // Demande l'envoi d'un code OTP. Réponse TOUJOURS neutre (SC-003).
    //
    //Future<Accepte> demander(DemandeOtp demandeOtp) async
    test('test demander', () async {
      // TODO
    });

    // Crée le compte après consentement ARTCI, puis ouvre sa session.
    //
    //Future<ResultatVerification> inscrire(Inscription inscription) async
    test('test inscrire', () async {
      // TODO
    });

    // Vérifie le code : ouvre une session (numéro connu) ou exige le consentement.
    //
    //Future<ResultatVerification> verifier(VerificationOtp verificationOtp) async
    test('test verifier', () async {
      // TODO
    });

  });
}
