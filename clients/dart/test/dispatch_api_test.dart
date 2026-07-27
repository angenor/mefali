import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for DispatchApi
void main() {
  final instance = MefaliApiClient().getDispatchApi();

  group(DispatchApi, () {
    // `PUT /moi/disponibilite` — se mettre en ligne ou hors ligne.
    //
    // ⚠ Le suffixe `_coursier` n'est pas décoratif : utoipa dérive l'`operationId` du NOM DE LA FONCTION, et `vendeur_http::basculer_disponibilite` (bascule d'un article en rupture) porte déjà le nom court. Deux `operationId` identiques font échouer la génération des clients — donc la CI.  Passer `en_ligne: false` retire du pool **immédiatement**, sans attendre l'expiration (FR-005) : un coursier qui a rangé sa moto ne doit pas voir son téléphone sonner 90 s plus tard.  Se mettre en ligne exige un dossier valide et **au moins une capacité déclarée** : sans véhicule, aucune course ne pourra jamais lui être proposée, et le lui dire tout de suite vaut mieux qu'une attente muette.
    //
    //Future<EtatDisponibilite> basculerDisponibiliteCoursier(BasculeDisponibilite basculeDisponibilite) async
    test('test basculerDisponibiliteCoursier', () async {
      // TODO
    });

    // `GET /moi/disponibilite` — l'état courant, tel que K1 l'affiche.
    //
    //Future<EtatDisponibilite> lireDisponibilite() async
    test('test lireDisponibilite', () async {
      // TODO
    });

    // `POST /moi/position` — publier sa position, et rester dans le pool.
    //
    // `204` si le coursier n'est pas en ligne : la position n'est pas **refusée**, elle est **ignorée** — l'app peut être en retard d'un tic après un « hors ligne », et lui rendre une erreur ferait clignoter un écran pour rien.  **Idempotence** : rejouer la même position repousse simplement la durée de vie ; aucun événement n'est écrit dans les deux cas (une position est un fait éphémère qui se répète toutes les 30 s, et elle porte une coordonnée que la minimisation interdit de journaliser).
    //
    //Future<EtatPublicationPosition> publierPosition(PublicationPosition publicationPosition) async
    test('test publierPosition', () async {
      // TODO
    });

  });
}
