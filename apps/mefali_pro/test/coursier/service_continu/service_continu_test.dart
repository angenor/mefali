/// Tests d'**US7 — être réveillé par une offre** (CRS-02, T078 → T082).
///
/// Ce que ces tests protègent, et pourquoi c'est du travail perdu sinon :
///
/// - **le service suit la bascule** en ligne / hors ligne (FR-111, FR-112). Un
///   service qui survivrait à la mise hors ligne viderait la batterie de
///   quelqu'un qui a fini sa journée ; un service qui ne démarrerait pas à la
///   mise en ligne laisserait Yao sortir du vivier sans le savoir ;
/// - **les deux silences obligatoires** (FR-101, FR-102) : hors ligne, aucune
///   offre ne peut lui parvenir ; en course, `course_active` l'exclut du
///   vivier. Sonner dans ces cas-là, c'est le faire sortir son téléphone au
///   milieu d'un marché pour rien ;
/// - **jamais deux horloges d'offre** (R13) : au premier plan, l'aiguillage
///   interroge toutes les 2 s ; en arrière-plan, le service. Doubler le débit
///   coûte la batterie et le forfait prépayé de Yao ;
/// - **un refus de permission ou un arrêt système se DIT** (FR-115). Le
///   silence ferait croire qu'il n'y a pas de courses ;
/// - **le compte à rebours annoncé est le temps RÉELLEMENT restant** (FR-100) :
///   entre l'émission et le réveil, des secondes sont passées, et afficher la
///   durée nominale du timer ferait croire à Yao qu'il a le temps.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/course/etat_course.dart';
import 'package:mefali_pro/coursier/disponibilite/etat_disponibilite.dart';
import 'package:mefali_pro/coursier/service_continu/canal_offre.dart';
import 'package:mefali_pro/coursier/service_continu/service_continu.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

/// `GET /moi/disponibilite` — l'état que le porteur charge à sa construction.
Map<String, Object?> _disponibilite({bool enLigne = false}) => {
      'jour': '2026-07-31',
      'en_ligne': enLigne,
      'dans_le_pool': enLigne,
      'plafond_declare_unites': enLigne ? 10000 : null,
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

/// Une offre en vol, dont l'échéance est **dans le futur proche**.
Map<String, Object?> _offre({int restantS = 31}) => {
      'offre_id': '019fa000-0000-7000-8000-000000000001',
      'commande_id': '019fa000-0000-7000-8000-000000000002',
      'mode': 'cascade',
      'echeance_le': DateTime.now()
          .toUtc()
          .add(Duration(seconds: restantS))
          .toIso8601String(),
      'timer_s': 40,
      'restant_s': restantS,
      'arrets': const <Object?>[],
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
        'plafond_retenu_unites': 20000,
        'devise': 'XOF',
      },
      'degraded': false,
    };

/// Textes du service — le point de montage les résout depuis l'ARB ; ici on en
/// pose des repérables, pour vérifier CE QUI est annoncé.
TextesService _textes() => TextesService(
      notificationTitre: 'Mefali — en ligne',
      notificationTexte: 'Vous recevez les offres.',
      canalServiceNom: 'Mefali — en ligne',
      canalOffreNom: 'Offres de course',
      canalOffreDescription: 'Sonnerie prolongée.',
      offreTitre: 'Une course pour vous',
      offreTexte: (n) => 'reste:$n',
    );

/// Course active FIXE — le vrai porteur lit un cache drift qu'un test widget
/// ne fournit pas.
class _EnCourse extends EtatCourseActive {
  @override
  Future<EtatCourse> build() async => const EtatCourse(
        livraisonId: '019fa000-0000-7000-8000-0000000000f1',
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

({
  ProviderContainer container,
  ServicePremierPlanInerte service,
  CanalOffreMuet canal,
}) _monde({
  bool enLigne = false,
  bool servicePermis = true,
  bool sonneriePermise = true,
  Map<String, Object?>? offre,
  bool enCourse = false,
}) {
  final service = ServicePremierPlanInerte(autorise: servicePermis);
  final canal = CanalOffreMuet(permissionAccordee: sonneriePermise);

  // L'état bascule VRAIMENT : `PUT /moi/disponibilite` rend l'état demandé, pas
  // l'état initial. Un double qui rendrait toujours la même chose ferait passer
  // ces tests sans que la bascule n'ait jamais eu lieu — c'est exactement le
  // « double qui ment » du cycle 009.
  var enLigneCourant = enLigne;

  final transport = TransportFake((requete) {
    if (requete.path.contains('/moi/disponibilite')) {
      if (requete.method == 'PUT') {
        final corps = requete.data;
        enLigneCourant = corps is Map && corps['en_ligne'] == true;
      }
      return reponseJson(_disponibilite(enLigne: enLigneCourant));
    }
    if (requete.path.contains('/offre-courante')) {
      if (offre == null) return reponseJson(<String, Object?>{}, statut: 204);
      return reponseJson(offre);
    }
    if (requete.path.contains('/courses/active')) {
      return reponseJson(<String, Object?>{}, statut: 204);
    }
    if (requete.path.contains('/moi/position')) {
      return reponseJson({'dans_le_pool': true, 'prochaine_publication_s': 30});
    }
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });

  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
    supplements: [
      baseOfflineProvider.overrideWithValue(BaseOffline.memoire()),
      servicePremierPlanProvider.overrideWithValue(service),
      canalOffreProvider.overrideWithValue(canal),
      textesServiceProvider.overrideWithValue(_textes()),
      if (enCourse) etatCourseActiveProvider.overrideWith(_EnCourse.new),
    ],
  );
  return (container: container, service: service, canal: canal);
}

/// Laisse tourner les futures en vol sans horloge simulée : ces tests portent
/// sur un porteur, pas sur un arbre de widgets.
Future<void> _laisserTourner() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

@Dependencies([ServiceContinu])
void main() {
  test('FR-111 — passer en ligne démarre le service et prépare la sonnerie',
      () async {
    final m = _monde();
    addTearDown(m.container.dispose);

    // Le porteur écoute la bascule dès sa construction.
    m.container.read(serviceContinuProvider);
    await m.container.read(disponibiliteProvider.notifier).passerEnLigne(10000);
    await _laisserTourner();

    expect(m.service.demarrages, 1, reason: 'le service DOIT démarrer');
    expect(m.canal.prepare, isTrue, reason: 'le canal d\'offre est créé AVANT '
        'la première sonnerie : Android fige ses réglages à la création');
    expect(m.container.read(serviceContinuProvider).actif, isTrue);
  });

  test('FR-112 — passer hors ligne arrête TOUT : service, sonnerie, horloges',
      () async {
    final m = _monde(enLigne: true);
    addTearDown(m.container.dispose);

    m.container.read(serviceContinuProvider);
    await m.container.read(disponibiliteProvider.notifier).passerEnLigne(10000);
    await _laisserTourner();
    expect(m.container.read(serviceContinuProvider).actif, isTrue);

    await m.container.read(disponibiliteProvider.notifier).passerHorsLigne();
    await _laisserTourner();

    expect(m.service.arrets, greaterThanOrEqualTo(1));
    expect(m.canal.taires, greaterThanOrEqualTo(1),
        reason: 'une notification d\'offre en vol ne survit pas à la mise '
            'hors ligne');
    expect(m.container.read(serviceContinuProvider).actif, isFalse);
  });

  test('FR-115 — une permission refusée se DIT, elle ne se tait pas', () async {
    final m = _monde(sonneriePermise: false);
    addTearDown(m.container.dispose);

    m.container.read(serviceContinuProvider);
    await m.container.read(disponibiliteProvider.notifier).passerEnLigne(10000);
    await _laisserTourner();

    final etat = m.container.read(serviceContinuProvider);
    expect(etat.motif, MotifServiceArrete.permissionRefusee);
    expect(etat.aUnProbleme, isTrue,
        reason: 'sans ce signal, Yao croirait qu\'il n\'y a pas de courses');
  });

  test('FR-115 — un service refusé par le système est signalé, pas subi',
      () async {
    final m = _monde(servicePermis: false);
    addTearDown(m.container.dispose);

    m.container.read(serviceContinuProvider);
    await m.container.read(disponibiliteProvider.notifier).passerEnLigne(10000);
    await _laisserTourner();

    final etat = m.container.read(serviceContinuProvider);
    expect(etat.actif, isFalse);
    expect(etat.aUnProbleme, isTrue);
  });

  test('un arrêt par le système est découvert au retour au premier plan',
      () async {
    final m = _monde();
    addTearDown(m.container.dispose);
    final notifier = m.container.read(serviceContinuProvider.notifier);

    await m.container.read(disponibiliteProvider.notifier).passerEnLigne(10000);
    await _laisserTourner();
    expect(m.container.read(serviceContinuProvider).actif, isTrue);

    // Android tue le service pendant que l'écran est éteint.
    await notifier.changerCycleDeVie(AppLifecycleState.paused);
    m.service.actif = false;
    await notifier.changerCycleDeVie(AppLifecycleState.resumed);
    await _laisserTourner();

    final etat = m.container.read(serviceContinuProvider);
    expect(etat.actif, isFalse);
    expect(etat.motif, MotifServiceArrete.arreteParSysteme,
        reason: 'le découvrir en ne recevant rien serait pire');
  });

  test('R13 — le cycle de vie dit QUI tient l\'horloge d\'offre', () async {
    final m = _monde();
    addTearDown(m.container.dispose);
    final notifier = m.container.read(serviceContinuProvider.notifier);
    // Le chargement de la disponibilité est en vol dès la première lecture :
    // le laisser aboutir AVANT la fin du test, sinon il touche un porteur
    // déjà démonté par le `tearDown`.
    await _laisserTourner();

    expect(m.container.read(serviceContinuProvider).enArrierePlan, isFalse);
    await notifier.changerCycleDeVie(AppLifecycleState.paused);
    expect(m.container.read(serviceContinuProvider).enArrierePlan, isTrue,
        reason: 'l\'aiguillage cesse alors d\'interroger toutes les 2 s');
    await notifier.changerCycleDeVie(AppLifecycleState.resumed);
    expect(m.container.read(serviceContinuProvider).enArrierePlan, isFalse);
  });

  // ── Les deux silences obligatoires, en fonction pure ────────────────────

  group('sonnerieAutorisee (FR-101, FR-102)', () {
    test('hors ligne, le téléphone reste muet', () {
      expect(sonnerieAutorisee(enLigne: false, enCourse: false), isFalse);
    });

    test('en course, le téléphone reste muet — le vivier l\'exclut déjà', () {
      expect(sonnerieAutorisee(enLigne: true, enCourse: true), isFalse);
    });

    test('en ligne et libre, il a le droit de sonner', () {
      expect(sonnerieAutorisee(enLigne: true, enCourse: false), isTrue);
    });
  });

  test('le canal muet retient ce qu\'on lui demande — et rien de plus',
      () async {
    final canal = CanalOffreMuet();
    expect(await canal.preparer(nom: 'n', description: 'd'), isTrue);
    await canal.sonner(
      const AnnonceOffre(offreId: 'o1', titre: 't', texte: 'reste:30'),
    );
    expect(canal.sonnees, hasLength(1));
    expect(canal.sonnees.single.texte, 'reste:30');
    await canal.taire();
    expect(canal.taires, 1);
  });

  test('le service ne sonne jamais au premier plan (R13)', () async {
    final m = _monde(offre: _offre());
    addTearDown(m.container.dispose);
    final notifier = m.container.read(serviceContinuProvider.notifier);

    await m.container.read(disponibiliteProvider.notifier).passerEnLigne(10000);
    await _laisserTourner();
    // Resté au premier plan : c'est l'aiguillage qui interroge.
    await notifier.changerCycleDeVie(AppLifecycleState.resumed);
    await _laisserTourner();

    expect(m.canal.sonnees, isEmpty,
        reason: 'doubler l\'horloge doublerait le débit sans rien couvrir');
  });

  test('en course, aucune sonnerie même en arrière-plan (FR-102)', () async {
    final m = _monde(offre: _offre(), enCourse: true);
    addTearDown(m.container.dispose);
    final notifier = m.container.read(serviceContinuProvider.notifier);

    await m.container.read(disponibiliteProvider.notifier).passerEnLigne(10000);
    await _laisserTourner();
    await notifier.changerCycleDeVie(AppLifecycleState.paused);
    await _laisserTourner();

    expect(m.canal.sonnees, isEmpty);
  });
}
