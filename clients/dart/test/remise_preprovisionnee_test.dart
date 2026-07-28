import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for RemisePreprovisionnee
void main() {
  final instance = RemisePreprovisionneeBuilder();
  // TODO add properties to the builder and call build()

  group(RemisePreprovisionnee, () {
    // Saisie du code bloquée (K4-1d).
    // bool codeBloque
    test('to test the property `codeBloque`', () async {
      // TODO
    });

    // Empreinte salée du code à 4 chiffres — **jamais le code** (FR-037).
    // String empreinteCode
    test('to test the property `empreinteCode`', () async {
      // TODO
    });

    // Empreinte du jeton de réception — **jamais le jeton**.
    // String empreinteJeton
    test('to test the property `empreinteJeton`', () async {
      // TODO
    });

    // Essais faux déjà comptés côté serveur.
    // int essaisConsommes
    test('to test the property `essaisConsommes`', () async {
      // TODO
    });

    // Seuil de zone `commande.essais_code_livraison` (cycle 008, réutilisé).
    // int essaisMax
    test('to test the property `essaisMax`', () async {
      // TODO
    });

    // `cash` | `mobile_money`.
    // String modePaiement
    test('to test the property `modePaiement`', () async {
      // TODO
    });

    // Total à encaisser chez le client (unités mineures).
    // int montantAEncaisserUnites
    test('to test the property `montantAEncaisserUnites`', () async {
      // TODO
    });

    // Seuils de preuve de la zone.
    // SeuilsPreuves preuves
    test('to test the property `preuves`', () async {
      // TODO
    });

  });
}
