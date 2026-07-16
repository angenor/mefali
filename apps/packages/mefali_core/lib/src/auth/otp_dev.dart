/// Affordance de DÉVELOPPEMENT : relire le code OTP que le backend a tracé au
/// lieu de l'envoyer (`SMS_MODE=traces`), pour dérouler l'inscription à la main
/// sur un appareil sans aller tailler les logs du serveur.
///
/// # Invisible en build normal
///
/// [modeDevOtp] est une constante de compilation à `false` par défaut : sans le
/// `--dart-define`, la branche qui appelle [lireCodeDevReseau] est morte et le
/// compilateur Dart l'élimine — la surface n'existe pas dans un build de
/// release, ni le bandeau, ni l'appel réseau.
///
/// # Le pendant serveur
///
/// `GET /dev/otp` n'est monté qu'hors production, sous le MÊME gate que Swagger
/// UI (`api/src/dev_http.rs`). En production la route rend 404 : même un build
/// où quelqu'un aurait forcé `MEFALI_DEV_OTP=true` n'obtiendrait rien.
///
/// Rien ici ne touche au défi OTP lui-même : le code reste soumis à son TTL, à
/// ses 3 essais et aux plafonds d'envoi. C'est une LECTURE.
library;

import 'package:dio/dio.dart';

/// Vrai quand le build a été fait avec `--dart-define=MEFALI_DEV_OTP=true`.
///
/// `const` et non une variable : c'est ce qui permet au compilateur de couper
/// la branche morte en release.
const bool modeDevOtp = bool.fromEnvironment('MEFALI_DEV_OTP');

/// Lecteur du code tracé — doublé par les tests (patron de [JouerNote]).
typedef LireCodeDev = Future<String?> Function({
  required String telephone,
  required String zone,
});

/// Implémentation réelle : interroge la surface dev du backend.
///
/// `dio` est celui du client GÉNÉRÉ, donc sa `baseUrl` est déjà celle de l'API
/// (`--dart-define=MEFALI_API_URL`) — pas d'URL en dur ici.
///
/// `/dev/otp` est délibérément absent du contrat OpenAPI (une surface qui
/// n'existe pas en production n'a rien à faire dans un client généré), d'où
/// l'appel dio direct plutôt qu'une méthode générée.
///
/// Rend `null` sur n'importe quel échec — route absente (production), plafond
/// atteint donc aucun SMS tracé, réseau coupé. L'affordance dev ne doit jamais
/// faire échouer le parcours qu'elle sert à observer : sans code, l'écran OTP
/// reste simplement celui de tout le monde.
LireCodeDev lireCodeDevReseau(Dio dio) => ({
      required String telephone,
      required String zone,
    }) async {
      try {
        final reponse = await dio.get<Map<String, dynamic>>(
          '/dev/otp',
          queryParameters: {'telephone': telephone, 'zone': zone},
        );
        return reponse.data?['code'] as String?;
      } on DioException {
        return null;
      }
    };
