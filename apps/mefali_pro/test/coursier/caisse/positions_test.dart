/// US6 (cycle PAY 011, T075) — la caisse à **trois positions**.
///
/// Ce que le test mesure :
///
/// 1. les trois positions s'affichent **séparément**, chacune avec son chiffre.
///    Un total unique les mélangerait et ne répondrait à aucune des trois
///    questions que Yao se pose ;
/// 2. elles s'affichent **même à zéro** — une position qui disparaîtrait
///    laisserait Yao se demander si Mefali ne lui doit rien ou si l'écran a
///    un bug ;
/// 3. une créance **réglée** se distingue d'une créance **due** : la première
///    est une trace, la seconde une attente ;
/// 4. un solde négatif reste **lisible** — c'est justement le moment où Yao a
///    le plus besoin de lire son écran.
///
/// Aucune planche de paiement n'existe dans `docs/design/png/` : le test porte
/// donc sur le comportement, pas sur une comparaison visuelle (T085 vérifie à
/// l'œil, sur appareil).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/caisse/ecran_caisse.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';

const _commande = '019fa000-0000-7000-8000-00000000000b';

Map<String, Object?> _caisse({
  int avanceNonRecuperee = 0,
  int duParMefali = 0,
  int detenuPourMefali = 0,
  List<Object?> creances = const [],
  int avanceEnCours = 0,
}) =>
    {
      'avance_en_cours_unites': avanceEnCours,
      'courses_concernees': 0,
      'avances_en_attente_reglement_unites': 0,
      'historique_du_jour': const <Object?>[],
      'mouvements': const <Object?>[],
      'indemnisations': const <Object?>[],
      'litiges_en_cours': const <Object?>[],
      'positions': {
        'avance_non_recuperee_unites': avanceNonRecuperee,
        'du_par_mefali_unites': duParMefali,
        'detenu_pour_mefali_unites': detenuPourMefali,
      },
      'creances': creances,
      'devise': 'XOF',
      'ecart_plafond': false,
    };

Map<String, Object?> _creance({
  required String id,
  required String nature,
  required int montant,
  String etat = 'due',
}) =>
    {
      'id': id,
      'commande_id': _commande,
      'nature': nature,
      'montant_unites': montant,
      'devise': 'XOF',
      'etat': etat,
      'cree_le': '2026-08-01T09:55:00Z',
      'regle_le': etat == 'reglee' ? '2026-08-01T18:02:00Z' : null,
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
  // Écran LONG : un `ListView` ne bâtit que ce qui entre dans la fenêtre, et
  // un `find` sur une carte hors écran échouerait sans que rien ne soit cassé.
  tester.view.physicalSize = const Size(1080, 6400);
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
  testWidgets('FR-094 — les trois positions s\'affichent séparément',
      (tester) async {
    final container = _conteneur(_caisse(
      avanceNonRecuperee: 4200,
      duParMefali: 5100,
      detenuPourMefali: 0,
    ));
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.text('Avancé, non récupéré'), findsOneWidget);
    expect(find.text('Mefali me doit'), findsOneWidget);
    expect(find.text('Je détiens pour Mefali'), findsOneWidget);

    // Trois chiffres DISTINCTS : c'est ce qui prouve qu'ils ne sont pas
    // recopiés l'un de l'autre.
    expect(find.text(formaterMontant(4200, 'XOF')), findsWidgets);
    expect(find.text(formaterMontant(5100, 'XOF')), findsOneWidget);
  });

  testWidgets('une position à ZÉRO s\'affiche quand même', (tester) async {
    final container = _conteneur(_caisse());
    addTearDown(container.dispose);
    await _poser(tester, container);

    // Les trois libellés sont là, même quand tout vaut zéro. Une position
    // absente se lirait comme une position oubliée.
    expect(find.text('Avancé, non récupéré'), findsOneWidget);
    expect(find.text('Mefali me doit'), findsOneWidget);
    expect(
      find.text('Je détiens pour Mefali'),
      findsOneWidget,
      reason: 'la marge vaut 0 au MVP, et la position doit exister quand même '
          '— sinon rien ne sera à ajouter le jour où elle cesse d\'être nulle',
    );
    expect(find.text(formaterMontant(0, 'XOF')), findsWidgets);
  });

  testWidgets('une créance réglée se distingue d\'une créance due',
      (tester) async {
    final container = _conteneur(_caisse(
      duParMefali: 4200,
      creances: [
        _creance(
          id: '019fa000-0000-7000-8000-0000000000c1',
          nature: 'avance_prepayee',
          montant: 4200,
        ),
        _creance(
          id: '019fa000-0000-7000-8000-0000000000c2',
          nature: 'part_course',
          montant: 900,
          etat: 'reglee',
        ),
      ],
    ));
    addTearDown(container.dispose);
    await _poser(tester, container);

    expect(find.text('Ce que Mefali me doit'), findsOneWidget);
    expect(find.text('Avance sur commande prépayée'), findsOneWidget);
    expect(find.text('Part de la course'), findsOneWidget);

    // Les deux états, en clair — pas une couleur seule : un écran lu en plein
    // soleil ne distingue pas deux teintes.
    expect(find.text('En attente de règlement'), findsOneWidget);
    expect(find.text('Réglée'), findsOneWidget);
  });

  testWidgets('un solde négatif reste lisible', (tester) async {
    // Le moment où Yao a le plus besoin de son écran : il a avancé de sa poche
    // et rien ne lui est encore revenu.
    final container = _conteneur(_caisse(
      avanceEnCours: 12500,
      avanceNonRecuperee: 12500,
      duParMefali: 12500,
      creances: [
        _creance(
          id: '019fa000-0000-7000-8000-0000000000c3',
          nature: 'avance_prepayee',
          montant: 12500,
        ),
      ],
    ));
    addTearDown(container.dispose);
    await _poser(tester, container);

    // Le montant apparaît en POSITIF avec son libellé : « avancé, non
    // récupéré », plutôt qu'un « −12 500 » qui se lirait comme une dette de
    // Yao envers Mefali. Le sens vient du mot, pas du signe.
    expect(find.text(formaterMontant(12500, 'XOF')), findsWidgets);
    expect(find.text('Avancé, non récupéré'), findsOneWidget);
    expect(find.text('Mefali me doit'), findsOneWidget);
    expect(find.text('Avance sur commande prépayée'), findsOneWidget);
  });
}
