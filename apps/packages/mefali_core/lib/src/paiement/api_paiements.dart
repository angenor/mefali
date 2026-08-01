/// Couche d'appel de l'API **paiements** (cycle PAY 011).
///
/// Consomme le client Dart **GÉNÉRÉ** (`clients/dart`), jamais de HTTP
/// artisanal (constitution I). Même patron qu'`api_commandes` : sortie en
/// `Map<String, Object?>` sérialisée par les `standardSerializers` du paquet
/// généré — les noms de champs viennent d'`openapi.json` (`wireName`), pas de
/// littéraux recopiés à la main.
///
/// Aucun refus n'est traduit ici : la couche rend le `code` de l'`ErreurApi`,
/// et c'est le l10n de l'app qui en fait une phrase (constitution VII).
///
/// ⚠ La route de **notification** du fournisseur n'est volontairement pas
/// enveloppée : elle est destinée à un agrégateur, pas à une app. L'exposer
/// dans la couche cliente inviterait un jour à la rejouer depuis un téléphone,
/// et c'est exactement le chemin par lequel un paiement s'inventerait.
library;

import 'package:mefali_api_client/mefali_api_client.dart' as gen;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/clients.dart';

part 'api_paiements.g.dart';

/// La couche d'appel paiements, sur le client PORTEUR de session.
@Riverpod(keepAlive: true)
PaiementsApi paiementsApi(Ref ref) =>
    PaiementsApi(ref.watch(clientSessionProvider));

/// Appels de l'API paiements côté client.
class PaiementsApi {
  /// Construit la couche sur un client généré déjà configuré.
  PaiementsApi(this._client);

  final gen.MefaliApiClient _client;

  gen.PaiementsApi get _api => _client.getPaiementsApi();

  /// `POST /commandes/{id}/paiement` — ouvre **ou renvoie** la session.
  ///
  /// Idempotent : l'identifiant de commande est la clé. Rappeler cette méthode
  /// tant que la session vit rend la même session, sans rouvrir d'encaissement.
  /// L'app peut donc la retenter sans compter ses appels.
  Future<Map<String, Object?>> ouvrir(String commandeId) async {
    final reponse = await _api.ouvrirPaiement(id: commandeId);
    return _versJson(reponse.data!);
  }

  /// `GET /commandes/{id}/paiement` — l'état, et le temps restant **calculé par
  /// le serveur**.
  ///
  /// C'est cette valeur qui recale le compte à rebours local : l'horloge de
  /// l'appareil ne décide pas si une session vit encore.
  Future<Map<String, Object?>> etat(String commandeId) async {
    final reponse = await _api.etatPaiement(id: commandeId);
    return _versJson(reponse.data!);
  }

  Map<String, Object?> _versJson(gen.SessionPaiement valeur) =>
      gen.standardSerializers
          .serializeWith(gen.SessionPaiement.serializer, valeur)!
      as Map<String, Object?>;
}
