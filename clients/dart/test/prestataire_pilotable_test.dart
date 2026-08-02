import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for PrestatairePilotable
void main() {
  final instance = PrestatairePilotableBuilder();
  // TODO add properties to the builder and call build()

  group(PrestatairePilotable, () {
    // État effectif de la boutique.
    // EtatEffectifBoutique boutique
    test('to test the property `boutique`', () async {
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

    // Offre de livraison déclarée (VND-08) : `jamais` | `toujours` | `au_dela`.  Champ ADDITIF (cycle PAY 011) : l'app livrée l'ignore et continue de fonctionner. Servi ici plutôt que par une route dédiée parce que le réglage vit sur l'écran boutique, et qu'un second aller-retour pour deux scalaires n'aurait servi personne.
    // String offreLivraison
    test('to test the property `offreLivraison`', () async {
      // TODO
    });

    // Seuil de panier de l'offre `au_dela`, `null` sinon.
    // int offreLivraisonSeuilUnites
    test('to test the property `offreLivraisonSeuilUnites`', () async {
      // TODO
    });

    // Cycle de vie — `suspendu` : l'app affiche le refus, le rôle est intact.
    // StatutPrestataire statut
    test('to test the property `statut`', () async {
      // TODO
    });

  });
}
