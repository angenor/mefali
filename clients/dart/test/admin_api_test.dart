import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for AdminApi
void main() {
  final instance = MefaliApiClient().getAdminApi();

  group(AdminApi, () {
    // Geste de boutique pour le compte du prestataire (source admin).
    //
    //Future<BoutiqueVendeur> actionBoutiqueAdmin(String id, CorpsActionBoutique corpsActionBoutique) async
    test('test actionBoutiqueAdmin', () async {
      // TODO
    });

    // Agrée un prospect : la fiche devient servie et commandable, l'identité de plaque est créée au premier passage, l'activation de catégorie recalculée.
    //
    //Future<PrestataireAdminDetail> agreerPrestataire(String id) async
    test('test agreerPrestataire', () async {
      // TODO
    });

    // Ajoute une photo de fiche.
    //
    //Future<PhotoAdminDto> ajouterPhoto(String id, MultipartFile fichier) async
    test('test ajouterPhoto', () async {
      // TODO
    });

    // Bascule la disponibilité (source admin — la SEULE à lever une rupture admin, FR-041).
    //
    //Future<ArticleVendeur> basculerDisponibiliteAdmin(String id, String articleId, BasculeDisponibiliteDto basculeDisponibiliteDto) async
    test('test basculerDisponibiliteAdmin', () async {
      // TODO
    });

    // Dossier complet d'un coursier, pièce lisible comprise (FR-017 scénario 2).
    //
    //Future<DossierCoursierAdmin> consulterDossierCoursier(String compteId) async
    test('test consulterDossierCoursier', () async {
      // TODO
    });

    // Fiche complète (contact, GPS, plaque, chartes présignées, rattachements).
    //
    //Future<PrestataireAdminDetail> consulterPrestataireAdmin(String id) async
    test('test consulterPrestataireAdmin', () async {
      // TODO
    });

    // Corrige catégorie et/ou ville — SANS suspendre ni ré-agréer, plaque et historique intacts ; les DEUX compteurs sont recalculés dans la même transaction (FR-056).
    //
    //Future<PrestataireAdminDetail> corrigerPrestataire(String id, CorrigerDto corrigerDto) async
    test('test corrigerPrestataire', () async {
      // TODO
    });

    // Crée un article pour le compte du prestataire (source admin).
    //
    //Future<ArticleVendeur> creerArticleAdmin(String id, CreerArticleDto creerArticleDto) async
    test('test creerArticleAdmin', () async {
      // TODO
    });

    // Crée un prestataire (prospect) — ville de type `ville` uniquement.
    //
    //Future<PrestataireAdmin> creerPrestataire(CreerPrestataireDto creerPrestataireDto) async
    test('test creerPrestataire', () async {
      // TODO
    });

    // Décision admin sur un rôle — machine à états de data-model §4, journalisée.
    //
    //Future<EtatRoleDto> deciderRole(String compteId, String role, DecisionRole decisionRole) async
    test('test deciderRole', () async {
      // TODO
    });

    // Miroir admin de l'offre de livraison — l'exploitation configure pour un vendeur qui n'a pas l'app (FR-046).
    //
    //Future<OffreLivraisonVendeur> definirOffreLivraisonAdmin(String id, OffreLivraisonDeclaration offreLivraisonDeclaration) async
    test('test definirOffreLivraisonAdmin', () async {
      // TODO
    });

    // Crée ou met à jour LE site (position GPS, horaires, statut initial).
    //
    //Future<PrestataireAdminDetail> definirSite(String id, SiteAdminDto siteAdminDto) async
    test('test definirSite', () async {
      // TODO
    });

    // Dépose la charte signée scannée — condition NÉCESSAIRE de l'agrément.
    //
    //Future<CharteAdminDto> deposerCharte(String id, MultipartFile fichier, Date signeeLe, String versionCharte) async
    test('test deposerCharte', () async {
      // TODO
    });

    // Détache un compte — le rôle vendeur du compte ne bouge JAMAIS (FR-008).
    //
    //Future detacherCompte(String id, String compteId) async
    test('test detacherCompte', () async {
      // TODO
    });

    // Liste des dossiers coursier pour la revue admin (FR-017).
    //
    //Future<BuiltList<DossierCoursierAdmin>> listerDossiersCoursier({ String statut }) async
    test('test listerDossiersCoursier', () async {
      // TODO
    });

    // Liste les prestataires (filtres statut / ville / catégorie).
    //
    //Future<BuiltList<PrestataireAdmin>> listerPrestataires({ String statut, String ville, String categorie }) async
    test('test listerPrestataires', () async {
      // TODO
    });

    // Modifie un article (source admin).
    //
    //Future<ArticleVendeur> modifierArticleAdmin(String id, String articleId, ModifierArticleDto modifierArticleDto) async
    test('test modifierArticleAdmin', () async {
      // TODO
    });

    // Modifie la fiche (nom, contact, délai) — administrable à tout statut.
    //
    //Future<PrestataireAdmin> modifierPrestataire(String id, ModifierPrestataireDto modifierPrestataireDto) async
    test('test modifierPrestataire', () async {
      // TODO
    });

    // Photo d'article (source admin).
    //
    //Future<ArticleVendeur> photoArticleAdmin(String id, String articleId, MultipartFile fichier) async
    test('test photoArticleAdmin', () async {
      // TODO
    });

    // Rattache un compte vérifié — attribue le rôle vendeur si absent, IDEMPOTENT (FR-007, research R11).
    //
    //Future<PrestataireAdminDetail> rattacherCompte(String id, RattacherCompteDto rattacherCompteDto) async
    test('test rattacherCompte', () async {
      // TODO
    });

    // Remet un article retiré au catalogue (source admin — FR-055).
    //
    //Future<ArticleVendeur> remettreArticleAdmin(String id, String articleId) async
    test('test remettreArticleAdmin', () async {
      // TODO
    });

    // Rétablit un suspendu : tout revient — MÊME jeton, MÊME code de secours, la plaque physique n'a jamais bougé (SC-003).
    //
    //Future<PrestataireAdminDetail> retablirPrestataire(String id) async
    test('test retablirPrestataire', () async {
      // TODO
    });

    // Retire un article du catalogue (source admin — FR-055).
    //
    //Future<ArticleVendeur> retirerArticleAdmin(String id, String articleId) async
    test('test retirerArticleAdmin', () async {
      // TODO
    });

    // Supprime une photo de fiche (objet S3 purgé APRÈS commit — FR-026).
    //
    //Future supprimerPhoto(String id, String photoId) async
    test('test supprimerPhoto', () async {
      // TODO
    });

    // Suspend un prestataire agréé : dans la seconde, fiche retirée, plus commandable, plaque invalide, actions vendeur refusées — TOUT PAR DÉRIVATION, sans action distincte (SC-002).
    //
    //Future<PrestataireAdminDetail> suspendrePrestataire(String id, SuspendreDto suspendreDto) async
    test('test suspendrePrestataire', () async {
      // TODO
    });

  });
}
