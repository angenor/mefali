/// Tests widget de **K4-1e — les trois preuves** (CRS-05, T059/T060/T061).
///
/// Cible visuelle : `docs/design/png/K4-confirmation-livraison.png` état 1e.
///
/// Ce que ces tests protègent, et pourquoi ça compte pour Yao :
///
/// - **le bouton reste gris** tant que les trois preuves ne sont pas réunies,
///   et il s'active **exactement** à la troisième (FR-058) — les 8 combinaisons
///   sont exercées, comme côté serveur ;
/// - chaque preuve **dit pourquoi** elle n'avance pas. Un compteur figé sans
///   explication ferait recommencer au hasard : deux appels de plus, une photo
///   de plus, alors qu'il manque peut-être trois minutes d'attente ;
/// - **aucune minuterie ne fuit** : le rafraîchissement est local au widget, et
///   un `Timer` resté en vol ferait échouer ces tests (piège du cycle 004).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/preuves/ecran_preuves.dart';
import 'package:mefali_pro/coursier/preuves/etat_preuves.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';

const _livraison = '019fa000-0000-7000-8000-00000000000a';
const _commande = '019fa000-0000-7000-8000-00000000000b';

/// Une course arrivée chez le client — le point d'entrée de K4-1e.
Map<String, Object?> _course() => {
      'livraison_id': _livraison,
      'commande_id': _commande,
      'etat': 'en_livraison',
      'devise': 'XOF',
      'arrets': const <Object?>[],
      'client': const {
        'nom_usage': null,
        'telephone': '+2250700000002',
        'repere_texte': 'Cour verte après la pharmacie',
        'repere_vocal_url': null,
        'repere_vocal_duree_s': null,
        'lieu_lat': 5.905,
        'lieu_lon': -4.830,
        'depot_autorise': false,
      },
      'remise': const {
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
        'arret_remise_id': '019fa000-0000-7000-8000-0000000000aa',
        'arret_remise_statut': 'arrive',
        'arrive_chez_client_le': '2026-07-28T14:56:00Z',
      },
    };

ProviderContainer _conteneur() {
  final transport = TransportFake((requete) {
    if (requete.path.contains('/courses/active')) return reponseJson(_course());
    // Toute écriture réussit : ce fichier teste l'écran, pas le transport.
    return reponseJson(<String, Object?>{}, statut: 201);
  });
  return conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
    supplements: [baseOfflineProvider.overrideWithValue(BaseOffline.memoire())],
  );
}

Widget _monter(ProviderContainer container) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // ⚠ `echantillonner: false` : un échantillonnage réel demanderait le GPS
      // par un canal de plateforme que le test ne sert pas — et armerait la
      // minuterie périodique, qu'aucun `pump` ne pourrait épuiser.
      home: const EcranPreuves(livraisonId: _livraison, echantillonner: false),
    );

Future<void> _poser(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_monter(container));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Pose les preuves demandées **directement dans le porteur d'état**, sans
/// passer par le GPS ni la caméra : c'est l'activation du bouton qu'on teste
/// ici, pas les canaux de plateforme.
void _poserPreuves(
  ProviderContainer container, {
  bool appels = false,
  bool presence = false,
  bool photo = false,
}) {
  final notifier = container.read(etatPreuvesProvider.notifier);
  notifier.state = notifier.state.copieAvec(
    appels: PreuveAppelsVue(
      faits: appels ? 2 : 0,
      requis: 2,
      candidats: appels ? 2 : 0,
      horodatages: appels
          ? [DateTime(2026, 7, 28, 15, 2), DateTime(2026, 7, 28, 15, 6)]
          : const [],
    ),
    presence: PreuvePresenceVue(secondes: presence ? 600 : 0, requis: 600),
    photos: PreuvePhotosVue(faites: photo ? 1 : 0),
  );
}

void main() {
  testWidgets('K4-1e : les trois preuves, leur état et le compteur',
      (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.text('Livraison impossible'), findsWidgets);
    expect(find.textContaining('Réunissez les 3 preuves'), findsOneWidget);
    expect(find.text('2 appels via l\'app'), findsOneWidget);
    expect(find.text('10 min sur place'), findsOneWidget);
    expect(find.text('1 photo du lieu'), findsOneWidget);
    expect(find.text('0 preuve sur 3 réunie'), findsOneWidget);
  });

  testWidgets(
      'FR-058 : le bouton s\'active EXACTEMENT à la troisième preuve — '
      'les 8 combinaisons', (tester) async {
    for (final (appels, presence, photo) in [
      (false, false, false),
      (false, false, true),
      (false, true, false),
      (false, true, true),
      (true, false, false),
      (true, false, true),
      (true, true, false),
      (true, true, true),
    ]) {
      final container = _conteneur();
      await _poser(tester, container);
      _poserPreuves(
        container,
        appels: appels,
        presence: presence,
        photo: photo,
      );
      await tester.pump();

      final bouton = tester.widget<FilledButton>(
        find.byKey(const Key('preuves-declarer')),
      );
      final attendu = appels && presence && photo;
      expect(
        bouton.onPressed != null,
        attendu,
        reason: 'combinaison ($appels, $presence, $photo) : '
            'le bouton devrait être ${attendu ? "actif" : "grisé"}',
      );

      final reunies =
          (appels ? 1 : 0) + (presence ? 1 : 0) + (photo ? 1 : 0);
      expect(find.text('$reunies preuve sur 3 réunie'), findsOneWidget);
      container.dispose();
    }
  });

  testWidgets('une preuve DIT pourquoi elle n\'avance pas', (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);
    final notifier = container.read(etatPreuvesProvider.notifier);

    // Deux appels trop rapprochés : « attends », pas « rappelle ». Et le délai
    // vient de la zone, pas d'un nombre écrit dans l'écran.
    notifier.state = notifier.state.copieAvec(
      appels: const PreuveAppelsVue(
        faits: 1,
        requis: 2,
        espacementS: 180,
        espacementOk: false,
        candidats: 2,
      ),
    );
    await tester.pump();
    expect(find.text('Attendez 180 s entre deux appels'), findsOneWidget);

    // GPS coupé : le décompte ne bouge pas, et l'écran l'explique au lieu de
    // laisser un compteur figé.
    notifier.state = notifier.state.copieAvec(
      presence: const PreuvePresenceVue(gpsIndisponible: true, requis: 600),
    );
    await tester.pump();
    expect(
      find.text('Position indisponible — le décompte est en pause'),
      findsOneWidget,
    );

    // Trop loin : la conduite à tenir est différente — se rapprocher.
    notifier.state = notifier.state.copieAvec(
      presence: const PreuvePresenceVue(
        secondes: 120,
        requis: 600,
        horsRayon: true,
        distanceM: 850,
      ),
    );
    await tester.pump();
    expect(
      find.text('Trop loin du point de livraison (850 m)'),
      findsOneWidget,
    );
  });

  testWidgets('la présence en cours affiche ce qu\'il reste, pas un ratio nu',
      (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);
    final notifier = container.read(etatPreuvesProvider.notifier);

    notifier.state = notifier.state.copieAvec(
      presence: const PreuvePresenceVue(secondes: 360, requis: 600),
    );
    await tester.pump();

    expect(find.text('En cours — encore 4 min'), findsOneWidget);
    expect(find.text('6 / 10 min'), findsOneWidget);
  });

  testWidgets('les appels réunis affichent LEURS HEURES (K4-1e)',
      (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);
    _poserPreuves(container, appels: true);
    await tester.pump();

    expect(find.text('Fait — 15:02 et 15:06'), findsOneWidget);
  });

  testWidgets('hors ligne, les preuves en attente sont annoncées comme telles',
      (tester) async {
    final container = _conteneur();
    addTearDown(container.dispose);
    await _poser(tester, container);
    final notifier = container.read(etatPreuvesProvider.notifier);

    notifier.state = notifier.state.copieAvec(enAttenteDeSynchro: true);
    await tester.pump();

    expect(find.byType(BandeauHorsLigne), findsOneWidget);
  });

  test('l\'espacement se compte depuis le dernier appel RETENU', () {
    final base = DateTime(2026, 7, 28, 15);
    final retenus = appelsRetenus(
      [
        base,
        base.add(const Duration(seconds: 120)), // écarté
        base.add(const Duration(seconds: 240)), // 240 − 0 ≥ 180 → retenu
        base.add(const Duration(seconds: 300)), // écarté
      ],
      180,
    );
    expect(retenus.length, 2);
    expect(retenus.last, base.add(const Duration(seconds: 240)));
  });

  test('R8 — un aller-retour ne vaut pas une présence', () {
    final base = DateTime(2026, 7, 28, 15);
    final duree = dureePresence(
      [
        (quand: base, distanceM: 10),
        (quand: base.add(const Duration(seconds: 30)), distanceM: 10),
        (quand: base.add(const Duration(seconds: 60)), distanceM: 800),
        (quand: base.add(const Duration(seconds: 90)), distanceM: 10),
        (quand: base.add(const Duration(seconds: 120)), distanceM: 10),
      ],
      rayonM: 100,
      trouMaxS: 120,
    );
    expect(duree, 60, reason: 'seuls les deux segments sur place comptent');
  });

  test('R8 — un trou plus long que le seuil ne compte pas', () {
    final base = DateTime(2026, 7, 28, 15);
    expect(
      dureePresence(
        [
          (quand: base, distanceM: 10),
          (quand: base.add(const Duration(seconds: 300)), distanceM: 10),
        ],
        rayonM: 100,
        trouMaxS: 120,
      ),
      0,
    );
  });

  /// **T087, FR-061** — les échantillons ne servent à rien s'ils restent dans
  /// l'appareil : c'est le SERVEUR qui compte la présence (FR-060), et il ne
  /// peut compter que ce qu'il a reçu.
  ///
  /// Le défaut que ce test verrouille a tenu jusqu'à la validation sur
  /// appareil : la file locale se remplissait, l'écran montait bien à 10
  /// minutes, et `GET .../preuves` répondait `presence_aucun_releve` — la
  /// déclaration d'échec était donc refusée pour une preuve réunie.
  test('les relevés de présence PARTENT au serveur, en lot idempotent',
      () async {
    final envoyes = <Map<String, Object?>>[];
    final transport = TransportFake((requete) {
      if (requete.path.contains('/courses/active')) return reponseJson(_course());
      if (requete.path.endsWith('/presence')) {
        final corps = requete.data as Map<String, Object?>;
        envoyes.add(corps);
        return reponseJson({'retenus': 2, 'presence_s': 600, 'requis_s': 600});
      }
      return reponseJson(<String, Object?>{}, statut: 201);
    });
    final container = conteneurMefali(
      jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
      transport: transport,
      supplements: [baseOfflineProvider.overrideWithValue(BaseOffline.memoire())],
    );
    addTearDown(container.dispose);

    final file = container.read(fileActionsProvider);
    await file.enfilerPresence(
      uuidClient: '019fa000-0000-7000-8000-0000000000c1',
      livraisonId: _livraison,
      distanceM: 12,
      releveLeLocal: DateTime(2026, 7, 28, 15),
    );
    await file.enfilerPresence(
      uuidClient: '019fa000-0000-7000-8000-0000000000c2',
      livraisonId: _livraison,
      distanceM: 8,
      releveLeLocal: DateTime(2026, 7, 28, 15, 0, 30),
    );

    await container
        .read(etatPreuvesProvider.notifier)
        .transmettrePresence(_livraison);

    expect(envoyes, hasLength(1), reason: 'un LOT, pas un appel par relevé');
    expect((envoyes.single['releves']! as List).length, 2);

    // Transmis = plus jamais renvoyé : le second appel n'a rien à dire.
    expect(await file.presenceEnAttente(_livraison), isEmpty);
    await container
        .read(etatPreuvesProvider.notifier)
        .transmettrePresence(_livraison);
    expect(envoyes, hasLength(1));
  });
}
