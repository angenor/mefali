/// Couche d'appel de l'API **dispatch** (cycle DSP 009) — disponibilité,
/// position, offre courante et décision.
///
/// Consomme le client Dart **GÉNÉRÉ** (`clients/dart`), jamais de HTTP
/// artisanal (constitution I) : les chemins, les en-têtes et les corps sortent
/// d'`openapi.json`, et un contrat qui bouge casse ici à la compilation plutôt
/// qu'en production.
///
/// **Pourquoi des `Map<String, Object?>` en sortie et non les DTO générés.**
/// C'est la leçon du cycle 008, et elle n'a rien de cosmétique : les vues
/// d'écran se construisent depuis le corps JSON, et c'est CE chemin-là que
/// couvrent les tests widget. Rendre le DTO obligerait à écrire un second
/// chemin de conversion, non couvert, qui divergerait du premier au premier
/// changement de contrat. Le DTO typé est donc sérialisé avec les
/// `standardSerializers` du paquet généré : les noms de champs sont ceux
/// d'`openapi.json` (`wireName`), jamais des littéraux recopiés à la main.
///
/// Cette couche ne traduit **aucun** refus en texte : elle rend le `code` de
/// l'`ErreurApi`, et c'est l'écran qui en fait une phrase à partir d'une clé
/// i18n (constitution VII).
library;

import 'package:built_value/serializer.dart';
// Préfixé : la classe `DispatchApi` de CE fichier porte le même nom que celle
// du client généré, qu'elle enveloppe.
import 'package:mefali_api_client/mefali_api_client.dart' as gen;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/clients.dart';

part 'api_dispatch.g.dart';

/// La couche d'appel dispatch, construite sur le client PORTEUR de session —
/// toutes ces routes exigent `Authorization` et le rôle coursier.
@Riverpod(keepAlive: true)
DispatchApi dispatchApi(Ref ref) => DispatchApi(ref.watch(clientSessionProvider));

/// Appels de l'API dispatch, de la mise en ligne à la décision d'offre.
class DispatchApi {
  /// Construit la couche sur un client généré déjà configuré.
  DispatchApi(this._client);

  final gen.MefaliApiClient _client;

  gen.DispatchApi get _api => _client.getDispatchApi();

  /// `PUT /moi/disponibilite` — se mettre en ligne (avec son plafond du jour)
  /// ou hors ligne.
  ///
  /// Passer `enLigne: false` retire du pool **immédiatement** (FR-005) : un
  /// coursier qui a rangé sa moto ne doit pas voir son téléphone sonner 90 s
  /// plus tard. Le `plafondDeclareUnites` est obligatoire pour se mettre en
  /// ligne, ignoré pour en sortir.
  Future<Map<String, Object?>> basculerDisponibilite({
    required bool enLigne,
    int? plafondDeclareUnites,
  }) async {
    final reponse = await _api.basculerDisponibiliteCoursier(
      basculeDisponibilite: gen.BasculeDisponibilite(
        (b) => b
          ..enLigne = enLigne
          ..plafondDeclareUnites = plafondDeclareUnites,
      ),
    );
    return _versJson(gen.EtatDisponibilite.serializer, reponse.data!);
  }

  /// `GET /moi/disponibilite` — l'état courant, tel que K1 l'affiche.
  ///
  /// Rend TOUJOURS les deux plafonds — déclaré et retenu — et dit lequel
  /// s'applique : un coursier à qui l'on refuse une course sans lui dire que
  /// son palier le limite croira à un bug.
  Future<Map<String, Object?>> lireDisponibilite() async {
    final reponse = await _api.lireDisponibilite();
    return _versJson(gen.EtatDisponibilite.serializer, reponse.data!);
  }

  /// `POST /moi/position` — publier sa position et rester dans le pool.
  ///
  /// Rend `null` quand le serveur répond `204` : le coursier n'est pas en
  /// ligne, sa position est **ignorée** et non refusée. L'app peut être en
  /// retard d'un tic après un « hors ligne », et lui afficher une erreur ferait
  /// clignoter un écran pour rien.
  ///
  /// ⚠ Cet appel **n'entre pas** dans la file hors-ligne (dérogation déclarée
  /// au principe V) : une position vieille de dix minutes rejouée au retour du
  /// réseau réinscrirait le coursier avec une localisation fausse, et le
  /// dispatch lui offrirait une course à 4 km de là où il est.
  Future<Map<String, Object?>?> publierPosition({
    required String uuidClient,
    required DateTime horodatageLocal,
    required double lat,
    required double lon,
    int? precisionM,
  }) async {
    final reponse = await _api.publierPosition(
      publicationPosition: gen.PublicationPosition(
        (b) => b
          ..uuidClient = uuidClient
          ..horodatageLocal = horodatageLocal
          ..lat = lat
          ..lon = lon
          ..precisionM = precisionM,
      ),
    );
    if (reponse.statusCode == 204 || reponse.data == null) return null;
    return _versJson(gen.EtatPublicationPosition.serializer, reponse.data!);
  }

  /// Sérialise un DTO généré en corps JSON du contrat — les noms de champs
  /// viennent d'`openapi.json`, jamais d'un littéral recopié.
  Map<String, Object?> _versJson<T>(Serializer<T> serializer, T valeur) =>
      gen.standardSerializers.serializeWith(serializer, valeur)!
          as Map<String, Object?>;
}
