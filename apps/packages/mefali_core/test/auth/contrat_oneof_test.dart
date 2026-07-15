import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Le contrat `/auth/otp/verifier` renvoie un `oneOf` discriminé par `resultat`
/// (session | consentement_requis). Le générateur dart-dio ne produit PAS de
/// discriminateur : il essaie chaque variante et garde celle qui désérialise.
///
/// Tout le parcours d'authentification repose sur cette résolution. Si elle
/// échouait — ou pire, choisissait la mauvaise variante — `ParcoursAuth`
/// n'ouvrirait jamais de session, et rien dans `flutter analyze` ne le
/// signalerait. Ces tests exercent donc les serializers générés sur les DEUX
/// formes exactes que le backend émet.
void main() {
  final serializers = standardSerializers;

  ResultatVerification decoder(Map<String, Object?> charge) =>
      serializers.deserializeWith(ResultatVerification.serializer, charge)!;

  group('ResultatVerification (oneOf du contrat)', () {
    test('la forme « session » donne bien la variante à jetons + compte', () {
      final resultat = decoder({
        'resultat': 'session',
        'jetons': {'acces': 'jwt-de-test', 'rafraichissement': 'opaque-de-test'},
        'compte': {
          'id': '01900000-0000-7000-8000-000000000401',
          'telephone_e164': '+2250701020304',
          'zone_id': '01900000-0000-7000-8000-000000000002',
          'roles': [
            {'role': 'client', 'statut': 'valide', 'motif': null, 'decide_le': null}
          ],
          'cree_le': '2026-07-14T10:00:00Z',
        },
      });

      final valeur = resultat.oneOf.value;
      expect(valeur, isA<ResultatVerificationOneOf>());
      final session = valeur as ResultatVerificationOneOf;
      expect(session.jetons.acces, 'jwt-de-test');
      expect(session.jetons.rafraichissement, 'opaque-de-test');
      expect(session.compte.telephoneE164, '+2250701020304');
      expect(session.compte.roles.first.role, 'client');
    });

    test('la forme « consentement_requis » donne la variante à jeton', () {
      final resultat = decoder({
        'resultat': 'consentement_requis',
        'jeton_inscription': 'jeton-usage-unique',
      });

      final valeur = resultat.oneOf.value;
      expect(valeur, isA<ResultatVerificationOneOf1>());
      expect(
        (valeur as ResultatVerificationOneOf1).jetonInscription,
        'jeton-usage-unique',
      );
    });

    test('les deux formes ne se confondent pas', () {
      final session = decoder({
        'resultat': 'session',
        'jetons': {'acces': 'a', 'rafraichissement': 'r'},
        'compte': {
          'id': '01900000-0000-7000-8000-000000000401',
          'telephone_e164': '+2250701020304',
          'zone_id': '01900000-0000-7000-8000-000000000002',
          'roles': <Object>[],
          'cree_le': '2026-07-14T10:00:00Z',
        },
      });
      final consentement = decoder({
        'resultat': 'consentement_requis',
        'jeton_inscription': 'j',
      });

      expect(session.oneOf.value, isNot(isA<ResultatVerificationOneOf1>()));
      expect(consentement.oneOf.value, isNot(isA<ResultatVerificationOneOf>()));
    });
  });
}
