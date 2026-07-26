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

    // CMD-05 — journalise l'intention d'appeler le coursier (FR-041).
    //
    // L'appel part du téléphone : le serveur n'en voit rien et **ne journalise aucun numéro**. Ce qu'il enregistre, c'est qu'un client a eu BESOIN d'appeler — une métrique de friction (minimisation ARTCI).
    //
    //Future intentionAppel(String id, IntentionAppel intentionAppel) async
    test('test intentionAppel', () async {
      // TODO
    });

    // CMD-05 — les commandes du compte, les plus récentes d'abord.
    //
    //Future<MesCommandes> mesCommandes() async
    test('test mesCommandes', () async {
      // TODO
    });

    // CMD-05 — suivi complet d'une commande, pour son **propriétaire**.
    //
    // Le code et le jeton de remise ne sont servis qu'ici, et qu'au propriétaire : le coursier, lui, ne reçoit que des empreintes (research R6).
    //
    //Future<SuiviCommande> suivreCommande(String id) async
    test('test suivreCommande', () async {
      // TODO
    });

  });
}
