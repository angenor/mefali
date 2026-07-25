import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for CommandesApi
void main() {
  final instance = MefaliApiClient().getCommandesApi();

  group(CommandesApi, () {
    // Crée une commande : prix verrouillés, devis figé, code et QR remis immédiatement (CMD-03).
    //
    // Un rejeu de la même `Idempotency-Key` rend la commande EXISTANTE avec un corps identique et un `200` — jamais un doublon.
    //
    //Future<Commande> creerCommande(String idempotencyKey, DemandeCreationCommande demandeCreationCommande) async
    test('test creerCommande', () async {
      // TODO
    });

    // Devis d'un panier multi-vendeurs — **sans aucun effet de bord** (CMD-01).
    //
    // Regroupe par vendeur, chiffre les frais via le moteur tarifaire, et renvoie les deux déclencheurs de proposition de scission en UNE seule surface. Aucune ligne n'est écrite, aucune commande n'est créée : rien n'est engagé tant que le client n'a pas confirmé (FR-010, research R8).
    //
    //Future<DevisPanier> devisPanier(DemandeDevisPanier demandeDevisPanier) async
    test('test devisPanier', () async {
      // TODO
    });

  });
}
