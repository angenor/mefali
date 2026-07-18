import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for CreerPrestataireDto
void main() {
  final instance = CreerPrestataireDtoBuilder();
  // TODO add properties to the builder and call build()

  group(CreerPrestataireDto, () {
    // Slug de la catégorie de service (référentiel ZON).
    // String categorieSlug
    test('to test the property `categorieSlug`', () async {
      // TODO
    });

    // Contact téléphonique (servi à l'admin seulement).
    // String contactTelephone
    test('to test the property `contactTelephone`', () async {
      // TODO
    });

    // Délai de préparation moyen déclaré (minutes).
    // int delaiPreparationMin
    test('to test the property `delaiPreparationMin`', () async {
      // TODO
    });

    // Nom public.
    // String nom
    test('to test the property `nom`', () async {
      // TODO
    });

    // Ville de rattachement — type `ville` exigé (FR-002).
    // String villeId
    test('to test the property `villeId`', () async {
      // TODO
    });

  });
}
