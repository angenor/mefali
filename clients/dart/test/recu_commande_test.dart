import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for RecuCommande
void main() {
  final instance = RecuCommandeBuilder();
  // TODO add properties to the builder and call build()

  group(RecuCommande, () {
    // Commande.
    // String commandeId
    test('to test the property `commandeId`', () async {
      // TODO
    });

    // La commande est-elle déjà réglée ? (FR-073)
    // bool dejaRegle
    test('to test the property `dejaRegle`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // Frais de livraison facturés.
    // int fraisLivraisonUnites
    test('to test the property `fraisLivraisonUnites`', () async {
      // TODO
    });

    // Lignes, **retirées comprises** : le reçu explique pourquoi le total a bougé plutôt que de le faire bouger en silence.
    // BuiltList<LigneRecu> lignes
    test('to test the property `lignes`', () async {
      // TODO
    });

    // `cash` | `mobile_money`.
    // String modePaiement
    test('to test the property `modePaiement`', () async {
      // TODO
    });

    // Ce qui reste à remettre au coursier — **0** sur une commande prépayée.
    // int montantARemettreAuCoursierUnites
    test('to test the property `montantARemettreAuCoursierUnites`', () async {
      // TODO
    });

    // Somme des lignes vivantes.
    // int montantArticlesUnites
    test('to test the property `montantArticlesUnites`', () async {
      // TODO
    });

    // Moyen employé — `null` tant que le fournisseur ne l'a pas dit (FR-012).
    // String moyen
    test('to test the property `moyen`', () async {
      // TODO
    });

    // Part de frais prise en charge par le vendeur (VND-08), `0` sinon.
    // int retenueVendeurUnites
    test('to test the property `retenueVendeurUnites`', () async {
      // TODO
    });

    // Total dû, déjà ajusté par les retraits et les arrêts indisponibles.
    // int totalDuUnites
    test('to test the property `totalDuUnites`', () async {
      // TODO
    });

  });
}
