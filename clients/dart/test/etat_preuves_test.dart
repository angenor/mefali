import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for EtatPreuves
void main() {
  final instance = EtatPreuvesBuilder();
  // TODO add properties to the builder and call build()

  group(EtatPreuves, () {
    // Preuve « appels ».
    // PreuveAppels appels
    test('to test the property `appels`', () async {
      // TODO
    });

    // Preuve « photo ».
    // PreuvePhotos photos
    test('to test the property `photos`', () async {
      // TODO
    });

    // Preuve « présence ».
    // PreuvePresence presence
    test('to test the property `presence`', () async {
      // TODO
    });

    // Les trois sont réunies — l'échec devient déclarable.
    // bool reunies
    test('to test the property `reunies`', () async {
      // TODO
    });

    // Compteur « N sur 3 » de K4-1e.
    // int reuniesSur
    test('to test the property `reuniesSur`', () async {
      // TODO
    });

    // Toujours 3 — le compteur n'a de sens que si le total est explicite.
    // int total
    test('to test the property `total`', () async {
      // TODO
    });

  });
}
