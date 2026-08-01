/// Tests widget d'**US6 — la journée du coursier et la navigation basse**
/// (CRS-01, T075/T076).
///
/// Cible visuelle : `docs/design/png/K1-disponibilite.png` états 1a et 1b, plus
/// la barre basse commune à K1 et K5.
///
/// Ce que ces tests protègent :
///
/// - **le bandeau de gains dit la vérité** — nombre de courses livrées et somme
///   des parts coursier, dans la devise de la zone (FR-091) ;
/// - **la note reste un tiret** tant qu'AVI n'est pas construit (FR-094), et le
///   taux d'acceptation aussi tant qu'aucune offre décidable n'a été émise : un
///   « 0 % » ferait croire à Yao qu'il refuse tout ;
/// - **le reste disponible** diminue de ce qui est engagé (FR-095) — c'est le
///   nombre qui lui dit s'il peut accepter la course suivante ;
/// - **la barre basse vient SOUS la règle de priorité du cycle 009** : une offre
///   en vol garde l'écran entier, une course active garde la barre mais ouvre
///   sur la course ;
/// - **un réseau muet efface le bandeau, il ne bloque pas K1** — c'est l'écran
///   depuis lequel on se met en ligne.
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

/// `GET /moi/disponibilite` — hors ligne, plafond déjà connu.
Map<String, Object?> _disponibilite() => {
      'jour': '2026-07-31',
      'en_ligne': false,
      'dans_le_pool': false,
      'plafond_declare_unites': null,
      'plafond_retenu_unites': 20000,
      'plafond_source': 'grille_note',
      'palier_note_cle': 'dispatch.palier.entree',
      'note_centiemes': null,
      'devise': 'XOF',
      'periode_position_s': 30,
      'capacites': [
        {'famille': 'transport', 'valeur': 'moto'},
      ],
    };

/// `GET /moi/journee` — sept courses livrées, une avance encore dehors.
Map<String, Object?> _journee({
  int coursesLivrees = 7,
  int gains = 8400,
  int avances = 0,
  int? taux = 92,
}) =>
    {
      'courses_livrees': coursesLivrees,
      'gains_unites': gains,
      'devise': 'XOF',
      'plafond_retenu_unites': 20000,
      'reste_disponible_unites': 20000 - avances,
      'avances_en_cours_unites': avances,
      'taux_acceptation_pourcent': taux,
      'note_centiemes': null,
    };

/// `GET /moi/caisse` — une caisse vide, l'écran K5 s'ouvre quand même.
Map<String, Object?> _caisse() => const {
      'avance_en_cours_unites': 0,
      'courses_concernees': 0,
      'avances_en_attente_reglement_unites': 0,
      'historique_du_jour': <Object?>[],
      'mouvements': <Object?>[],
      'indemnisations': <Object?>[],
      'litiges_en_cours': <Object?>[],
      // Cycle PAY 011 — champs du contrat, exigés par le client généré.
      'positions': {
        'avance_non_recuperee_unites': 0,
        'du_par_mefali_unites': 0,
        'detenu_pour_mefali_unites': 0,
      },
      'creances': <Object?>[],
      'devise': 'XOF',
      'ecart_plafond': false,
    };

ProviderContainer _conteneur({
  Map<String, Object?>? journee,
  bool journeeMuette = false,
  List<dynamic> supplements = const [],
}) {
  final transport = TransportFake((requete) {
    if (requete.path.contains('/moi/journee')) {
      if (journeeMuette) {
        throw DioException.connectionError(
          requestOptions: requete,
          reason: 'mode avion',
        );
      }
      return reponseJson(journee ?? _journee());
    }
    if (requete.path.contains('/moi/caisse')) return reponseJson(_caisse());
    if (requete.path.contains('/offre-courante')) {
      return reponseJson(<String, Object?>{}, statut: 204);
    }
    if (requete.path.contains('/courses/active')) {
      return reponseJson(<String, Object?>{}, statut: 204);
    }
    if (requete.path.contains('/moi/disponibilite')) {
      return reponseJson(_disponibilite());
    }
    if (requete.path.contains('/moi/position')) {
      return reponseJson({'dans_le_pool': true, 'prochaine_publication_s': 30});
    }
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  return conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
    supplements: [
      baseOfflineProvider.overrideWithValue(BaseOffline.memoire()),
      ...supplements,
    ],
  );
}

/// Course active FIXE — le vrai porteur lit un cache drift qu'un test widget
/// ne fournit pas (patron d'`interface_coursier_test`).
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

Stream<Position> _aucunePosition(LocationSettings _) => const Stream.empty();
Future<bool> _permissionAccordee() async => true;
Future<Position?> _aucunReleve() async => null;

EtatRolesData _coursierSeul() => const EtatRolesData(
      charge: true,
      attributions: [
        AttributionPro(role: RolePro.coursier, statut: StatutRolePro.valide),
      ],
      actif: RolePro.coursier,
    );

Widget _monter(ProviderContainer container) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProviderScope(
        overrides: [
          sourcePositionsProvider.overrideWithValue(_aucunePosition),
          permissionPositionProvider.overrideWithValue(_permissionAccordee),
          relevePonctuelProvider.overrideWithValue(_aucunReleve),
        ],
        child: InterfaceCoursier(etat: _coursierSeul()),
      ),
    );

Future<void> _poser(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_monter(container));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('K1-1a — le bandeau de gains montre les courses et leur somme',
      (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);

    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('dispo-gains-montant'))),
    )!;
    expect(find.text(t.crsJourneeCoursesLivrees(7)), findsOneWidget);
    final montant =
        tester.widget<Text>(find.byKey(const Key('dispo-gains-montant')));
    expect(montant.data, formaterMontant(8400, 'XOF'));
    expect(montant.style?.color, MefaliTokens.success);
  });

  testWidgets('FR-094 — la note reste un tiret, le taux réel s\'affiche',
      (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);

    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('dispo-note'))),
    )!;
    expect(
      tester.widget<Text>(find.byKey(const Key('dispo-note'))).data,
      t.crsJourneeNoteAbsente,
      reason: 'AVI n\'existe pas — jamais un 4,8 inventé',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('dispo-acceptation'))).data,
      t.crsJourneeAcceptationValeur(92),
    );
  });

  testWidgets('un taux inconnu s\'efface, il ne devient pas 0 %',
      (tester) async {
    final container = _conteneur(journee: _journee(taux: null));
    addTearDown(container.dispose);
    await _poser(tester, container);

    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('dispo-acceptation'))),
    )!;
    expect(
      tester.widget<Text>(find.byKey(const Key('dispo-acceptation'))).data,
      t.crsJourneeNoteAbsente,
      reason: '0 % ferait croire à Yao qu\'il refuse tout',
    );
  });

  testWidgets('FR-095 — le reste disponible diminue de l\'avance engagée',
      (tester) async {
    final container = _conteneur(journee: _journee(avances: 5550));
    addTearDown(container.dispose);
    await _poser(tester, container);

    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('dispo-reste-disponible'))),
    )!;
    expect(
      tester.widget<Text>(find.byKey(const Key('dispo-reste-disponible'))).data,
      t.crsJourneeResteDisponible(formaterMontant(20000 - 5550, 'XOF')),
    );
    // FR-096 — le raccourci Caisse n'apparaît QUE quand de l'argent est engagé.
    expect(find.byKey(const Key('dispo-raccourci-caisse')), findsOneWidget);
  });

  testWidgets('sans avance engagée, pas de raccourci Caisse encombrant',
      (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.byKey(const Key('dispo-raccourci-caisse')), findsNothing);
    // La barre basse, elle, mène TOUJOURS à la caisse.
    expect(find.byKey(const Key('coursier-nav')), findsOneWidget);
  });

  testWidgets('un réseau muet efface le bandeau — il ne bloque pas K1',
      (tester) async {
    final container = _conteneur(journeeMuette: true);
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.byKey(const Key('dispo-gains-montant')), findsNothing);
    expect(
      find.byKey(const Key('dispo-passer-en-ligne')),
      findsOneWidget,
      reason: 'K1 reste utilisable : c\'est de là que Yao se met en ligne',
    );
  });

  // ── T076 : la navigation basse ───────────────────────────────────────────

  testWidgets('FR-096 — la barre basse mène à la caisse et en revient',
      (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);

    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('coursier-nav'))),
    )!;
    expect(find.text(t.crsNavTableau), findsOneWidget);
    expect(find.text(t.crsNavCourses), findsOneWidget);
    expect(find.text(t.crsNavCaisse), findsOneWidget);

    await tester.tap(find.text(t.crsNavCaisse));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('caisse-solde-montant')), findsOneWidget);
    // La barre survit à la bascule : elle est PERMANENTE (FR-096).
    expect(find.byKey(const Key('coursier-nav')), findsOneWidget);

    await tester.tap(find.text(t.crsNavTableau));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('dispo-gains-montant')), findsOneWidget);
  });

  testWidgets(
      'K5-1b — « Passer en ligne » ramène au tableau, où le plafond se déclare',
      (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);

    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('coursier-nav'))),
    )!;
    await tester.tap(find.text(t.crsNavCaisse));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('caisse-passer-en-ligne')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const Key('dispo-plafond-montant')),
      findsOneWidget,
      reason: 'passer en ligne sans plafond déclaré serait refusé par le '
          'serveur — le bouton conduit là où la décision se prend',
    );
  });

  testWidgets('une course active ouvre sur la course, barre basse comprise',
      (tester) async {
    final container = _conteneur(
      supplements: [etatCourseActiveProvider.overrideWith(_CourseActiveFixe.new)],
    );
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(
      find.text('Étal Adjoua'),
      findsOneWidget,
      reason: 'la destination par défaut suit ce que Yao est en train de faire',
    );
    expect(
      find.byKey(const Key('coursier-nav')),
      findsOneWidget,
      reason: 'consulter sa caisse au milieu d\'une course est légitime',
    );

    // Et la caisse reste atteignable sans perdre la course.
    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('coursier-nav'))),
    )!;
    await tester.tap(find.text(t.crsNavCaisse));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('caisse-solde-montant')), findsOneWidget);
  });
}
