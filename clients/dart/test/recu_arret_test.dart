import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for RecuArret
void main() {
  final instance = RecuArretBuilder();
  // TODO add properties to the builder and call build()

  group(RecuArret, () {
    // Arrêt collecté.
    // String arretId
    test('to test the property `arretId`', () async {
      // TODO
    });

    // Instant du scan (horloge SERVEUR).
    // DateTime collecteLe
    test('to test the property `collecteLe`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Lignes de cet arrêt, retirées comprises.
    // BuiltList<LigneRecu> lignes
    test('to test the property `lignes`', () async {
      // TODO
    });

    // Articles bruts, AVANT retenue.
    // int montantArticlesUnites
    test('to test the property `montantArticlesUnites`', () async {
      // TODO
    });

    // Clé i18n du motif de retenue, `null` s'il n'y en a pas.
    // String motifRetenueCle
    test('to test the property `motifRetenueCle`', () async {
      // TODO
    });

    // Ce que le coursier a effectivement versé — `articles − retenue`.
    // int netVerseUnites
    test('to test the property `netVerseUnites`', () async {
      // TODO
    });

    // Prestataire chez qui la collecte a eu lieu.
    // String prestataireId
    test('to test the property `prestataireId`', () async {
      // TODO
    });

    // Retenue au titre de la livraison offerte.
    // int retenueLivraisonOfferteUnites
    test('to test the property `retenueLivraisonOfferteUnites`', () async {
      // TODO
    });

  });
}
