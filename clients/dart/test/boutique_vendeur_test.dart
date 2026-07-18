import 'package:test/test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

// tests for BoutiqueVendeur
void main() {
  final instance = BoutiqueVendeurBuilder();
  // TODO add properties to the builder and call build()

  group(BoutiqueVendeur, () {
    // État EFFECTIF dérivé.
    // EtatEffectifBoutique etatEffectif
    test('to test the property `etatEffectif`', () async {
      // TODO
    });

    // Horaires hebdomadaires.
    // HorairesSemaineDto horaires
    test('to test the property `horaires`', () async {
      // TODO
    });

    // Plages du jour courant (fuseau de la zone).
    // BuiltList<PlageDto> horairesDuJour
    test('to test the property `horairesDuJour`', () async {
      // TODO
    });

    // Échéance de la pause en cours.
    // DateTime pauseFin
    test('to test the property `pauseFin`', () async {
      // TODO
    });

    // FR-035 — rappel non bloquant à afficher (fermé manuel dans les horaires) ; « rester fermé » = fermer pour la journée, qui l'éteint.
    // bool rappelOuverture
    test('to test the property `rappelOuverture`', () async {
      // TODO
    });

    // Statut DÉCLARÉ (l'effectif peut différer — FR-032).
    // StatutBoutique statut
    test('to test the property `statut`', () async {
      // TODO
    });

  });
}
