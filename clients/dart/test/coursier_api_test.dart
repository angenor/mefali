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
