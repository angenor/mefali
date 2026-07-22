import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PrestataireAdminDetail
void main() {
  final instance = PrestataireAdminDetailBuilder();
  // TODO add properties to the builder and call build()

  group(PrestataireAdminDetail, () {
    // Slug de la catégorie de service.
    // String categorie
    test('to test the property `categorie`', () async {
      // TODO
    });

    // FR-028, dérivé à la lecture.
    // bool commandable
    test('to test the property `commandable`', () async {
      // TODO
    });

    // Contact téléphonique — surface ADMIN uniquement.
    // String contactTelephone
    test('to test the property `contactTelephone`', () async {
      // TODO
    });

    // Délai de préparation (minutes).
    // int delaiPreparationMin
    test('to test the property `delaiPreparationMin`', () async {
      // TODO
    });

    // Identifiant.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Nom public.
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

    // Cycle de vie.
    // StatutPrestataire statut
    test('to test the property `statut`', () async {
      // TODO
    });

    // Ville de rattachement.
    // String villeId
    test('to test the property `villeId`', () async {
      // TODO
    });

    // Chartes déposées, la plus récente d'abord.
    // BuiltList<CharteAdminDto> chartes
    test('to test the property `chartes`', () async {
      // TODO
    });

    // Code de secours — AUCUNE recherche par ce code n'existe (FR-014).
    // String codeSecours
    test('to test the property `codeSecours`', () async {
      // TODO
    });

    // Jeton de plaque (posé au premier agrément, stable — FR-013).
    // String jetonPlaque
    test('to test the property `jetonPlaque`', () async {
      // TODO
    });

    // Photos présignées.
    // BuiltList<PhotoAdminDto> photos
    test('to test the property `photos`', () async {
      // TODO
    });

    // Comptes rattachés.
    // BuiltList<RattachementDto> rattachements
    test('to test the property `rattachements`', () async {
      // TODO
    });

    // LE site unique, s'il est créé.
    // SiteAdminVueDto site
    test('to test the property `site`', () async {
      // TODO
    });

    // Horodatage de la dernière décision.
    // DateTime statutDecideLe
    test('to test the property `statutDecideLe`', () async {
      // TODO
    });

    // Auteur de la dernière décision de cycle de vie.
    // String statutDecidePar
    test('to test the property `statutDecidePar`', () async {
      // TODO
    });

    // Motif de la dernière décision (suspension).
    // String statutMotif
    test('to test the property `statutMotif`', () async {
      // TODO
    });

  });
}
