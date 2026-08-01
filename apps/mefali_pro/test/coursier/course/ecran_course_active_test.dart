/// Tests widget de l'écran **K3 — course active** (CRS-03, T032).
///
/// Cible visuelle : `docs/design/png/K3-course-active.png`. Ce que ces tests
/// prouvent, et qui compte pour Yao :
///
/// - **un seul arrêt est développé** — c'est ce qui l'empêche de payer chez le
///   mauvais vendeur ;
/// - déclarer un article indisponible fait **baisser le montant tout de suite**,
///   sans attendre le serveur (FR-013, SC-002) ;
/// - hors ligne, le scan et les coches restent **visiblement actifs** ; seuls
///   l'itinéraire et l'appel sont grisés, **avec leur explication** (FR-026) ;
/// - quand tout est collecté, l'écran bascule seul vers « en route vers le
///   client », avec le montant à encaisser (K3-1c).
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/course/ecran_course_active.dart';
import 'package:mefali_pro/coursier/course/etat_course.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';

const _livraison = '019fa000-0000-7000-8000-00000000000a';

/// Corps de `GET /courses/active`, tel que le contrat le rend.
Map<String, Object?> _course({
  String etat = 'en_collecte',
  bool premierCollecte = false,
  bool toutCollecte = false,
  String statutLigne = 'presente',
  int retenueUnites = 0,
}) =>
    {
      'livraison_id': _livraison,
      'commande_id': '019fa000-0000-7000-8000-00000000000b',
      'etat': etat,
      'devise': 'XOF',
      'arrets': [
        _arret(
          id: '019fa000-0000-7000-8000-000000000001',
          nom: 'Étal Adjoua',
          ordre: 0,
          statut: (premierCollecte || toutCollecte) ? 'collecte' : 'a_collecter',
          ligneId: '019fa000-0000-7000-8000-0000000000f1',
          libelle: 'Tomates',
          prix: 400,
          retenueUnites: retenueUnites,
          statutLigne: statutLigne,
        ),
        _arret(
          id: '019fa000-0000-7000-8000-000000000002',
          nom: 'Étal Konan',
          ordre: 1,
          statut: toutCollecte ? 'collecte' : 'a_collecter',
          ligneId: '019fa000-0000-7000-8000-0000000000f2',
          libelle: 'Poisson fumé',
          prix: 800,
        ),
      ],
      'client': {
        'nom_usage': null,
        'telephone': '+2250700000002',
        'repere_texte': 'Cour verte après la pharmacie',
        'repere_vocal_url': null,
        'repere_vocal_duree_s': null,
        'lieu_lat': 5.905,
        'lieu_lon': -4.830,
        'depot_autorise': false,
      },
      'remise': {
        'empreinte_code': 'a1b2',
        'empreinte_jeton': 'c3d4',
        'essais_consommes': 0,
        'essais_max': 3,
        'code_bloque': false,
        'montant_a_encaisser_unites': 5800,
        'mode_paiement': 'cash',
        'preuves': {
          'appels_min': 2,
          'espacement_s': 180,
          'presence_s': 600,
          'rayon_m': 100,
          'photos_min': 1,
        },
        // La cible de « je suis arrivé chez le client » (FR-053). Sans elle, le
        // bouton n'a rien à transitionner et ne fait rien.
        'arret_remise_id': '019fa000-0000-7000-8000-0000000000e1',
        'arret_remise_statut': 'a_collecter',
      },
    };

Map<String, Object?> _arret({
  required String id,
  required String nom,
  required int ordre,
  required String statut,
  required String ligneId,
  required String libelle,
  required int prix,
  String statutLigne = 'presente',
  int retenueUnites = 0,
}) =>
    {
      'arret_id': id,
      'ordre': ordre,
      'prestataire_id': '019fa000-0000-7000-8000-00000000000$ordre',
      'nom': nom,
      'site_lat': 5.898,
      'site_lon': -4.823,
      'distance_precedent_m': null,
      'empreinte_jeton': 'jeton-$ordre',
      'empreinte_code': 'code-$ordre',
      // Cycle PAY 011 : `montant_avance` est le NET. Sans livraison offerte
      // (le cas par défaut), il coïncide avec le brut.
      'montant_avance': prix * 2 - retenueUnites,
      'montant_articles_unites': prix * 2,
      'retenue_appliquee_unites': retenueUnites,
      'photo_exigee': false,
      'distance_max_m': 100,
      'statut': statut,
      'en_route_le': null,
      'arrive_le': null,
      'collecte_le': statut == 'collecte' ? '2026-07-28T14:32:00Z' : null,
      'telephone_vendeur': '+2250700000099',
      'lignes': [
        {
          'ligne_id': ligneId,
          'libelle': libelle,
          'quantite': 2,
          'prix_unitaire_unites': prix,
          'preference_substitution': 'appeler',
          'statut': statutLigne,
        },
      ],
    };

ProviderContainer _conteneur({
  Map<String, Object?>? course,
  /// Coupe le réseau APRÈS le nombre d'appels indiqué. Une coupure d'emblée ne
  /// laisserait rien en cache — et l'écran dirait « aucune course », ce qui est
  /// juste mais ne teste pas le bandeau. Le vrai scénario est : la course est
  /// chargée, PUIS le réseau tombe.
  int couperApres = -1,
}) {
  var appels = 0;
  final transport = TransportFake((requete) {
    appels++;
    if (couperApres >= 0 && appels > couperApres) {
      throw DioException.connectionError(
        requestOptions: requete,
        reason: 'mode avion',
      );
    }
    if (requete.path.contains('/courses/active')) {
      if (course == null) return reponseJson(<String, Object?>{}, statut: 204);
      return reponseJson(course);
    }
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  return conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
    // La base locale de PRODUCTION ouvre un fichier via `path_provider`, canal
    // de plateforme qu'un test widget ne sert pas. On surcharge la DÉPENDANCE
    // (la base), jamais le sujet (l'état de course) — patron du harnais.
    supplements: [baseOfflineProvider.overrideWithValue(BaseOffline.memoire())],
  );
}

/// Écran assez HAUT pour que tout K3 soit construit : un `ListView` ne bâtit
/// que ce qui entre dans la fenêtre, et un `find` sur une carte hors écran
/// échouerait sans que rien ne soit cassé.
Future<void> _ecranHaut(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _monter(ProviderContainer container) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EcranCourseActive(),
    );

Future<void> _poser(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(_monter(container));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('K3-1a : un seul arrêt développé, avec sa checklist et son montant',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course());
    addTearDown(container.dispose);
    await _poser(tester, container);

    // L'arrêt courant est développé : son rang, sa checklist, ses actions.
    expect(find.text('Arrêt 1 / 2'), findsOneWidget);
    expect(find.text('Tomates — 2'), findsOneWidget);
    expect(find.text('Itinéraire'), findsOneWidget);

    // Le second arrêt est REPLIÉ : son article n'apparaît pas. C'est ce qui
    // empêche Yao de payer chez le mauvais vendeur.
    expect(find.text('Étal Konan'), findsOneWidget);
    expect(find.text('Poisson fumé — 2'), findsNothing);

    // Le montant à payer à CE vendeur : 2 × 400.
    expect(find.text('Payez à Étal Adjoua'), findsOneWidget);
    expect(find.text(formaterMontant(800, 'XOF')), findsWidgets);
  });

  testWidgets('FR-013 : une ligne retirée fait baisser le montant tout de suite',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course(statutLigne: 'retiree'));
    addTearDown(container.dispose);
    await _poser(tester, container);

    // La ligne reste VISIBLE, barrée, avec la raison choisie par le client.
    expect(find.text('Tomates — 2'), findsOneWidget);
    expect(
      find.text('Indisponible — le client veut être appelé'),
      findsOneWidget,
      reason: 'Yao doit savoir POURQUOI il n\'achète pas cet article',
    );
    // Et le montant de l'arrêt tombe à zéro : plus rien à avancer ici.
    expect(find.text(formaterMontant(0, 'XOF')), findsOneWidget);
  });

  testWidgets(
      'FR-092 : la livraison offerte est expliquée, pas seulement déduite',
      (tester) async {
    await _ecranHaut(tester);
    // Articles 800, le vendeur prend 500 de livraison à sa charge → 300 à payer.
    final container = _conteneur(course: _course(retenueUnites: 500));
    addTearDown(container.dispose);
    await _poser(tester, container);

    // Le CALCUL est affiché, pas seulement son résultat : un coursier qui voit
    // un montant plus bas que ce que le vendeur réclame doit pouvoir montrer
    // pourquoi, au comptoir, sans appeler l'agence.
    expect(find.text('Livraison offerte par le vendeur'), findsOneWidget);
    expect(find.text('Articles'), findsOneWidget);
    expect(find.text(formaterMontant(800, 'XOF')), findsWidgets,
        reason: 'le brut reste lisible — c\'est ce que le vendeur facture');
    expect(find.text('− ${formaterMontant(500, 'XOF')}'), findsOneWidget);
    expect(find.text('à payer'), findsOneWidget);
    expect(find.text(formaterMontant(300, 'XOF')), findsWidgets,
        reason: 'le net est ce que Yao sort de sa poche');
  });

  testWidgets(
      'sans livraison offerte, aucune explication ne vient encombrer la carte',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course());
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.text('Livraison offerte par le vendeur'), findsNothing);
  });

  testWidgets('K3-1b : hors ligne, le scan reste actif et le grisage s\'explique',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course(), couperApres: 1);
    addTearDown(container.dispose);
    await _poser(tester, container);
    // Le réseau tombe : on force un rechargement, le cache prend le relais.
    container.invalidate(etatCourseActiveProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Le bandeau dit ce qui CONTINUE de marcher.
    expect(find.text('Actions enregistrées, synchronisation auto'), findsOneWidget);
    expect(
      find.text('Le scan et les coches fonctionnent hors connexion'),
      findsOneWidget,
    );
  });

  testWidgets('K3-1c : tout collecté, l\'écran bascule vers le client',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course(toutCollecte: true));
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.text('En route vers le client'), findsOneWidget);
    expect(find.text('2 arrêts collectés — tout est dans le sac'), findsOneWidget);
    // Le repère prend la place du nom d'usage, qui n'existe pas au MVP.
    expect(find.text('Cour verte après la pharmacie'), findsOneWidget);
    // Le montant à encaisser vient du SERVEUR (5 800), pas de la somme des
    // lignes (2 400) : il inclut la livraison, que l'app ne connaît pas.
    expect(find.text(formaterMontant(5800, 'XOF')), findsOneWidget);
    expect(find.text('Je suis arrivé chez le client'), findsOneWidget);
    // La checklist n'est plus à l'écran : la collecte est finie.
    expect(find.text('Tomates — 2'), findsNothing);
  });

  testWidgets('K3-1b : un arrêt collecté est replié avec son heure',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course(premierCollecte: true));
    addTearDown(container.dispose);
    await _poser(tester, container);

    // Le premier est replié avec son heure ; le second devient le courant.
    expect(find.textContaining('Collecté'), findsOneWidget);
    expect(find.text('Arrêt 2 / 2'), findsOneWidget);
    expect(find.text('Poisson fumé — 2'), findsOneWidget);
  });

  testWidgets('SANS RÉSEAU, « je suis arrivé chez le client » ouvre quand même K4',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course(toutCollecte: true), couperApres: 1);
    await _poser(tester, container);

    await tester.tap(find.text('Je suis arrivé chez le client'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // L'écran suit ce que Yao vient de faire, sans attendre un statut serveur
    // qui ne peut pas venir. Sans état local, la course était intransmissible
    // hors ligne : le bouton restait, indéfiniment (T087, SC-003).
    expect(find.text('Je suis arrivé chez le client'), findsNothing);
    expect(find.text('SCANNER LE QR DU CLIENT'), findsOneWidget);

    // Démontage EXPLICITE : le drain a échoué (réseau coupé) et s'est
    // reprogrammé. Le minuteur meurt avec la portée — encore faut-il fermer la
    // portée avant que `flutter_test` ne compte les minuteurs en vol.
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets('une remise validée SANS RÉSEAU ferme l\'écran de remise',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course(toutCollecte: true));
    addTearDown(container.dispose);
    await _poser(tester, container);

    // Ce que `EtatRemiseNotifier.confirmer` écrit quand le réseau manque.
    final file = container.read(fileActionsProvider);
    await file.avancerRemiseLocalement(_livraison, 'arrive');
    await file.marquerRemiseValideeLocalement(_livraison, DateTime.now());
    container.invalidate(etatCourseActiveProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Fini pour Yao — et dit sans mentir : rien n'est clos côté serveur.
    expect(find.text('Course terminée'), findsOneWidget);
    expect(
      find.text(
          'Validée sur place. Elle partira au serveur dès le retour du réseau.'),
      findsOneWidget,
    );
    // Et surtout : plus aucune action. L'écran ne repropose pas de scanner une
    // commande déjà remise.
    expect(find.text('SCANNER LE QR DU CLIENT'), findsNothing);
    expect(find.text('Saisir le code à 4 chiffres'), findsNothing);
  });

  testWidgets('sans course assignée, l\'écran le dit et ne bricole rien',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.text('Arrêt 1 / 2'), findsNothing);
    expect(find.text('SCANNER LE QR du vendeur'), findsNothing);
  });
}
