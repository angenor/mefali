import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for SiteAdminDto
void main() {
  final instance = SiteAdminDtoBuilder();
  // TODO add properties to the builder and call build()

  group(SiteAdminDto, () {
    // Horaires hebdomadaires (remplacement complet).
    // HorairesSemaineDto horaires
    test('to test the property `horaires`', () async {
      // TODO
    });

    // Latitude relevée sur place.
    // double positionLat
    test('to test the property `positionLat`', () async {
      // TODO
    });

    // Longitude.
    // double positionLng
    test('to test the property `positionLng`', () async {
      // TODO
    });

    // Statut initial — à la CRÉATION seulement (`ouvert` par défaut ; `en_pause`/`ferme_journee` refusés).
    // StatutBoutique statutInitial
    test('to test the property `statutInitial`', () async {
      // TODO
    });

  });
}
