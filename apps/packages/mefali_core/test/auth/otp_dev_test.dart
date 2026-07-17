import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

/// `test()` et non `testWidgets()` dans tout ce fichier : l'horloge d'un test de
/// widget est SIMULÉE, et y attendre un appel dio suspend le test pour toujours.
///
/// Le double de transport (`_AdaptateurFige`, l'un des 6 de SC-011) est remplacé
/// par `TransportFake` du harnais ; le `Dio` nu reste (lireCodeDevReseau prend
/// un Dio, pas le client généré).
Dio _dio(HttpClientAdapter adaptateur) =>
    Dio(BaseOptions(baseUrl: 'http://test.invalid'))
      ..httpClientAdapter = adaptateur;

void main() {
  group('modeDevOtp', () {
    test('est ÉTEINT sans --dart-define — la surface dev n\'existe pas par défaut',
        () {
      // Le garde-fou côté app : c'est cette constante à `false` qui rend le
      // bandeau et l'appel `/dev/otp` inatteignables, et qui permet au
      // compilateur de les retirer d'un build de release. Si ce test tombe,
      // c'est qu'un build normal embarque la surface dev.
      expect(modeDevOtp, isFalse);
    });
  });

  group('lireCodeDevReseau', () {
    test('rend le code tracé, lu sur la surface dev du backend', () async {
      final transport = TransportFake(
        (_) => reponseJson({
          'code': '424242',
          'telephone_e164': '+2250701020304',
        }),
      );
      final lire = lireCodeDevReseau(_dio(transport));

      final code = await lire(telephone: '0701020304', zone: 'zone-tiassale');

      expect(code, '424242');
      // Le numéro part TEL QUE SAISI avec sa zone : c'est le serveur qui
      // normalise en E.164, avec l'indicatif de la zone (FR-024).
      expect(transport.recues.single.path, '/dev/otp');
      expect(transport.recues.single.queryParameters, {
        'telephone': '0701020304',
        'zone': 'zone-tiassale',
      });
    });

    test('rend null quand la route est absente — c\'est le cas de la PRODUCTION',
        () async {
      final lire = lireCodeDevReseau(
        _dio(TransportFake((_) => ResponseBody.fromString('', 404))),
      );

      expect(await lire(telephone: '0701020304', zone: 'z'), isNull);
    });

    test('rend null sur échec de transport, sans jamais lever', () async {
      // L'affordance dev ne doit pas faire échouer le parcours qu'elle sert à
      // observer : la demande d'OTP, elle, a réussi. `repondre` LÈVE au lieu de
      // rendre une réponse — le transport factice sait échouer.
      final lire = lireCodeDevReseau(
        _dio(
          TransportFake(
            (options) => throw DioException.connectionError(
              requestOptions: options,
              reason: 'injecté par le test',
            ),
          ),
        ),
      );

      expect(await lire(telephone: '0701020304', zone: 'z'), isNull);
    });
  });
}
