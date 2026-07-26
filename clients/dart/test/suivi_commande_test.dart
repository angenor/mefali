import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for SuiviCommande
void main() {
  final instance = SuiviCommandeBuilder();
  // TODO add properties to the builder and call build()

  group(SuiviCommande, () {
    // Coursier affecté.
    // CoursierSuivi coursier
    test('to test the property `coursier`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // État de très haut niveau.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // **Clé i18n** de l'état affiché — jamais une phrase (constitution VII).
    // String etatCle
    test('to test the property `etatCle`', () async {
      // TODO
    });

    // Instant du dernier changement d'état.
    // DateTime etatLe
    test('to test the property `etatLe`', () async {
      // TODO
    });

    // Commande.
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // État logistique.
    // String livraisonEtat
    test('to test the property `livraisonEtat`', () async {
      // TODO
    });

    // Livraison, si la commande en a une (composant 0..n).
    // String livraisonId
    test('to test the property `livraisonId`', () async {
      // TODO
    });

    // Montant des articles (révisé si des articles ont sauté).
    // int montantArticlesUnites
    test('to test the property `montantArticlesUnites`', () async {
      // TODO
    });

    // Dernière position connue — `null` si aucune (research R13).
    // PositionSuivi position
    test('to test the property `position`', () async {
      // TODO
    });

    // Progression par arrêt.
    // ProgressionSuivi progression
    test('to test the property `progression`', () async {
      // TODO
    });

    // Code et QR de remise — **propriétaire seul** (R6).
    // SecretsRemise remise
    test('to test the property `remise`', () async {
      // TODO
    });

    // Proposition de remplacement ouverte.
    // SubstitutionSuivi substitutionEnAttente
    test('to test the property `substitutionEnAttente`', () async {
      // TODO
    });

    // Total à payer.
    // int totalUnites
    test('to test the property `totalUnites`', () async {
      // TODO
    });

  });
}
