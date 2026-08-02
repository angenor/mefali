import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for MoiApi
void main() {
  final instance = MefaliApiClient().getMoiApi();

  group(MoiApi, () {
    // URL présignée de lecture du repère vocal (FR-020).
    //
    //Future<UrlPresignee> ecouterRepereVocal(String adresseId) async
    test('test ecouterRepereVocal', () async {
      // TODO
    });

    // Enregistre une adresse — proposition post-livraison acceptée (FR-019).
    //
    //Future<Adresse> enregistrerAdresse(String idempotencyKey, double lat, String libelle, double lng, { int dureeS, String livraisonOrigine, MultipartFile noteVocale, String repereTexte }) async
    test('test enregistrerAdresse', () async {
      // TODO
    });

    // Adresses enregistrées du compte courant (FR-021).
    //
    //Future<BuiltList<Adresse>> mesAdresses() async
    test('test mesAdresses', () async {
      // TODO
    });

    // Appareils/sessions actifs du compte (FR-008).
    //
    //Future<BuiltList<SessionAppareil>> mesSessions() async
    test('test mesSessions', () async {
      // TODO
    });

    // Renomme l'adresse ou met à jour son repère écrit (FR-021).
    //
    //Future<Adresse> modifierAdresse(String adresseId, ModifierAdresse modifierAdresse) async
    test('test modifierAdresse', () async {
      // TODO
    });

    // Compte courant et états de TOUS ses rôles.
    //
    //Future<CompteMoi> moi() async
    test('test moi', () async {
      // TODO
    });

    // État du dossier coursier du compte courant (FR-013 : l'app Pro l'affiche).
    //
    //Future<DossierCoursier> monDossierCoursier() async
    test('test monDossierCoursier', () async {
      // TODO
    });

    // Change les véhicules d'un dossier coursier DÉJÀ validé (CPT-04).
    //
    // `PUT` et non `PATCH` : l'écriture est un remplacement intégral, et le corps porte la flotte entière. Route DISTINCTE de `POST /moi/dossier-coursier`, dont la sémantique « soumettre ou re-soumettre après refus » est juste et testée — la surcharger ferait repasser par une revue admin un coursier qui change simplement de moto.  Aucun identifiant de compte en chemin : `auth.compte_id` est le seul compte touchable. La garde de propriété la plus sûre est celle qu'on ne peut pas oublier d'écrire (le cycle 008 a livré une fuite exactement là).  L'en-tête d'idempotence est exigée par cohérence avec `POST`, mais n'est pas stockée : c'est le remplacement intégral, plus la branche « flotte inchangée » du domaine, qui rendent le rejeu inoffensif.
    //
    //Future<DossierCoursier> remplacerMesVehicules(String idempotencyKey, MesVehicules mesVehicules) async
    test('test remplacerMesVehicules', () async {
      // TODO
    });

    // Enregistre un nouveau repère vocal — après purge, ou pour le refaire.
    //
    //Future<Adresse> remplacerRepereVocal(String adresseId, int dureeS, MultipartFile noteVocale) async
    test('test remplacerRepereVocal', () async {
      // TODO
    });

    // Déconnexion à distance d'un appareil (SC-004).
    //
    //Future revoquerSession(String sessionId) async
    test('test revoquerSession', () async {
      // TODO
    });

    // Soumet (ou re-soumet après refus) le dossier coursier — crée la demande de rôle (FR-015).
    //
    //Future<DossierCoursier> soumettreDossierCoursier(String idempotencyKey, MultipartFile piece, String referentNom, String referentTelephone, BuiltList<String> vehicules) async
    test('test soumettreDossierCoursier', () async {
      // TODO
    });

    // Supprime l'adresse — soft (FR-021).
    //
    //Future supprimerAdresse(String adresseId) async
    test('test supprimerAdresse', () async {
      // TODO
    });

  });
}
