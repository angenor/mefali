import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for CoursierApi
void main() {
  final instance = MefaliApiClient().getCoursierApi();

  group(CoursierApi, () {
    // CRS-03 — course active du coursier, **complète** et pré-provisionnée.
    //
    // Cet endpoint a déménagé de `qr_http` : son contenu n'a plus rien à faire dans un domaine dont l'objet est la plaque. Le chemin ne bouge pas, et les champs du cycle 006 restent là — l'app livrée continue de fonctionner pendant la transition.  `204` sans course : ce n'est pas une erreur, c'est une journée qui commence.
    //
    //Future<CourseActiveComplete> courseActive() async
    test('test courseActive', () async {
      // TODO
    });

    // CRS-03 — déclare (ou corrige) l'issue d'un appel (FR-036, R19).
    //
    // Le serveur ne peut pas l'observer : l'appel part du téléphone. Cette issue sert l'affichage de K4-1e et **n'est jamais un critère de preuve** — un coursier qui déclarerait « sans réponse » à tort ne gagne rien.
    //
    //Future<AppelEnregistre> declarerIssueAppel(String livraisonId, IssueAppelDeclaree issueAppelDeclaree) async
    test('test declarerIssueAppel', () async {
      // TODO
    });

    // CRS-05 — dépose une photo de preuve d'échec (FR-056, FR-064).
    //
    // **Multipart** pour la même raison que la remise (R18) : la photo voyage AVEC la demande, donc dans la file hors-ligne. Une preuve qui exigerait du réseau au moment de la prise serait une preuve qu'on ne peut pas réunir là où elle sert — devant une porte close, dans un quartier sans couverture.  Idempotent par `uuid_client` : le rejeu ne redépose rien et ne compte pas une seconde photo.
    //
    //Future<PhotoPreuveDeposee> deposerPhotoPreuve(String livraisonId, DemandePhotoPreuve demande, MultipartFile photo) async
    test('test deposerPhotoPreuve', () async {
      // TODO
    });

    // CRS-05 — enregistre un lot de relevés de présence (FR-061, FR-064).
    //
    // L'app envoie des **échantillons**, jamais une durée : c'est le serveur qui compte, en ignorant tout intervalle supérieur au « trou » de la zone. Sans cette règle, deux relevés espacés de dix minutes vaudraient dix minutes de présence, et un aller-retour vaudrait une attente (R8).  Idempotent par `uuid_client` : un lot rejoué par la file rend le même corps.
    //
    //Future<PresenceEnregistree> enregistrerPresence(String livraisonId, LotDePresence lotDePresence) async
    test('test enregistrerPresence', () async {
      // TODO
    });

    // CRS-05 — état des trois preuves et **ce qui manque** (FR-058, FR-062).
    //
    // C'est la **même fonction** que celle qui garde `POST /courses/{id}/echec` : l'écran et le serveur ne peuvent pas diverger (FR-059, FR-060). Un bouton actif dont la déclaration serait refusée serait pire qu'un bouton inactif.
    //
    //Future<EtatPreuves> etatPreuves(String livraisonId) async
    test('test etatPreuves', () async {
      // TODO
    });

    // CRS-03 — journalise un appel passé **via l'app** (FR-030, FR-031, FR-033).
    //
    // ⚠ **Aucun numéro** n'est transmis ni journalisé : le serveur ne voit pas l'appel, il part du téléphone. Il en garde l'intention, la direction, le motif et l'issue déclarée.  Idempotent par `uuid_client` : le rejeu rend `200` et le même corps, sans seconde ligne ni second événement.
    //
    //Future<AppelEnregistre> journaliserAppel(String livraisonId, DemandeAppel demandeAppel) async
    test('test journaliserAppel', () async {
      // TODO
    });

    // Signale un article introuvable — REFUSÉ (et compté nulle part) sans commande active comportant un arrêt chez ce prestataire (FR-038).
    //
    //Future<SignalementRecuDto> signalerRupture(String idempotencyKey, SignalerRuptureDto signalerRuptureDto) async
    test('test signalerRupture', () async {
      // TODO
    });

  });
}
