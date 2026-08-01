import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for DemandeRemise
void main() {
  final instance = DemandeRemiseBuilder();
  // TODO add properties to the builder and call build()

  group(DemandeRemise, () {
    // Code à 4 chiffres dicté par le client (mode `code`).
    // String code
    test('to test the property `code`', () async {
      // TODO
    });

    // Horodatage de l'appareil. **Observation seulement**.
    // DateTime confirmeLeLocal
    test('to test the property `confirmeLeLocal`', () async {
      // TODO
    });

    // Latitude du coursier au dépôt (mode `depot`, FR-048).
    // double depotLat
    test('to test the property `depotLat`', () async {
      // TODO
    });

    // Longitude du coursier au dépôt (mode `depot`, FR-048).
    // double depotLon
    test('to test the property `depotLon`', () async {
      // TODO
    });

    // Essais faux consommés **hors ligne**, consolidés en `max()` côté serveur contre le seuil de zone `commande.essais_code_livraison` (R5).
    // int essaisHorsLigne
    test('to test the property `essaisHorsLigne`', () async {
      // TODO
    });

    // La validation a-t-elle eu lieu sans réseau ? Journalisé, jamais décisif — le serveur revalide la preuve ici même (FR-046).
    // bool horsLigne
    test('to test the property `horsLigne`', () async {
      // TODO
    });

    // Jeton lu dans le QR de réception (mode `qr`).
    // String jeton
    test('to test the property `jeton`', () async {
      // TODO
    });

    // `qr` | `code` | `depot`.
    // String mode
    test('to test the property `mode`', () async {
      // TODO
    });

    // Clé d'une photo **déjà** déposée (mode `depot`) — compatibilité du cycle 008 ; l'app coursier envoie la partie binaire `photo` (R18).
    // String photoCle
    test('to test the property `photoCle`', () async {
      // TODO
    });

    // Clé d'idempotence (UUIDv7 produit par l'app, constitution V).  **Obligatoire** depuis CRS 010 : sans elle, un rejeu de la file clôturait deux fois la même course (R4).
    // String uuidClient
    test('to test the property `uuidClient`', () async {
      // TODO
    });

  });
}
