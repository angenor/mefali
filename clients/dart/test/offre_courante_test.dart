import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for OffreCourante
void main() {
  final instance = OffreCouranteBuilder();
  // TODO add properties to the builder and call build()

  group(OffreCourante, () {
    // Arrêts dans l'ordre optimisé du devis FIGÉ.
    // BuiltList<ArretOffre> arrets
    test('to test the property `arrets`', () async {
      // TODO
    });

    // Avance et plafond.
    // AvanceOffre avance
    test('to test the property `avance`', () async {
      // TODO
    });

    // Commande offerte.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // Vrai si les distances viennent du repli vol d'oiseau (constitution IV).
    // bool degraded
    test('to test the property `degraded`', () async {
      // TODO
    });

    // Destination approximative.
    // DestinationOffre destination
    test('to test the property `destination`', () async {
      // TODO
    });

    // **AUTORITÉ** du compte à rebours : le widget compte, le serveur tranche.
    // DateTime echeanceLe
    test('to test the property `echeanceLe`', () async {
      // TODO
    });

    // Gain détaillé.
    // GainOffre gain
    test('to test the property `gain`', () async {
      // TODO
    });

    // `cascade` | `broadcast`.
    // String mode
    test('to test the property `mode`', () async {
      // TODO
    });

    // Offre concernée.
    // String offreId
    test('to test the property `offreId`', () async {
      // TODO
    });

    // Secondes restantes à l'instant de la lecture.
    // int restantS
    test('to test the property `restantS`', () async {
      // TODO
    });

    // Durée totale du compte à rebours (secondes).
    // int timerS
    test('to test the property `timerS`', () async {
      // TODO
    });

  });
}
