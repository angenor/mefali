import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for CommandesAdminApi
void main() {
  final instance = MefaliApiClient().getCommandesAdminApi();

  group(CommandesAdminApi, () {
    // CMD-07 — un administrateur annule une commande, **motif obligatoire**.
    //
    // Le motif n'est pas une formalité : il est journalisé, il part dans l'événement, et c'est lui que le client lira. C'est une **clé i18n**, jamais du texte libre — un motif écrit à la main serait illisible pour la moitié des clients et impossible à agréger pour l'exploitation.
    //
    //Future<ResultatAnnulation> annulerCommandeAdmin(String id, DemandeAnnulation demandeAnnulation) async
    test('test annulerCommandeAdmin', () async {
      // TODO
    });

    // CMD-10 — file FIFO des commandes sans coursier d'une zone.
    //
    // L'ordre est l'âge, du plus ancien au plus récent : c'est la promesse produite au client qui attend (« la plus ancienne repart en premier »), et c'est le contrat que **DSP** consommera tel quel.
    //
    //Future<FileAttenteCoursier> fileAttente(String zoneId) async
    test('test fileAttente', () async {
      // TODO
    });

  });
}
