/// Couche d'appel des **adresses du compte** (`/moi/adresses`, CPT-05).
///
/// Existe pour une raison précise du cycle CMD : `POST /commandes` accepte une
/// `repere_vocal_cle`, mais **rien dans l'app ne peut la produire** — la seule
/// route qui téléverse une note vocale est `POST /moi/adresses` (multipart).
/// Une commande à repère VOCAL passe donc par le carnet : on enregistre
/// l'adresse, puis on commande sur son identifiant. Ce n'est pas un détour,
/// c'est CPT-05 qui sert à ce qu'il a été fait.
///
/// `MesAdresses` (liste, renommage, suppression) reste où il est : ici, la
/// seule écriture dont le parcours de commande a besoin.
library;

import 'package:dio/dio.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/clients.dart';
import 'note_vocale.dart';

part 'api_adresses.g.dart';

/// La couche d'appel des adresses, sur le client PORTEUR de session.
@Riverpod(keepAlive: true)
AdressesApi adressesApi(Ref ref) =>
    AdressesApi(ref.watch(clientSessionProvider));

/// Écriture du carnet d'adresses.
class AdressesApi {
  /// Construit la couche sur un client généré déjà configuré.
  AdressesApi(this._client);

  final MefaliApiClient _client;

  /// `POST /moi/adresses` — enregistre une adresse et rend son identifiant.
  ///
  /// `idempotencyKey` est fournie par l'appelant et REJOUÉE à l'identique en
  /// cas de nouvelle tentative : sans elle, un envoi qui expire au moment du
  /// téléversement laisserait deux adresses jumelles dans le carnet.
  ///
  /// Le mime `audio/mp4` est celui que `record` produit (m4a/aac) et que le
  /// serveur dérive de l'en-tête de la partie — même forme que l'atelier DEV,
  /// qui a servi à le vérifier sur appareil.
  Future<String> enregistrer({
    required String idempotencyKey,
    required double lat,
    required double lon,
    required String libelle,
    String? repereTexte,
    NoteVocaleCaptee? note,
  }) async {
    final reponse = await _client.getMoiApi().enregistrerAdresse(
          idempotencyKey: idempotencyKey,
          lat: lat,
          lng: lon,
          libelle: libelle,
          repereTexte: repereTexte,
          noteVocale: note == null
              ? null
              : MultipartFile.fromBytes(
                  note.octets,
                  filename: 'repere.m4a',
                  contentType: DioMediaType.parse('audio/mp4'),
                ),
          dureeS: note?.dureeS,
        );
    return reponse.data!.id;
  }
}
