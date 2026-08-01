/// US4 (PAY-01) — **les six natures d'écriture, distinguées à l'écran**.
///
/// Réf. `docs/design/png/K5-caisse-historique.png`, section historique.
///
/// L'historique agrégé par course ne peut pas porter un règlement d'agence ni
/// un reversement : ils n'appartiennent à aucune course. La liste des
/// mouvements existe pour ça — et un versement invisible est exactement ce que
/// la caisse existe pour empêcher.
///
/// ⚠ Aucun montant n'est asserté par une chaîne écrite à la main : le
/// séparateur de milliers est une espace fine insécable, invisible à la
/// relecture. `formaterMontant` fait foi (piège des cycles précédents).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/caisse/ecran_caisse.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';

const _commande = '019fa000-0000-7000-8000-00000000000b';

Map<String, Object?> _mouvement({
  required String id,
  required String nature,
  required int montant,
  String? reference,
}) =>
    {
      'id': id,
      'type_ecriture': nature,
      'montant_unites': montant,
      // Le SENS vient du serveur : l'app ne tient pas sa propre table.
      'entree': montant > 0,
      'commande_id': reference == null ? null : _commande,
      'reference': reference,
      'heure': '2026-07-31T14:32:00Z',
    };

/// Une caisse portant les **six** natures d'écriture.
Map<String, Object?> _caisse() => {
      'avance_en_cours_unites': 0,
      'courses_concernees': 0,
      'avances_en_attente_reglement_unites': 0,
      'historique_du_jour': const <Object?>[],
      'mouvements': [
        _mouvement(
          id: '019fa000-0000-7000-8000-000000000001',
          nature: 'avance',
          montant: -3000,
          reference: '#418',
        ),
        _mouvement(
          id: '019fa000-0000-7000-8000-000000000002',
          nature: 'remboursement',
          montant: 3000,
          reference: '#418',
        ),
        _mouvement(
          id: '019fa000-0000-7000-8000-000000000003',
          nature: 'frais_encaisses',
          montant: 500,
          reference: '#418',
        ),
        _mouvement(
          id: '019fa000-0000-7000-8000-000000000004',
          nature: 'indemnisation',
          montant: 200,
          reference: '#398',
        ),
        _mouvement(
          id: '019fa000-0000-7000-8000-000000000005',
          nature: 'correction',
          montant: -150,
          reference: '#398',
        ),
        // Sans référence : un règlement d'agence porte sur un SOLDE, pas sur
        // une course. C'est le mouvement que l'historique agrégé perdrait.
        _mouvement(
          id: '019fa000-0000-7000-8000-000000000006',
          nature: 'reglement',
          montant: 4200,
        ),
        _mouvement(
          id: '019fa000-0000-7000-8000-000000000007',
          nature: 'reversement',
          montant: -900,
        ),
      ],
      'indemnisations': const <Object?>[],
      'litiges_en_cours': const <Object?>[],
      'devise': 'XOF',
      'ecart_plafond': false,
    };

ProviderContainer _conteneur(Map<String, Object?> caisse) {
  final transport = TransportFake((requete) {
    if (requete.path.contains('/moi/caisse')) return reponseJson(caisse);
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  return conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
    supplements: [baseOfflineProvider.overrideWithValue(BaseOffline.memoire())],
  );
}

Future<void> _poser(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(1080, 5200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EcranCaisse(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('les six natures d\'écriture se distinguent', (tester) async {
    final container = _conteneur(_caisse());
    addTearDown(container.dispose);
    await _poser(tester, container);

    for (final libelle in [
      'Avance chez le vendeur',
      "Remboursement de l'avance",
      'Frais encaissés',
      'Indemnisation',
      'Correction',
      'Règlement Mefali',
      'Reversement à Mefali',
    ]) {
      expect(
        find.text(libelle),
        findsOneWidget,
        reason: '« $libelle » doit apparaître, et une seule fois',
      );
    }
  });

  testWidgets('le SENS de chaque mouvement est lisible', (tester) async {
    final container = _conteneur(_caisse());
    addTearDown(container.dispose);
    await _poser(tester, container);

    // Trois sorties (avance, correction, reversement), quatre entrées.
    expect(find.byIcon(Symbols.arrow_upward_rounded), findsNWidgets(3));
    expect(find.byIcon(Symbols.arrow_downward_rounded), findsNWidgets(4));
  });

  testWidgets('un règlement SANS course reste visible', (tester) async {
    final container = _conteneur(_caisse());
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(
      find.text('Règlement Mefali'),
      findsOneWidget,
      reason: 'un règlement porte sur un SOLDE : agrégé par course, il '
          'disparaîtrait de l\'écran — et un versement invisible est '
          'exactement ce que la caisse existe pour empêcher',
    );
    expect(
      find.text(formaterMontant(4200, 'XOF')),
      findsOneWidget,
      reason: 'son montant est lisible, formaté comme tous les autres',
    );
  });

  testWidgets('les montants sont formatés, jamais écrits à la main',
      (tester) async {
    final container = _conteneur(_caisse());
    addTearDown(container.dispose);
    await _poser(tester, container);

    // `-3 000 FCFA` avec l'espace FINE insécable : la comparer à une chaîne
    // tapée au clavier passerait à côté du séparateur.
    expect(find.text(formaterMontant(-3000, 'XOF')), findsOneWidget);
    expect(find.text(formaterMontant(500, 'XOF')), findsOneWidget);
  });

  testWidgets('une nature INCONNUE rend son sens, pas un identifiant',
      (tester) async {
    // Serveur plus récent que l'app : une septième nature apparaît. Yao doit
    // toujours pouvoir lire si l'argent est entré ou sorti.
    final caisse = _caisse();
    caisse['mouvements'] = [
      _mouvement(
        id: '019fa000-0000-7000-8000-0000000000ff',
        nature: 'une_nature_de_2030',
        montant: 700,
      ),
    ];
    final container = _conteneur(caisse);
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.text('une_nature_de_2030'), findsNothing);
    expect(find.text('Entrée'), findsWidgets);
  });
}
