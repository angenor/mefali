/// Tests widget de **K5 — Caisse & historique** (CRS-06, T070/T071/T072).
///
/// Cible visuelle : `docs/design/png/K5-caisse-historique.png` états 1a, 1b, 1c.
///
/// Ce que ces tests protègent, et pourquoi c'est de l'argent réel :
///
/// - le **solde avancé** affiché est celui du serveur, au franc près, et il est
///   en rouge **seulement** quand quelque chose est engagé (FR-068) ;
/// - une course en cours, une course soldée et une course sans avance ne se
///   lisent **pas pareil** — c'est l'écart entre les trois chiffres qui permet
///   de contester une ligne (FR-069) ;
/// - une avance de commande **prépayée** est ANNONCÉE, jamais masquée : la
///   masquer ferait disparaître un argent que Yao porte toujours (FR-117) ;
/// - **hors ligne, la caisse s'ouvre**, avec son bandeau de fraîcheur (FR-076) ;
/// - l'état vide montre le solde **à 0** plutôt qu'une carte manquante (FR-077).
///
/// ⚠ Aucun montant n'est asserté par une chaîne écrite à la main : le
/// séparateur de milliers est une espace fine insécable, invisible à la
/// relecture — `formaterMontant` fait foi (piège des cycles précédents).
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/caisse/ecran_caisse.dart';
import 'package:mefali_pro/coursier/caisse/etat_caisse.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';

const _commande = '019fa000-0000-7000-8000-00000000000b';

/// La caisse de la maquette 1a : une course en cours, deux soldées, une
/// indemnisation validée.
Map<String, Object?> _caisse({
  int avance = 5550,
  int courses = 1,
  int enAttenteReglement = 0,
  bool ecartPlafond = false,
  List<Object?>? historique,
  List<Object?>? indemnisations,
  List<Object?>? litiges,
  Map<String, Object?>? positions,
  List<Object?>? creances,
}) =>
    {
      'avance_en_cours_unites': avance,
      'courses_concernees': courses,
      'avances_en_attente_reglement_unites': enAttenteReglement,
      'historique_du_jour': historique ??
          const [
            {
              'commande_id': _commande,
              'livraison_id': null,
              'reference': '#418',
              'avance_unites': 5550,
              'rembourse_unites': 0,
              'gain_unites': 450,
              'terminee': false,
              'en_attente_reglement': false,
              'heure': '2026-07-31T14:32:00Z',
            },
            {
              'commande_id': _commande,
              'livraison_id': null,
              'reference': '#412',
              'avance_unites': 3200,
              'rembourse_unites': 3200,
              'gain_unites': 300,
              'terminee': true,
              'en_attente_reglement': false,
              'heure': '2026-07-31T13:45:00Z',
            },
            {
              'commande_id': _commande,
              'livraison_id': null,
              'reference': '#407',
              'avance_unites': 0,
              'rembourse_unites': 0,
              'gain_unites': 250,
              'terminee': true,
              'en_attente_reglement': false,
              'heure': '2026-07-31T11:20:00Z',
            },
          ],
      'indemnisations': indemnisations ??
          const [
            {
              'id': '019fa000-0000-7000-8000-0000000000c1',
              'commande_id': _commande,
              'commande_reference': '#398',
              'montant_unites': 200,
              'devise': 'XOF',
              'etat': 'validee',
              'litige_id': null,
              'motif_cle': 'echec.client_absent',
              'decision_motif_cle': null,
              'decide_le': '2026-07-30T18:00:00Z',
              'cree_le': '2026-07-30T17:00:00Z',
            },
          ],
      'litiges_en_cours': litiges ?? const <Object?>[],
      'devise': 'XOF',
      'ecart_plafond': ecartPlafond,
      // Cycle PAY 011 — champs du contrat. Le client généré les exige : une
      // fixture incomplète ferait échouer la désérialisation, et l'écran
      // rendrait une page blanche sans qu'aucune assertion ne dise pourquoi.
      'positions': positions ??
          const {
            'avance_non_recuperee_unites': 0,
            'du_par_mefali_unites': 0,
            'detenu_pour_mefali_unites': 0,
          },
      'creances': creances ?? const [],
    };

/// La caisse vide de la maquette 1b — solde à 0, aucune ligne.
Map<String, Object?> _caisseVide() => _caisse(
      avance: 0,
      courses: 0,
      historique: const [],
      indemnisations: const [],
    );

ProviderContainer _conteneur(
  Map<String, Object?> caisse, {
  int couperApres = -1,
}) {
  var appels = 0;
  final transport = TransportFake((requete) {
    appels++;
    // Piège payé : couper D'EMBLÉE ne laisse rien en cache. Le vrai scénario
    // est « la caisse est lue en ligne, PUIS le réseau tombe ».
    if (couperApres >= 0 && appels > couperApres) {
      throw DioException.connectionError(
        requestOptions: requete,
        reason: 'mode avion',
      );
    }
    if (requete.path.contains('/moi/caisse')) return reponseJson(caisse);
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  return conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
    supplements: [baseOfflineProvider.overrideWithValue(BaseOffline.memoire())],
  );
}

Widget _monter(ProviderContainer container, {VoidCallback? enLigne}) =>
    harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: EcranCaisse(onPasserEnLigne: enLigne),
    );

Future<void> _poser(
  WidgetTester tester,
  ProviderContainer container, {
  VoidCallback? enLigne,
}) async {
  tester.view.physicalSize = const Size(1080, 6400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_monter(container, enLigne: enLigne));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('K5-1a — le solde avancé s\'affiche en danger, au franc près',
      (tester) async {
    final container = _conteneur(_caisse());
    addTearDown(container.dispose);
    await _poser(tester, container);

    final montant = tester.widget<Text>(find.byKey(const Key('caisse-solde-montant')));
    expect(montant.data, formaterMontant(5550, 'XOF'));
    expect(montant.style?.color, MefaliTokens.danger);
    expect(montant.style?.fontSize, MefaliTokens.displaySize);
  });

  testWidgets('K5-1a — les trois chiffres distinguent en cours, soldée et sans avance',
      (tester) async {
    final container = _conteneur(_caisse());
    addTearDown(container.dispose);
    await _poser(tester, container);

    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('caisse-ligne-#418'))),
    )!;

    // #418 en cours : avancé + gain, PAS de « remboursé ✓ ».
    expect(
      find.text(t.crsCaisseLigneEnCours(
        formaterMontant(5550, 'XOF'),
        formaterMontant(450, 'XOF'),
      )),
      findsOneWidget,
    );
    // #412 soldée : les trois chiffres.
    expect(
      find.text(t.crsCaisseLigneAvanceGain(
        formaterMontant(3200, 'XOF'),
        formaterMontant(300, 'XOF'),
      )),
      findsOneWidget,
    );
    // #407 sans avance : dire « remboursé ✓ » sur une course où rien n'a été
    // avancé serait faux.
    expect(
      find.text(t.crsCaisseLigneSansAvance(formaterMontant(250, 'XOF'))),
      findsOneWidget,
    );
    // L'heure SERVEUR de la course soldée, en chip (FR-010).
    expect(find.text(t.crsCaisseChipTerminee('13:45')), findsOneWidget);
  });

  testWidgets('K5-1a — une indemnisation validée porte son chip success',
      (tester) async {
    final container = _conteneur(_caisse());
    addTearDown(container.dispose);
    await _poser(tester, container);

    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('caisse-solde-montant'))),
    )!;
    expect(find.text(t.crsCaisseIndemnisationValidee), findsOneWidget);
    expect(
      find.text(t.crsCaisseIndemnisationMontant(formaterMontant(200, 'XOF'))),
      findsOneWidget,
    );
  });

  testWidgets('FR-117 — une avance prépayée est ANNONCÉE, jamais masquée',
      (tester) async {
    final container = _conteneur(_caisse(enAttenteReglement: 3200));
    addTearDown(container.dispose);
    await _poser(tester, container);

    final texte = tester.widget<Text>(
      find.byKey(const Key('caisse-en-attente-reglement')),
    );
    expect(texte.data, contains(grouperMilliers(3200)));
    expect(texte.style?.color, MefaliTokens.warning);
  });

  testWidgets('FR-078 — l\'écart au plafond se voit, il ne se tait pas',
      (tester) async {
    final container = _conteneur(_caisse(ecartPlafond: true));
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.byKey(const Key('caisse-ecart-plafond')), findsOneWidget);
  });

  testWidgets('K5-1b — sans course, le solde reste affiché À ZÉRO en neutre',
      (tester) async {
    final container = _conteneur(_caisseVide());
    addTearDown(container.dispose);
    var passe = false;
    await _poser(tester, container, enLigne: () => passe = true);

    expect(find.byKey(const Key('caisse-vide')), findsOneWidget);
    final montant = tester.widget<Text>(
      find.byKey(const Key('caisse-solde-montant')),
    );
    expect(montant.data, formaterMontant(0, 'XOF'));
    // Neutre, pas rouge : encadrer de rouge un compteur vide apprendrait à
    // ignorer le rouge.
    expect(montant.style?.color, MefaliTokens.text);

    await tester.tap(find.byKey(const Key('caisse-passer-en-ligne')));
    await tester.pump();
    expect(passe, isTrue);
  });

  testWidgets('K5-1c — un litige affiche son engagement de rappel',
      (tester) async {
    final container = _conteneur(_caisse(litiges: const [
      {
        'id': '019fa000-0000-7000-8000-0000000000d1',
        'commande_id': _commande,
        'reference': '#405',
        'etat_cle': 'litige.en_examen',
        'montant_unites': 500,
        'ouvert_le': '2026-07-31T09:00:00Z',
      },
    ]));
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(
      find.byKey(const Key('caisse-litige-019fa000-0000-7000-8000-0000000000d1')),
      findsOneWidget,
    );
    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('caisse-solde-montant'))),
    )!;
    expect(find.text(t.crsCaisseLitigeTitre('#405')), findsOneWidget);
    expect(
      find.text(t.crsCaisseLitigeEngagement(formaterMontant(500, 'XOF'))),
      findsOneWidget,
    );
    // Le badge d'entête bascule de la date au décompte de litiges (1c).
    expect(find.text(t.crsCaisseLitigeBadge(1)), findsOneWidget);
  });

  testWidgets('FR-076 — hors ligne, la caisse s\'ouvre et se DIT datée',
      (tester) async {
    // Chargée EN LIGNE (1 appel), puis le réseau tombe.
    final container = _conteneur(_caisse(), couperApres: 1);
    addTearDown(container.dispose);
    await _poser(tester, container);

    // Le rechargement retombe sur le cache local. ⚠ `invalidate` + `pump`, et
    // surtout PAS un `await` sur le rafraîchissement : l'horloge d'un test
    // widget est simulée, et attendre dehors un futur qui n'avance que dans les
    // `pump` bloque jusqu'au délai de garde.
    container.invalidate(etatCaisseProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    final etat = container.read(etatCaisseProvider).value!;
    expect(etat.horsLigne, isTrue);
    expect(etat.avanceEnCoursUnites, 5550);
    expect(etat.historique, hasLength(3));
    expect(etat.luLe, isNotNull);

    final t = AppLocalizations.of(
      tester.element(find.byKey(const Key('caisse-solde-montant'))),
    )!;
    expect(find.text(t.crsCaisseHorsLigne), findsOneWidget);
  });

  testWidgets('un refus SERVEUR se dit en clair, avec de quoi réessayer',
      (tester) async {
    final transport = TransportFake((requete) {
      return reponseJson({'code': 'role_requis'}, statut: 403);
    });
    final container = conteneurMefali(
      jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
      transport: transport,
      supplements: [
        baseOfflineProvider.overrideWithValue(BaseOffline.memoire()),
      ],
    );
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.byKey(const Key('caisse-erreur')), findsOneWidget);
    expect(find.byKey(const Key('caisse-reessayer')), findsOneWidget);
  });
}
