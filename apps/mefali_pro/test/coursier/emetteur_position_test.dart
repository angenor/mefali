/// Tests de l'**émetteur de position** hors arbre de widgets (DSP-01).
///
/// Pourquoi hors arbre : ce qu'on vérifie ici est une COURSE entre deux
/// constructions du porteur, et elle se pilote par le conteneur — pas par des
/// frames. Le harnais `testWidgets` fige le temps, ce qui rend l'enchaînement
/// « en ligne → hors ligne → en ligne » impossible à dérouler sans attendre le
/// délai de garde du runner.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/disponibilite/emetteur_position.dart';
import 'package:mefali_pro/coursier/disponibilite/etat_disponibilite.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

/// Corps de `GET|PUT /moi/disponibilite`, tel que le contrat le rend.
Map<String, Object?> _etat({required bool enLigne}) => {
      'en_ligne': enLigne,
      'plafond_declare_unites': 10000,
      'plafond_retenu_unites': 5000,
      'plafond_source': 'grille_note',
      'palier_note_cle': 'dispatch.palier.entree',
      'note_centiemes': null,
      'devise': 'XOF',
      'jour': '2026-07-27',
      'capacites': [
        {'famille': 'transport', 'valeur': 'moto'},
      ],
      'dans_le_pool': enLigne,
      'periode_position_s': 30,
    };

Position _positionTiassale() => Position(
      latitude: 5.8960,
      longitude: -4.8210,
      timestamp: DateTime(2026, 7, 27, 12),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// `@Dependencies` : les surcharges du capteur et de la permission sont posées
/// sur le conteneur RACINE, où `EmetteurPosition` est de toute façon hébergé.
/// La déclaration le dit à l'outil d'analyse — sans elle, `dart analyze`
/// avertit à juste titre qu'un provider scopé est lu sans portée déclarée.
@Dependencies([EmetteurPosition])
void main() {
  test(
    'deux démarrages concurrents ne laissent qu\'UN abonnement au capteur',
    () async {
      // Ce que ce test protège : la demande de permission est `async`, et le
      // drapeau `_vivant` est RÉARMÉ à chaque `build`. Une bascule
      // en ligne → hors ligne → en ligne assez rapide laisse donc deux
      // `_demarrer` en vol ; tous deux se croient vivants, tous deux posent un
      // abonnement et une cadence, et le second ÉCRASE les champs du premier.
      // Le `Timer.periodic` écrasé n'est plus annulé par personne : il publie
      // en double, réveille le GPS pour rien, et survit à la sortie de Yao.
      var abonnements = 0;
      final permissions = <Completer<bool>>[];
      var enLigne = false;

      final transport = TransportFake((requete) {
        if (requete.path.contains('/moi/position')) {
          return reponseJson({'dans_le_pool': true, 'prochaine_publication_s': 30});
        }
        if (requete.path.contains('/moi/disponibilite')) {
          // Le corps d'une bascule porte `en_ligne` ; un simple chargement non.
          final brut = requete.data?.toString() ?? '';
          if (brut.contains('en_ligne')) {
            enLigne = !brut.contains('en_ligne: false') &&
                !brut.contains('"en_ligne":false');
          }
          return reponseJson(_etat(enLigne: enLigne));
        }
        return reponseJson({'code': 'introuvable'}, statut: 404);
      });

      Stream<Position> capteurCompte(LocationSettings _) {
        abonnements++;
        return const Stream.empty();
      }

      // La permission ne rend la main QUE quand le test le décide : c'est ce
      // qui met deux démarrages en vol en même temps.
      Future<bool> permissionDifferee() {
        final attente = Completer<bool>();
        permissions.add(attente);
        return attente.future;
      }

      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
        transport: transport,
        supplements: [
          sourcePositionsProvider.overrideWithValue(capteurCompte),
          permissionPositionProvider.overrideWithValue(permissionDifferee),
          relevePonctuelProvider.overrideWithValue(() async => _positionTiassale()),
        ],
      );
      addTearDown(container.dispose);

      // Un observateur permanent : sans lui, le porteur (jetable) serait
      // éliminé entre deux lectures et la course ne pourrait pas naître.
      final abonnement = container.listen(emetteurPositionProvider, (_, _) {});
      addTearDown(abonnement.close);

      final notifier = container.read(disponibiliteProvider.notifier);
      await notifier.passerEnLigne(10000);
      container.read(emetteurPositionProvider);
      await notifier.passerHorsLigne();
      container.read(emetteurPositionProvider);
      await notifier.passerEnLigne(10000);
      container.read(emetteurPositionProvider);

      expect(
        permissions.length,
        greaterThanOrEqualTo(2),
        reason: 'la bascule doit avoir mis DEUX démarrages en vol, sinon ce '
            'test ne reproduit pas la course qu\'il prétend fermer',
      );
      for (final attente in permissions) {
        if (!attente.isCompleted) attente.complete(true);
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        abonnements,
        1,
        reason: 'un seul abonnement au capteur doit survivre : le démarrage '
            'périmé doit se taire, pas écraser les champs du vivant',
      );
    },
  );
}
