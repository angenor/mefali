import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for CommandesApi
void main() {
  final instance = MefaliApiClient().getCommandesApi();

  group(CommandesApi, () {
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
