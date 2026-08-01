import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for PaiementsApi
void main() {
  final instance = MefaliApiClient().getPaiementsApi();

  group(PaiementsApi, () {
    // État de la session de prépaiement d'une commande.
    //
    //Future<SessionPaiement> etatPaiement(String id) async
    test('test etatPaiement', () async {
      // TODO
    });

    // Ouvre — ou renvoie — la session de prépaiement d'une commande.
    //
    //Future<SessionPaiement> ouvrirPaiement(String id) async
    test('test ouvrirPaiement', () async {
      // TODO
    });

    // Notification signée d'un fournisseur de paiement.
    //
    //Future<ReponseNotification> recevoirNotification(String fournisseur, String body) async
    test('test recevoirNotification', () async {
      // TODO
    });

    // Reçu d'une commande — ce qui a été commandé, ce qui en est sorti, et ce qui reste dû.
    //
    //Future<RecuCommande> recuCommande(String id) async
    test('test recuCommande', () async {
      // TODO
    });

  });
}
