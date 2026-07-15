import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import 'stockage_jetons.dart';

/// Session d'authentification de l'application : jetons au repos, en-tête
/// `Authorization` sur le client GÉNÉRÉ, et état observable par l'UI.
///
/// Le client Dart généré est la seule voie d'accès à l'API (constitution I) :
/// on ne lui substitue rien, on lui pose un intercepteur.
///
/// Le rafraîchissement automatique sur 401 est branché au cycle T013 — ici, la
/// session porte les jetons, les persiste et les retire.
class SessionAuth extends ChangeNotifier {
  /// Construit la session sur un stockage et le client généré.
  SessionAuth({required this.stockage, required this.client}) {
    client.dio.interceptors.add(_InterceptorAutorisation(this));
  }

  /// Conservation des jetons entre deux lancements.
  final StockageJetons stockage;

  /// Client généré, porteur de l'en-tête d'autorisation.
  final MefaliApiClient client;

  JetonsSession? _jetons;
  bool _charge = false;

  /// `true` dès que des jetons sont détenus.
  bool get connecte => _jetons != null;

  /// `true` une fois le stockage relu (l'UI attend avant de router).
  bool get charge => _charge;

  /// Jeton d'accès courant, ou `null`.
  String? get acces => _jetons?.acces;

  /// Jeton de renouvellement courant, ou `null` (consommé par T013).
  String? get rafraichissement => _jetons?.rafraichissement;

  /// Relit le stockage au démarrage. À appeler avant le premier `build`.
  Future<void> charger() async {
    _jetons = await stockage.lire();
    _charge = true;
    notifyListeners();
  }

  /// Ouvre (ou remplace) la session — après vérification OTP ou inscription.
  Future<void> ouvrir(JetonsSession jetons) async {
    _jetons = jetons;
    await stockage.ecrire(jetons);
    notifyListeners();
  }

  /// Ferme la session LOCALEMENT et efface les jetons.
  ///
  /// Ne révoque rien côté serveur : la révocation est un appel à part
  /// (`/auth/deconnexion`, T012). Distinction volontaire — quand le serveur a
  /// déjà refusé nos jetons, il n'y a plus rien à révoquer, mais il faut
  /// toujours nettoyer l'appareil.
  Future<void> fermer() async {
    _jetons = null;
    await stockage.effacer();
    notifyListeners();
  }
}

/// Chemin du renouvellement — jamais rafraîchi lui-même (sinon : boucle).
const String _cheminRafraichir = '/auth/rafraichir';

/// Marqueur posé sur une requête déjà rejouée après renouvellement.
const String _dejaRejouee = 'mefali.rejouee';

/// Pose `Authorization: Bearer <accès>` sur chaque requête tant qu'une session
/// existe, et RENOUVELLE silencieusement sur 401 (US2 scénario 2).
///
/// Le renouvellement est SÉRIALISÉ (`_enCours`) : sans cela, les N requêtes qui
/// se prennent un 401 en même temps — l'accès expire pour toutes à la fois —
/// tourneraient le refresh N fois. Or la rotation R2 invalide le jeton
/// précédent : les N-1 perdantes rejoueraient un jeton déjà tourné, le serveur
/// y verrait un vol et révoquerait la session. Un renouvellement partagé évite
/// à l'app de se déconnecter elle-même.
class _InterceptorAutorisation extends Interceptor {
  _InterceptorAutorisation(this._session);

  final SessionAuth _session;
  Future<bool>? _enCours;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final acces = _session.acces;
    if (acces != null) {
      options.headers['Authorization'] = 'Bearer $acces';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException erreur,
    ErrorInterceptorHandler handler,
  ) async {
    final requete = erreur.requestOptions;
    final rejouable = erreur.response?.statusCode == 401 &&
        !requete.path.contains(_cheminRafraichir) &&
        requete.extra[_dejaRejouee] != true &&
        _session.rafraichissement != null;
    if (!rejouable) return handler.next(erreur);

    final renouvele = await (_enCours ??= _renouveler());
    if (!renouvele) {
      // Le serveur a refusé : la session est morte (révoquée à distance, ou
      // rejeu détecté). On nettoie l'appareil — l'UI repart sur l'auth.
      await _session.fermer();
      return handler.next(erreur);
    }

    try {
      requete.extra[_dejaRejouee] = true;
      requete.headers['Authorization'] = 'Bearer ${_session.acces}';
      handler.resolve(await _session.client.dio.fetch(requete));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _renouveler() async {
    try {
      final reponse = await _session.client.getAuthApi().rafraichir(
            demandeRafraichissement: DemandeRafraichissement(
              (b) => b..rafraichissement = _session.rafraichissement!,
            ),
          );
      final jetons = reponse.data;
      if (jetons == null) return false;
      await _session.ouvrir(
        JetonsSession(
          acces: jetons.acces,
          rafraichissement: jetons.rafraichissement,
        ),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _enCours = null;
    }
  }
}
