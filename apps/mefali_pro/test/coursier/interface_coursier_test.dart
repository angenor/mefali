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
/// La troisième branche — course assignée ⇒ écran de course — est couverte
/// ici : le porteur de course active est remplacé par un double (`supplements`),
/// parce que le vrai lit un cache drift (SQLite) que `sqlite3_flutter_libs` ne
/// fournit pas en test widget. Le même test suit la chaîne jusqu'au bout et
/// vérifie qu'une **position part** alors que K1 n'a jamais été monté.
///
/// ⚠ **Ce que ce fichier ne couvre PAS** : la bascule K2 → écran de course
/// **après acceptation** n'est vérifiée qu'en aval de la décision (le panneau
/// rend la main, la course est relue). L'enchaînement complet, à l'écran, n'a
/// jamais été OBSERVÉ — ni ici, ni sur émulateur : voir `rapport-ecarts.md` §7,
/// « Non validé visuellement ».
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/course/etat_course.dart';
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

/// Corps de `GET /moi/disponibilite`. Hors ligne par défaut ; [enLigne] rend
/// l'**intention persistée** d'un coursier qui roulait déjà (migration 0013).
Map<String, Object?> _disponibilite({bool enLigne = false}) => {
      // `jour` est REQUIS par le contrat : sans lui, le client généré rejette
      // le corps, `charger()` tombe en `horsLigne` — et le double ment sur
      // exactement ce que ces tests prétendent vérifier.
      'jour': '2026-07-27',
      'en_ligne': enLigne,
      'dans_le_pool': false,
      'plafond_declare_unites': enLigne ? 10000 : null,
      'plafond_retenu_unites': 5000,
      'plafond_source': 'grille_note',
      'palier_note_cle': 'dispatch.palier.entree',
      'note_centiemes': null,
      'devise': 'XOF',
      'periode_position_s': 30,
      'capacites': [
        {'famille': 'transport', 'valeur': 'moto'},
      ],
    };

/// Interrupteur de réseau — le test coupe la ligne AU MOMENT du geste, comme
/// les données mobiles de Tiassalé le font.
class _Reseau {
  bool coupe = false;
}

(ProviderContainer, TransportFake) _conteneur({
  Map<String, Object?>? offre,
  bool enLigne = false,
  List<dynamic> supplements = const [],
  _Reseau? reseau,
}) {
  final transport = TransportFake((requete) {
    if (reseau != null && reseau.coupe) {
      throw DioException.connectionError(
        requestOptions: requete,
        reason: 'réseau coupé',
      );
    }
    if (requete.path.contains('/offre-courante')) {
      if (offre == null) return reponseJson(<String, Object?>{}, statut: 204);
      return reponseJson(offre);
    }
    if (requete.path.contains('/courses/active')) {
      return reponseJson(<String, Object?>{}, statut: 204);
    }
    if (requete.path.contains('/moi/disponibilite')) {
      return reponseJson(_disponibilite(enLigne: enLigne));
    }
    if (requete.path.contains('/moi/position')) {
      return reponseJson({'dans_le_pool': true, 'prochaine_publication_s': 30});
    }
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
    supplements: supplements,
  );
  return (container, transport);
}

/// Course active FIXE — le vrai porteur lit un cache drift (SQLite) qui n'existe
/// pas dans un test widget, et retomberait sur un état vide : l'aiguillage
/// prendrait alors K1, c'est-à-dire exactement la branche que ce double sert à
/// éviter. Surchargé sur le conteneur RACINE (`supplements`) : `EtatCourseActive`
/// est déclaré sans `dependencies`, donc non scopable.
class _CourseActiveFixe extends EtatCourseActive {
  @override
  Future<EtatCourse> build() async => const EtatCourse(
        arrets: [
          ArretCourse(
            arretId: '019fa000-0000-7000-8000-0000000000a1',
            prestataireId: '019fa000-0000-7000-8000-0000000000b1',
            nom: 'Étal Adjoua',
            empreinteJeton: '',
            empreinteCode: '',
            siteLat: 5.8960,
            siteLon: -4.8210,
            montantAvance: 5550,
            devise: 'XOF',
            photoExigee: false,
            distanceMaxM: 120,
            collecte: false,
          ),
        ],
      );
}

/// Position de Tiassalé — ce que le relevé ponctuel rend quand le capteur parle.
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

/// Le capteur RÉPOND — c'est l'état d'un coursier arrêté qui reste joignable.
Future<Position?> _relevePonctuelFixe() async => _positionTiassale();

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

/// Permission ACCORDÉE sans dialogue — un test widget n'en ouvre aucun.
Future<bool> _permissionAccordee() async => true;

/// Aucun relevé ponctuel : la plupart de ces tests ne regardent pas la
/// publication.
Future<Position?> _aucunReleve() async => null;


Widget _monter(
  ProviderContainer container, {
  Future<Position?> Function() releve = _aucunReleve,
}) =>
    harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProviderScope(
        overrides: [
          sourcePositionsProvider.overrideWithValue(_aucunePosition),
          // Aucun dialogue système dans un test widget.
          permissionPositionProvider.overrideWithValue(_permissionAccordee),
          relevePonctuelProvider.overrideWithValue(releve),
        ],
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

  testWidgets(
    'app rouverte sur une COURSE ACTIVE — la position part sans que K1 soit monté',
    (tester) async {
      // Ce que ce test protège, et ce qu'il a coûté de ne pas l'avoir : Android
      // tue l'app d'un coursier qui roule vers son premier vendeur. Il la
      // rouvre, l'aiguillage l'envoie sur l'écran de course — **K1 n'est jamais
      // monté**. Tant que K1 était le seul à charger l'intention d'être en
      // ligne, `enLigne` restait faux, l'émetteur ne démarrait pas, et plus
      // aucune position ne partait. Côté serveur, `reprendre_courses_immobiles`
      // ne voit alors aucune progression et REPREND la course au bout de
      // `dispatch.reassignation_sans_mouvement_s` — rien n'est encore collecté,
      // donc la garde d'argent ne protège pas Yao. Un coursier qui travaille
      // perd sa course : « le coursier ne perd jamais » (cadrage §7.5) mis en
      // défaut.
      final (container, transport) = _conteneur(
        enLigne: true,
        supplements: [etatCourseActiveProvider.overrideWith(_CourseActiveFixe.new)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_monter(container, releve: _relevePonctuelFixe));
      // La chaîne à traverser est longue — charger la disponibilité, en déduire
      // « en ligne », demander la permission, relever, publier — et chaque
      // maillon est une microtask. `pumpAndSettle` ne convient pas : l'écran
      // porte des `Timer.periodic` qui ne se taisent jamais.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        find.text('Étal Adjoua'),
        findsWidgets,
        reason: 'l\'aiguillage doit être sur l\'écran de course, pas sur K1',
      );
      expect(
        find.text('Tableau de bord'),
        findsNothing,
        reason: 'si K1 est monté, ce test ne prouve plus rien',
      );
      expect(
        transport.recues.where((r) => r.path.contains('/moi/position')),
        isNotEmpty,
        reason: 'sans position publiée, le serveur ne voit aucune progression '
            'et reprend la course à un coursier qui roule',
      );
    },
  );

  testWidgets(
    'un refus PERDU sur coupure réseau ne referme pas K2 — sinon il coûte une franchise',
    (tester) async {
      // Ce que ce test protège : l'erreur du refus était AVALÉE et l'écran
      // rendait la main quoi qu'il arrive. Yao croyait avoir refusé ; côté
      // serveur l'offre restait `en_vol`, donc **aucune autre offre ne pouvait
      // lui parvenir** (motif d'écart `offre_en_vol`), elle expirait à 40 s et
      // consommait une des trois franchises du jour.
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final reseau = _Reseau();
      final (container, _) = _conteneur(offre: _offreEnVol(), reseau: reseau);
      addTearDown(container.dispose);

      await tester.pumpWidget(_monter(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Étal Adjoua'), findsOneWidget);

      reseau.coupe = true;
      await tester.tap(find.byKey(const Key('offre-refuser')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(const Key('offre-echec-reseau')),
        findsOneWidget,
        reason: 'un refus qui n\'est pas parti doit se DIRE : sinon Yao croit '
            'avoir refusé et perd une franchise sans le savoir',
      );
      expect(
        find.byKey(const Key('offre-refuser')),
        findsOneWidget,
        reason: 'K2 reste à l\'écran : c\'est le seul endroit d\'où Yao peut '
            'réessayer avant les 40 s',
      );
    },
  );
}
