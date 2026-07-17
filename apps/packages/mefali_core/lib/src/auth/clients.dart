import 'package:dio/dio.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../portee.dart';
import 'session.dart';
import 'stockage_jetons.dart';

part 'clients.g.dart';

/// Chemin du renouvellement — jamais rafraîchi lui-même (sinon : boucle).
const String _cheminRafraichir = '/auth/rafraichir';

/// Marqueur posé sur une requête déjà rejouée après renouvellement.
const String _dejaRejouee = 'mefali.rejouee';

/// Le client HTTP PORTEUR d'`Authorization`, et le SEUL. Il pose l'unique
/// instance de `InterceptorAutorisation` de l'app (FR-013) et la retire à sa
/// destruction (FR-018).
///
/// `keepAlive` OBLIGATOIRE : sous `@riverpod` nu, une ré-évaluation empilerait un
/// 2ᵉ intercepteur ⇒ 2 renouvellements concurrents ⇒ jeton déjà tourné rejoué ⇒
/// vol présumé ⇒ session révoquée (mode de panne n°1). NI `dio:` NI
/// `interceptors:` : les délais 5000/3000 ms ne vivent que dans la branche par
/// défaut du client généré, et passer `interceptors:` REMPLACE les 4
/// intercepteurs générés au lieu de s'y ajouter (FR-017, R3).
@Riverpod(keepAlive: true)
MefaliApiClient clientSession(Ref ref) {
  final client = MefaliApiClient(basePathOverride: ref.watch(urlApiProvider));
  final intercepteur = InterceptorAutorisation(ref, client);
  client.dio.interceptors.add(intercepteur);
  // FR-018 — `List.remove` compare par IDENTITÉ, donc ORDRE-INDÉPENDANT. JAMAIS
  // `removeWhere` (il en supprimerait deux dans l'ordre défavorable → 0).
  ref.onDispose(() => client.dio.interceptors.remove(intercepteur));
  return client;
}

/// Le client HTTP qui NE porte JAMAIS d'`Authorization` (FR-017). Deux clients
/// distincts, JAMAIS un : la garantie ne repose sur AUCUNE assertion runtime —
/// c'est une propriété du graphe, seul `clientSession` pose un intercepteur (R3).
@Riverpod(keepAlive: true)
MefaliApiClient clientConfig(Ref ref) =>
    MefaliApiClient(basePathOverride: ref.watch(urlApiProvider));

/// L'intercepteur d'autorisation — PUBLIC (il était `_InterceptorAutorisation`),
/// sans quoi le harnais ne peut le compter PAR TYPE et SC-005 retomberait sur le
/// `.last` positionnel que ce cycle supprime (R11).
///
/// Il détient le `Ref` de `clientSession` et le client — JAMAIS le notificateur :
/// un `this` capturé laisserait un `Session` disposé joignable depuis le dio ; un
/// `Ref` résout toujours l'instance COURANTE (R3). On lit l'ÉTAT
/// (`ref.read(sessionProvider)`) et on appelle des MÉTHODES (`.notifier`) : seul
/// montage qui passe `dart analyze` (exposer les jetons en getters de
/// notificateur → `avoid_public_notifier_properties`).
class InterceptorAutorisation extends Interceptor {
  /// Construit l'intercepteur sur le `Ref` et le client de `clientSession`.
  InterceptorAutorisation(this._ref, this._client);

  final Ref _ref;
  final MefaliApiClient _client;

  /// Le verrou de renouvellement. INCHANGÉ, zéro ligne modifiée : FR-013 garantit
  /// une instance d'intercepteur par client ⇒ l'unicité du verrou en est le
  /// COROLLAIRE. Le remonter dans `state` est interdit par FR-001 (R7).
  Future<bool>? _enCours;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final acces = _ref.read(sessionProvider).acces;
    if (acces != null) {
      options.headers['Authorization'] = 'Bearer $acces';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requete = err.requestOptions;
    final rejouable = err.response?.statusCode == 401 &&
        !requete.path.contains(_cheminRafraichir) &&
        requete.extra[_dejaRejouee] != true &&
        _ref.read(sessionProvider).rafraichissement != null;
    if (!rejouable) return handler.next(err);

    final renouvele = await (_enCours ??= _renouveler());
    if (!renouvele) {
      // Le serveur a refusé : la session est morte (révoquée à distance, ou
      // rejeu détecté). On nettoie l'appareil — l'UI repart sur l'auth.
      await _ref.read(sessionProvider.notifier).fermer();
      return handler.next(err);
    }

    try {
      requete.extra[_dejaRejouee] = true;
      requete.headers['Authorization'] =
          'Bearer ${_ref.read(sessionProvider).acces}';
      handler.resolve(await _client.dio.fetch(requete));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _renouveler() async {
    try {
      final reponse = await _client.getAuthApi().rafraichir(
            demandeRafraichissement: DemandeRafraichissement(
              (b) => b
                ..rafraichissement =
                    _ref.read(sessionProvider).rafraichissement!,
            ),
          );
      final jetons = reponse.data;
      if (jetons == null) return false;
      await _ref.read(sessionProvider.notifier).ouvrir(
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
