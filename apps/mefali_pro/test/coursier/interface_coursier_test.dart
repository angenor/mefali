/// Tests de l'**aiguillage** de l'espace coursier (T071).
///
/// Ce que ces tests protègent, et pourquoi ils existent : le cycle DSP 009 a
/// livré K1 et K2 sans les brancher. Les deux écrans étaient parfaits et
/// testés — et **inatteignables depuis l'app**. Un coursier ne pouvait ni se
/// mettre en ligne, ni voir une offre arriver. Le défaut n'a été trouvé qu'à la
/// validation sur émulateur, parce qu'aucun test ne regardait la jonction.
///
/// Ces tests la regardent : ils montent `InterfaceCoursier` et vérifient que
/// chaque état du monde ouvre le bon écran.
///
/// ⚠ **Ce que ce fichier ne couvre PAS** : la troisième branche — course
/// assignée ⇒ écran de course. `EtatCourseActive` lit le cache drift (SQLite)
/// avant le réseau, et `sqlite3_flutter_libs` n'existe pas dans un test
/// widget ; le provider retombe alors sur un état vide, et l'aiguillage sur
/// K1 — ce qui est le bon REPLI, mais ne prouve pas la branche. Elle est
/// validée sur émulateur (quickstart, « Validation sur appareil »).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/disponibilite/emetteur_position.dart';
import 'package:mefali_pro/coursier/interface_coursier.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/roles/etat_roles.dart';

/// Corps de `GET /courses/offre-courante` — offre encore en vol.
Map<String, Object?> _offreEnVol({int dansSecondes = 31}) => {
      'offre_id': '019fa000-0000-7000-8000-000000000001',
      'commande_id': '019fa000-0000-7000-8000-000000000002',
      'mode': 'cascade',
      'echeance_le':
          DateTime.now().toUtc().add(Duration(seconds: dansSecondes)).toIso8601String(),
      'timer_s': 40,
      'restant_s': dansSecondes,
      'arrets': [
        {'ordre': 1, 'prestataire_id': null, 'nom': 'Étal Adjoua', 'distance_m': 800},
      ],
      'destination': {
        'zone_nom': 'Tiassalé',
        'distance_m': 1800,
        'mention_cle': 'dispatch.offre.adresse_apres_acceptation',
      },
      'gain': {
        'total_unites': 450,
        'deplacement_unites': 250,
        'arrets_unites': 50,
        'effort_unites': 100,
        'devise': 'XOF',
      },
      'avance': {
        'montant_unites': 5550,
        'plafond_retenu_unites': 10000,
        'devise': 'XOF',
      },
      'degraded': false,
    };

/// Corps de `GET /moi/disponibilite` — hors ligne, rien d'engagé.
Map<String, Object?> _disponibilite() => {
      'en_ligne': false,
      'dans_le_pool': false,
      'plafond_declare_unites': null,
      'plafond_retenu_unites': 5000,
      'plafond_source': 'grille_note',
      'palier_note_cle': 'dispatch.palier.entree',
      'note_centiemes': null,
      'devise': 'XOF',
      'ttl_s': 90,
      'periode_position_s': 30,
      'capacites': [
        {'famille': 'transport', 'valeur': 'moto'},
      ],
    };

(ProviderContainer, TransportFake) _conteneur({Map<String, Object?>? offre}) {
  final transport = TransportFake((requete) {
    if (requete.path.contains('/offre-courante')) {
      if (offre == null) return reponseJson(<String, Object?>{}, statut: 204);
      return reponseJson(offre);
    }
    if (requete.path.contains('/courses/active')) {
      return reponseJson(<String, Object?>{}, statut: 204);
    }
    if (requete.path.contains('/moi/disponibilite')) {
      return reponseJson(_disponibilite());
    }
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
  );
  return (container, transport);
}

/// Un coursier seul — pas de bascule de rôle à rendre.
EtatRolesData _coursierSeul() => const EtatRolesData(
      charge: true,
      attributions: [
        AttributionPro(role: RolePro.coursier, statut: StatutRolePro.valide),
      ],
      actif: RolePro.coursier,
    );

/// Source de positions INERTE — un test widget n'a ni capteur ni permission,
/// et le vrai `geolocator` laisserait un minuteur pendant après la
/// destruction de l'arbre. Injectée par la PORTÉE (constitution XII).
Stream<Position> _aucunePosition(LocationSettings _) => const Stream.empty();

Widget _monter(ProviderContainer container) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProviderScope(
        overrides: [sourcePositionsProvider.overrideWithValue(_aucunePosition)],
        child: InterfaceCoursier(etat: _coursierSeul()),
      ),
    );

void main() {
  testWidgets(
    'sans course ni offre, l\'espace coursier ouvre K1 — c\'est là que Yao décide s\'il travaille',
    (tester) async {
      final (container, _) = _conteneur();
      addTearDown(container.dispose);

      await tester.pumpWidget(_monter(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Tableau de bord'),
        findsOneWidget,
        reason: 'K1 doit être ATTEIGNABLE : sans lui, aucun coursier ne peut '
            'entrer dans le pool depuis l\'app',
      );
    },
  );

  testWidgets(
    'une offre en vol prend tout l\'écran — elle a 40 s, rien ne passe devant',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final (container, _) = _conteneur(offre: _offreEnVol());
      addTearDown(container.dispose);

      await tester.pumpWidget(_monter(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Étal Adjoua'), findsOneWidget, reason: 'K2 est à l\'écran');
      expect(
        find.text('Tableau de bord'),
        findsNothing,
        reason: 'K2 est PLEIN écran : K1 ne reste pas derrière',
      );
    },
  );

  testWidgets(
    'une offre ÉCHUE laisse K2-1b à l\'écran : Yao doit LIRE qu\'il n\'a pas été puni',
    (tester) async {
      // `GET /courses/offre-courante` rend `204` dès qu'une offre est échue.
      // Sans mémoire de l'offre tenue, le panneau « sans pénalité » clignoterait
      // deux secondes avant de disparaître — et un coursier qui ne le lit pas
      // croit avoir été sanctionné.
      final (container, _) = _conteneur(offre: _offreEnVol(dansSecondes: -5));
      addTearDown(container.dispose);

      await tester.pumpWidget(_monter(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('offre-sans-penalite')), findsOneWidget);
      expect(
        find.text('Tableau de bord'),
        findsNothing,
        reason: 'K1 n\'escamote pas le panneau : c\'est Yao qui le referme',
      );

      // Et c'est bien SON geste qui rend la main.
      await tester.tap(find.byKey(const Key('offre-retour')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Tableau de bord'), findsOneWidget);
    },
  );
}
