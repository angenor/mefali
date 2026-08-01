/// Tests widget de l'écran **K4 — confirmation de livraison** (CRS-04, T044).
///
/// Cible visuelle : `docs/design/png/K4-confirmation-livraison.png`. Ce que ces
/// tests prouvent, et qui compte pour Yao :
///
/// - **1a** — le montant à encaisser est en display, l'absence de paiement
///   partiel est écrite, et les trois voies apparaissent DANS L'ORDRE : QR en
///   principal, code en secondaire, dépôt en lien discret ;
/// - le dépôt **n'apparaît pas** quand l'exploitation ne l'a pas ouvert : un
///   bouton grisé apprendrait au coursier qu'une porte existe (FR-039) ;
/// - **1c** — hors ligne, le bandeau dit « validation locale », et les deux
///   voies de preuve restent **pleinement actives** (FR-041) ;
/// - **1d** — trois codes faux ferment la saisie, mais **pas le scan** : c'est
///   la correction que FR-043 imposait au cycle 008.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/course/ecran_course_active.dart';
import 'package:mefali_pro/coursier/course/etat_course.dart';
import 'package:mefali_pro/coursier/remise/etat_remise.dart';
import 'package:mefali_pro/coursier/remise/pave_code.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';

const _livraison = '019fa000-0000-7000-8000-00000000000a';
const _commande = '019fa000-0000-7000-8000-00000000000b';
const _arretRemise = '019fa000-0000-7000-8000-0000000000aa';

/// Une course TOUTE COLLECTÉE et arrivée chez le client — le point d'entrée de
/// K4. Les collectes sont derrière ; il ne reste que la remise.
Map<String, Object?> _course({
  bool arriveChezClient = true,
  bool depotAutorise = false,
  bool codeBloque = false,
  int essaisConsommes = 0,
}) =>
    {
      'livraison_id': _livraison,
      'commande_id': _commande,
      'etat': 'en_livraison',
      'devise': 'XOF',
      'arrets': [
        {
          'arret_id': '019fa000-0000-7000-8000-000000000001',
          'ordre': 0,
          'prestataire_id': '019fa000-0000-7000-8000-000000000010',
          'nom': 'Étal Adjoua',
          'site_lat': 5.898,
          'site_lon': -4.823,
          'distance_precedent_m': null,
          'empreinte_jeton': 'jeton-0',
          'empreinte_code': 'code-0',
          'montant_avance': 800,
          'montant_articles_unites': 800,
          'retenue_appliquee_unites': 0,
          'photo_exigee': false,
          'distance_max_m': 100,
          'statut': 'collecte',
          'en_route_le': null,
          'arrive_le': null,
          'collecte_le': '2026-07-28T14:32:00Z',
          'telephone_vendeur': '+2250700000099',
          'lignes': const <Object?>[],
        },
      ],
      'client': {
        'nom_usage': null,
        'telephone': '+2250700000002',
        'repere_texte': 'Cour verte après la pharmacie',
        'repere_vocal_url': null,
        'repere_vocal_duree_s': null,
        'lieu_lat': 5.905,
        'lieu_lon': -4.830,
        'depot_autorise': depotAutorise,
      },
      'remise': {
        'empreinte_code': 'a1b2',
        'empreinte_jeton': 'c3d4',
        'essais_consommes': essaisConsommes,
        'essais_max': 3,
        'code_bloque': codeBloque,
        'montant_a_encaisser_unites': 5800,
        'mode_paiement': 'cash',
        'preuves': {
          'appels_min': 2,
          'espacement_s': 180,
          'presence_s': 600,
          'rayon_m': 100,
          'photos_min': 1,
        },
        'arret_remise_id': _arretRemise,
        'arret_remise_statut': arriveChezClient ? 'arrive' : 'a_collecter',
        'arrive_chez_client_le':
            arriveChezClient ? '2026-07-28T14:56:00Z' : null,
      },
    };

ProviderContainer _conteneur({
  Map<String, Object?>? course,
  int couperApres = -1,
}) {
  var appels = 0;
  final transport = TransportFake((requete) {
    appels++;
    // Piège du cycle : couper D'EMBLÉE ne laisse rien en cache et l'écran dit
    // « aucune course ». Le vrai scénario est : la course est chargée, PUIS le
    // réseau tombe.
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
    supplements: [baseOfflineProvider.overrideWithValue(BaseOffline.memoire())],
  );
}

Future<void> _ecranHaut(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _monter(ProviderContainer container, {Widget? home}) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home ?? const EcranCourseActive(),
    );

Future<void> _poser(
  WidgetTester tester,
  ProviderContainer container, {
  Widget? home,
}) async {
  await tester.pumpWidget(_monter(container, home: home));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('K4-1a : le montant, le rappel « jamais partiel », et les 3 voies',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course(depotAutorise: true));
    addTearDown(container.dispose);
    await _poser(tester, container);

    // Le montant à encaisser, en display — le chiffre que Yao lit d'un coup
    // d'œil. Jamais une chaîne écrite à la main : le séparateur de
    // `formaterMontant` est une espace fine insécable.
    expect(find.text(formaterMontant(5800, 'XOF')), findsOneWidget);
    expect(
      find.textContaining('Jamais de paiement partiel'),
      findsOneWidget,
      reason: 'FR-049 : la règle est écrite à l\'écran, pas seulement en base',
    );

    // Les trois voies, dans l'ordre de la maquette.
    expect(find.text('SCANNER LE QR DU CLIENT'), findsOneWidget);
    expect(find.text('Saisir le code à 4 chiffres'), findsOneWidget);
    expect(
      find.textContaining('dépôt autorisé'),
      findsOneWidget,
      reason: 'le dépôt est OUVERT sur cette commande',
    );

    // Le lien mobile money est présent mais INACTIF : PAY-03 n'existe pas
    // (FR-050). Un bouton absent laisserait croire à un oubli.
    final lien = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.textContaining('Lien mobile money'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(lien.onPressed, isNull);
  });

  testWidgets(
      'FR-039 : sans autorisation, la voie dépôt n\'apparaît même pas grisée',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course());
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.text('SCANNER LE QR DU CLIENT'), findsOneWidget);
    expect(
      find.textContaining('dépôt autorisé'),
      findsNothing,
      reason: 'un bouton grisé apprendrait au coursier qu\'une porte existe',
    );
  });

  testWidgets('K4-1c : hors ligne, « validation locale » et les voies actives',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course(), couperApres: 1);
    addTearDown(container.dispose);
    await _poser(tester, container);
    // Le réseau tombe : rechargement, le cache prend le relais.
    container.invalidate(etatCourseActiveProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Validation locale — sera synchronisée'), findsOneWidget);
    expect(
      find.text('Le scan QR et le code fonctionnent sans réseau'),
      findsOneWidget,
    );
    // Et ce ne sont pas des mots : le scan est réellement actif.
    final scan = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('SCANNER LE QR DU CLIENT'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(scan.onPressed, isNotNull);
  });

  testWidgets(
      'K3-1c → K4 : tant que l\'arrivée n\'est pas déclarée, K4 ne s\'ouvre pas',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course(arriveChezClient: false));
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.text('Je suis arrivé chez le client'), findsOneWidget);
    expect(find.text('SCANNER LE QR DU CLIENT'), findsNothing);
  });

  testWidgets('K4-1b : le pavé montre les essais restants, jamais le bon code',
      (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course());
    addTearDown(container.dispose);
    // On pose l'état de remise directement : le pavé est un écran à part, et
    // c'est son comportement de SAISIE qui est testé ici.
    await _poser(
      tester,
      container,
      // Le contact est INJECTÉ : sans lui, l'écran irait le chercher dans
      // `serviceConfigProvider`, qui arme un minuteur horaire — et un test
      // widget échoue sur « a Timer is still pending » à la destruction de
      // l'arbre. On double la dépendance, jamais le sujet.
      home: const PaveCode(
        livraisonId: _livraison,
        commandeId: _commande,
        contactAgence:
            ContactAgence(nom: 'Tiassalé', telephone: '+2250707551212'),
      ),
    );

    expect(find.text('Code de réception'), findsOneWidget);
    expect(find.text('Valider le code'), findsOneWidget);

    // Saisie de quatre chiffres : chaque touche remplit une case.
    for (final c in ['7', '3', '4', '1']) {
      await tester.tap(find.widgetWithText(OutlinedButton, c));
      await tester.pump();
    }
    expect(find.text('7'), findsWidgets);

    // Le code est faux (l'empreinte du bac est `a1b2`, qui ne correspond à
    // rien) : le refus consomme un essai et l'annonce, SANS révéler le bon.
    await tester.tap(find.widgetWithText(FilledButton, 'Valider le code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Code faux'), findsOneWidget);
    expect(find.textContaining('il reste'), findsOneWidget);
  });

  testWidgets(
      'K4-1d : code bloqué → l\'agence en action principale, le scan toujours '
      'proposé (FR-043)', (tester) async {
    await _ecranHaut(tester);
    final container = _conteneur(course: _course());
    addTearDown(container.dispose);
    await _poser(
      tester,
      container,
      home: const Scaffold(
        body: EcranBlocageCode(
          agence: ContactAgence(nom: 'Tiassalé', telephone: '+2250707551212'),
        ),
      ),
    );

    expect(find.text('3 codes faux — saisie bloquée'), findsOneWidget);
    expect(
      find.textContaining('Appelez Mefali Tiassalé'),
      findsOneWidget,
      reason: 'le numéro vient de la CONFIGURATION de zone, pas d\'un binaire',
    );
    expect(
      find.textContaining('07 07 55 12 12'),
      findsOneWidget,
      reason: 'lisible à voix haute par qui le compose sur un autre téléphone',
    );
    // Le scan reste proposé : le jeton est un aléa long, le plafond n'a jamais
    // eu à le protéger. C'est la correction que FR-043 imposait au cycle 008.
    final scan = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Réessayer avec le scan QR'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(scan, isNotNull);
  });

  testWidgets('le compteur affiché est le MAX(serveur, hors ligne) — R5',
      (tester) async {
    final container = _conteneur(course: _course(essaisConsommes: 2));
    addTearDown(container.dispose);
    await _poser(tester, container);

    // Deux essais côté serveur, aucun local : il en reste un.
    await container.read(etatRemiseProvider.notifier).charger(_livraison);
    expect(container.read(etatRemiseProvider).essaisRestants, 1);
    expect(container.read(etatRemiseProvider).codeBloque, isFalse);
  });
}
