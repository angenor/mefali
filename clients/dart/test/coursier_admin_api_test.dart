import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';


/// tests for CoursierAdminApi
void main() {
  final instance = MefaliApiClient().getCoursierAdminApi();

  group(CoursierAdminApi, () {
    // **FR-116** — ouvre (ou referme) la voie « dépôt convenu » sur une commande.
    //
    // Le cadrage §7.4-5 dit « mode dépôt autorisé **par le client** ». Tant qu'aucune surface cliente ne le porte, c'est l'exploitation qui l'ouvre à sa demande, au téléphone, avec un motif tracé — le contrat ne changera pas quand l'app cliente reprendra la main.  **Fermé par défaut** : un défaut ouvert aurait rendu le dépôt possible partout sans que personne ne l'ait décidé.
    //
    //Future<DecisionDepot> autoriserDepot(String commandeId, DemandeDepot demandeDepot) async
    test('test autoriserDepot', () async {
      // TODO
    });

    // **FR-055** — l'exploitation lève le blocage du code, avec motif tracé.
    //
    // Le compteur d'essais retombe à zéro : une levée qui laisserait le compteur au plafond serait inopérante — le premier essai suivant rebloquerait la commande, et l'exploitation croirait avoir agi.
    //
    //Future debloquerCode(String commandeId, DemandeDeblocage demandeDeblocage) async
    test('test debloquerCode', () async {
      // TODO
    });

    // CRS-05 (exploitation) — le dossier de preuves d'une livraison (FR-063).
    //
    // C'est ce qui rend les preuves **lisibles**. Sans cet endpoint, elles existeraient en base sans que personne ne puisse répondre à un client qui conteste un échec — et une preuve que personne ne lit ne protège personne.  ⚠ Aucun numéro de téléphone n'en sort : le serveur n'en a jamais journalisé.
    //
    //Future<PreuvesExploitation> preuvesDeLivraison(String livraisonId) async
    test('test preuvesDeLivraison', () async {
      // TODO
    });

    // **FR-044** — les remises dont le code est épuisé et le blocage non levé.
    //
    // Le verrou du code protège un secret à quatre chiffres, mais il laisse une commande à la porte du client. Sans cette lecture, l'alerte `remise.code_epuise` partirait dans l'outbox sans que personne ne puisse répondre — et un humain ne s'abonne pas à un journal.
    //
    //Future<RemisesBloquees> remisesBloquees({ String zoneId }) async
    test('test remisesBloquees', () async {
      // TODO
    });

  });
}
