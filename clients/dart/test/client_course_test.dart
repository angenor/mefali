import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for ClientCourse
void main() {
  final instance = ClientCourseBuilder();
  // TODO add properties to the builder and call build()

  group(ClientCourse, () {
    // La voie « dépôt » est-elle ouverte sur cette commande (FR-039) ?
    // bool depotAutorise
    test('to test the property `depotAutorise`', () async {
      // TODO
    });

    // Point de livraison.
    // double lieuLat
    test('to test the property `lieuLat`', () async {
      // TODO
    });

    // Point de livraison.
    // double lieuLon
    test('to test the property `lieuLon`', () async {
      // TODO
    });

    // Nom d'usage. **Absent** tant que le produit n'en porte aucun (cycle CPT 003 : « un numéro vérifié, rien d'autre ») — l'app affiche le repère.
    // String nomUsage
    test('to test the property `nomUsage`', () async {
      // TODO
    });

    // Repère écrit.
    // String repereTexte
    test('to test the property `repereTexte`', () async {
      // TODO
    });

    // Durée de la note vocale (s).
    // int repereVocalDureeS
    test('to test the property `repereVocalDureeS`', () async {
      // TODO
    });

    // URL **présignée** de la note vocale — à télécharger tout de suite pour la jouer hors ligne (FR-024).
    // String repereVocalUrl
    test('to test the property `repereVocalUrl`', () async {
      // TODO
    });

    // Contact du client. Jamais journalisé, effacé du cache à la clôture (R6).
    // String telephone
    test('to test the property `telephone`', () async {
      // TODO
    });

  });
}
