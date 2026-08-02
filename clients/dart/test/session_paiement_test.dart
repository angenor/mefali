import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for SessionPaiement
void main() {
  final instance = SessionPaiementBuilder();
  // TODO add properties to the builder and call build()

  group(SessionPaiement, () {
    // Page de paiement à ouvrir dans le **navigateur système**.  `null` dès que l'état quitte `ouverte` : la colonne est effacée à l'issue, et un accès d'encaissement survivant à son paiement est une surface d'attaque sans usage (FR-006).
    // String accesPaiement
    test('to test the property `accesPaiement`', () async {
      // TODO
    });

    // Devise ISO 4217.
    // String devise
    test('to test the property `devise`', () async {
      // TODO
    });

    // État : `ouverte` | `reglee` | `echouee` | `expiree` | `payee_hors_delai`.
    // String etat
    test('to test the property `etat`', () async {
      // TODO
    });

    // Échéance **persistée**, calculée depuis `paiement.session_duree_s`.
    // DateTime expireLe
    test('to test the property `expireLe`', () async {
      // TODO
    });

    // Montant **figé** à l'ouverture (unités mineures).
    // int montantUnites
    test('to test the property `montantUnites`', () async {
      // TODO
    });

    // Moyen effectivement employé, tel que le fournisseur l'a dit. `inconnu` tant qu'il ne l'a pas dit — jamais deviné (FR-012).
    // String moyen
    test('to test the property `moyen`', () async {
      // TODO
    });

    // Secondes restantes, **calculées côté serveur** (FR-017).  L'horloge de l'app ne décide de rien : elle affiche un compte à rebours qu'elle recale sur cette valeur à chaque lecture. Vaut `0` sur une session échue, jamais un nombre négatif.
    // int restantS
    test('to test the property `restantS`', () async {
      // TODO
    });

    // Transaction de paiement.
    // String transactionId
    test('to test the property `transactionId`', () async {
      // TODO
    });

  });
}
