import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/mefali_core.dart';

/// Adaptateur qui répond sans réseau. `test()` et non `testWidgets()` dans tout
/// ce fichier : l'horloge d'un test de widget est SIMULÉE, et y attendre un
/// appel dio suspend le test pour toujours.
class _AdaptateurFige implements HttpClientAdapter {
  _AdaptateurFige(this.reponse);

  /// Réponse à rendre, ou `null` pour simuler un échec de transport.
  final ResponseBody? reponse;

  /// Requêtes reçues — pour vérifier ce qui est réellement demandé.
  final List<RequestOptions> recues = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? corps,
    Future<void>? annulation,
  ) async {
    recues.add(options);
    final r = reponse;
    if (r == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'injecté par le test',
      );
    }
    return r;
  }

  @override
  void close({bool force = false}) {}
}

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
      final adaptateur = _AdaptateurFige(
        ResponseBody.fromString(
          '{"code":"424242","telephone_e164":"+2250701020304"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      final lire = lireCodeDevReseau(_dio(adaptateur));

      final code = await lire(telephone: '0701020304', zone: 'zone-tiassale');

      expect(code, '424242');
      // Le numéro part TEL QUE SAISI avec sa zone : c'est le serveur qui
      // normalise en E.164, avec l'indicatif de la zone (FR-024).
      expect(adaptateur.recues.single.path, '/dev/otp');
      expect(adaptateur.recues.single.queryParameters, {
        'telephone': '0701020304',
        'zone': 'zone-tiassale',
      });
    });

    test('rend null quand la route est absente — c\'est le cas de la PRODUCTION',
        () async {
      final lire = lireCodeDevReseau(
        _dio(_AdaptateurFige(ResponseBody.fromString('', 404))),
      );

      expect(await lire(telephone: '0701020304', zone: 'z'), isNull);
    });

    test('rend null sur échec de transport, sans jamais lever', () async {
      // L'affordance dev ne doit pas faire échouer le parcours qu'elle sert à
      // observer : la demande d'OTP, elle, a réussi.
      final lire = lireCodeDevReseau(_dio(_AdaptateurFige(null)));

      expect(await lire(telephone: '0701020304', zone: 'z'), isNull);
    });
  });
}
