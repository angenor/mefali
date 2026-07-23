import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for AuthApi
void main() {
  final instance = MefaliApiClient().getAuthApi();

  group(AuthApi, () {
    // Révoque la session courante (déconnexion locale).
    //
    //Future deconnexion() async
    test('test deconnexion', () async {
      // TODO
    });

    // Demande l'envoi d'un code OTP. Réponse TOUJOURS neutre (SC-003).
    //
    //Future<Accepte> demander(DemandeOtp demandeOtp) async
    test('test demander', () async {
      // TODO
    });

    // Crée le compte après consentement ARTCI, puis ouvre sa session.
    //
    // Le 201 rend `SessionOuverte` SEULE, et non le `oneOf` de `/auth/otp/verifier` : ici le consentement vient d'être fourni, donc `consentement_requis` est une issue que ce chemin ne peut pas produire. L'annoncer obligerait chaque client à traiter une branche morte.
    //
    //Future<SessionOuverte> inscrire(Inscription inscription) async
    test('test inscrire', () async {
      // TODO
    });

    // Échange le refresh contre un nouvel accès (rotation systématique, R2).
    //
    //Future<JetonsDto> rafraichir(DemandeRafraichissement demandeRafraichissement) async
    test('test rafraichir', () async {
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
