/// Couche d'appel de l'API **commandes** (cycle CMD 008).
///
/// Consomme le client Dart **GÉNÉRÉ** (`clients/dart`), jamais de HTTP
/// artisanal (constitution I) : les chemins, les en-têtes et les corps sortent
/// d'`openapi.json`, et un contrat qui bouge casse ici à la compilation plutôt
/// qu'en production.
///
/// **Pourquoi des `Map<String, Object?>` en sortie et non les DTO générés.**
/// Les vues d'écran de l'app cliente (`DevisPanierVue`, `CommandeCreeeVue`,
/// `EtatSuivi`) se construisent déjà depuis le corps JSON — c'est ce chemin-là
/// que couvrent les tests widget du cycle. Rendre le DTO obligerait à écrire un
/// SECOND chemin de conversion, non couvert, qui divergerait du premier au
/// premier changement de contrat. On sérialise donc le DTO typé avec les
/// `standardSerializers` du paquet généré : les noms de champs sont ceux
/// d'`openapi.json` (`wireName`), pas des littéraux recopiés à la main.
///
/// Cette couche ne traduit **aucun** refus en texte : elle rend le `code` de
/// l'`ErreurApi`, et c'est `messageErreurCommande` — et lui seul — qui en fait
/// une phrase (constitution VII).
library;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
// Préfixé : la classe `CommandesApi` de CE fichier porte le même nom que celle
// du client généré, qu'elle enveloppe.
import 'package:mefali_api_client/mefali_api_client.dart' as gen;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/clients.dart';

part 'api_commandes.g.dart';

/// La couche d'appel commandes, construite sur le client PORTEUR de session —
/// toutes ces routes exigent `Authorization` (constitution VIII).
@Riverpod(keepAlive: true)
CommandesApi commandesApi(Ref ref) =>
    CommandesApi(ref.watch(clientSessionProvider));

/// Appels de l'API commandes, du devis à la décision de substitution.
class CommandesApi {
  /// Construit la couche sur un client généré déjà configuré.
  CommandesApi(this._client);

  final gen.MefaliApiClient _client;

  gen.CommandesApi get _api => _client.getCommandesApi();

  /// `POST /paniers/devis` — chiffre un panier **sans aucun effet de bord**
  /// (CMD-01). Les `lignes` sont au format rendu par `LignePanier.versJson()`.
  Future<Map<String, Object?>> devis({
    required String zoneId,
    required String categorieSlug,
    required String transportSlug,
    required double lat,
    required double lon,
    required List<Map<String, Object?>> lignes,
  }) async {
    final reponse = await _api.devisPanier(
      demandeDevisPanier: gen.DemandeDevisPanier(
        (b) => b
          ..zoneId = zoneId
          ..categorieSlug = categorieSlug
          ..transportSlug = transportSlug
          ..lieu.replace(_lieu(lat, lon))
          ..lignes = ListBuilder<gen.LignePanier>(lignes.map(_ligne)),
      ),
    );
    return _versJson(gen.DevisPanier.serializer, reponse.data!);
  }

  /// `POST /commandes` — crée la commande. La clé d'idempotence **DEVIENT**
  /// l'identifiant de la commande (R7) : un rejeu rend l'existante, jamais un
  /// doublon. Elle est fournie par l'appelant, qui la conserve tant que la
  /// commande n'est pas créée.
  ///
  /// `adresseId` OU (`lat`, `lon`) + repère : le carnet (CPT-05) porte déjà son
  /// repère, une adresse saisie doit fournir le sien.
  Future<Map<String, Object?>> creer({
    required String idempotencyKey,
    required String zoneId,
    required String categorieSlug,
    required String transportSlug,
    required String modePaiement,
    required List<Map<String, Object?>> lignes,
    String? adresseId,
    double? lat,
    double? lon,
    String? repereTexte,
    String? repereVocalCle,
  }) async {
    final reponse = await _api.creerCommande(
      idempotencyKey: idempotencyKey,
      demandeCreationCommande: gen.DemandeCreationCommande(
        (b) {
          b
            ..zoneId = zoneId
            ..categorieSlug = categorieSlug
            ..transportSlug = transportSlug
            ..modePaiement = modePaiement
            ..adresseId = adresseId
            ..repereTexte = repereTexte
            ..repereVocalCle = repereVocalCle
            ..lignes = ListBuilder<gen.LignePanier>(lignes.map(_ligne));
          // Le getter `b.lieu` CRÉE un builder vide : ne le toucher que si un
          // pin est fourni, sinon un `lieu` incomplet partirait avec une
          // commande qui s'appuie sur le carnet.
          if (lat != null && lon != null) b.lieu.replace(_lieu(lat, lon));
        },
      ),
    );
    return _versJson(gen.Commande.serializer, reponse.data!);
  }

  /// `GET /commandes/{id}` — le suivi (CMD-05).
  Future<Map<String, Object?>> suivre(String commandeId) async {
    final reponse = await _api.suivreCommande(id: commandeId);
    return _versJson(gen.SuiviCommande.serializer, reponse.data!);
  }

  /// `GET /moi/commandes` — les commandes du compte, les plus récentes d'abord.
  Future<List<Map<String, Object?>>> mesCommandes() async {
    final reponse = await _api.mesCommandes();
    return [
      for (final c in reponse.data!.commandes)
        _versJson(gen.CommandeResumee.serializer, c),
    ];
  }

  /// `POST /commandes/{id}/annuler` — CMD-07. Le client n'a pas à se justifier :
  /// `motifCle` reste facultatif pour lui (obligatoire côté admin, FR-054).
  Future<Map<String, Object?>> annuler(String commandeId, {String? motifCle}) async {
    final reponse = await _api.annulerCommande(
      id: commandeId,
      demandeAnnulation: gen.DemandeAnnulation((b) => b..motifCle = motifCle),
    );
    return _versJson(gen.ResultatAnnulation.serializer, reponse.data!);
  }

  /// `POST /commandes/{id}/appel` — journalise l'INTENTION d'appeler (FR-041).
  /// L'appel lui-même part du téléphone ; aucun numéro ne circule ici.
  Future<void> signalerAppel(String commandeId, {String motif = 'suivi'}) async {
    await _api.intentionAppel(
      id: commandeId,
      intentionAppel: gen.IntentionAppel((b) => b..motif = motif),
    );
  }

  /// `POST /commandes/{id}/substitutions/{sub}/decision` — CMD-06.
  Future<Map<String, Object?>> deciderSubstitution({
    required String commandeId,
    required String substitutionId,
    required bool accepte,
  }) async {
    final reponse = await _api.deciderSubstitution(
      id: commandeId,
      sub: substitutionId,
      decisionSubstitution:
          gen.DecisionSubstitution((b) => b..accepte = accepte),
    );
    return _versJson(gen.ResultatDecisionSubstitution.serializer, reponse.data!);
  }

  gen.Lieu _lieu(double lat, double lon) => gen.Lieu(
        (b) => b
          ..lat = lat
          ..lon = lon,
      );

  gen.LignePanier _ligne(Map<String, Object?> json) => gen.LignePanier(
        (b) => b
          ..prestataireId = json['prestataire_id']! as String
          ..articleId = json['article_id']! as String
          ..quantite = json['quantite']! as int
          ..preference = json['preference'] as String?,
      );

  /// Rend le corps JSON du DTO, avec les noms de champs du contrat.
  Map<String, Object?> _versJson<T>(Serializer<T> serializer, T valeur) =>
      gen.standardSerializers.serializeWith(serializer, valeur)!
          as Map<String, Object?>;
}

/// Le `code` du refus rendu par l'API (`ErreurApi.code`), ou `null` si l'échec
/// n'est pas un refus métier (panne réseau, timeout, corps illisible).
///
/// À passer tel quel à `messageErreurCommande` : un `null` y donne le message
/// générique, ce qui est exactement ce qu'il faut dire d'une panne inconnue.
String? codeErreurApi(Object erreur) {
  if (erreur is! DioException) return null;
  final corps = erreur.response?.data;
  if (corps is Map) {
    final code = corps['code'] ?? corps['message_cle'];
    if (code is String) return code;
  }
  return null;
}

/// L'échec vient du RÉSEAU, pas du serveur — l'app peut alors basculer sur son
/// cache local plutôt qu'annoncer une erreur (SC-009, maquette C4-4d).
///
/// `unknown` en fait partie : dio y range les `SocketException` d'un appareil
/// en mode avion, qui sont précisément le cas que cette bascule sert.
bool estPanneReseau(Object erreur) =>
    erreur is DioException &&
    (erreur.type == DioExceptionType.connectionError ||
        erreur.type == DioExceptionType.connectionTimeout ||
        erreur.type == DioExceptionType.receiveTimeout ||
        erreur.type == DioExceptionType.sendTimeout ||
        (erreur.type == DioExceptionType.unknown && erreur.response == null));
