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

    // Signale un article introuvable — REFUSÉ (et compté nulle part) sans commande active comportant un arrêt chez ce prestataire (FR-038).
    //
    //Future<SignalementRecuDto> signalerRupture(String idempotencyKey, SignalerRuptureDto signalerRuptureDto) async
    test('test signalerRupture', () async {
      // TODO
    });

  });
}
