/// VND-08 minimal (cycle PAY 011, T062) — le vendeur déclare qu'il offre la
/// livraison.
///
/// Ce que le test mesure :
/// - l'état courant est LISIBLE sur l'écran boutique, sans ouvrir la feuille ;
/// - le seuil est obligatoire en mode « à partir d'un montant », et le refus
///   est dit AVANT l'aller-retour — faire attendre le vendeur pour une saisie
///   qu'on sait invalide serait gratuit ;
/// - le corps envoyé est celui du contrat ;
/// - le rappel FR-048 (« les commandes déjà passées ne changent pas de prix »)
///   est affiché AVANT la validation, pas après un appel client.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/vendeur/boutique/ecran_boutique.dart';

const _prestataire = '01900000-0000-7000-8000-000000000502';

Map<String, Object?> _pilotable({
  String offre = 'jamais',
  int? seuil,
}) =>
    {
      'id': _prestataire,
      'nom': 'Étal Tantie Affoué',
      'statut': 'agree',
      'boutique': {'ouvert': true, 'reouverture_estimee': null},
      'offre_livraison': offre,
      'offre_livraison_seuil_unites': seuil,
    };

Map<String, Object?> _boutique() => {
      'statut': 'ouvert',
      'pause_fin': null,
      'etat_effectif': {'ouvert': true, 'reouverture_estimee': null},
      'horaires': {
        'jours': [
          for (var j = 0; j < 6; j++)
            [
              {'debut': '08:00', 'fin': '19:00'},
            ],
          <Map<String, String>>[],
        ],
      },
      'horaires_du_jour': [
        {'debut': '08:00', 'fin': '19:00'},
      ],
      'rappel_ouverture': false,
    };

(ProviderContainer, List<RequestOptionsFake>) _conteneur({
  String offre = 'jamais',
  int? seuil,
}) {
  final envois = <RequestOptionsFake>[];
  final transport = TransportFake((requete) {
    if (requete.method == 'PUT' && requete.path.endsWith('/offre-livraison')) {
      envois.add(RequestOptionsFake(requete.path, requete.data));
      return reponseJson({
        'offre': 'toujours',
        'seuil_unites': null,
        'message_cle': 'vendeur.offre_livraison.commandes_en_cours_inchangees',
      });
    }
    if (requete.path.endsWith('/vendeur/prestataires')) {
      return reponseJson([_pilotable(offre: offre, seuil: seuil)]);
    }
    if (requete.path.endsWith('/boutique') ||
        requete.path.endsWith('/boutique/action')) {
      return reponseJson(_boutique());
    }
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  return (
    conteneurMefali(
      jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
      transport: transport,
    ),
    envois,
  );
}

/// Ce qu'une requête a réellement envoyé — le corps compte autant que la route.
class RequestOptionsFake {
  RequestOptionsFake(this.path, this.data);

  final String path;
  final Object? data;
}

Widget _monter(ProviderContainer container) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EcranBoutique(),
    );

/// Écran assez haut pour que toute la liste V1 soit construite.
void _ecranHaut(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets("l'état courant se lit sans ouvrir la feuille", (tester) async {
    _ecranHaut(tester);
    final (container, _) = _conteneur(offre: 'au_dela', seuil: 5000);
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pumpAndSettle();

    expect(find.text('Offrir la livraison'), findsOneWidget);
    expect(
      find.text('À partir d\'un montant (${formaterMontant(5000, 'XOF')})'),
      findsOneWidget,
      reason: 'le seuil doit être visible : « à partir d\'un montant » seul '
          'ne dit pas lequel',
    );
  });

  testWidgets('FR-046 : « à partir d\'un montant » sans seuil est refusé AVANT '
      "l'aller-retour", (tester) async {
    _ecranHaut(tester);
    final (container, envois) = _conteneur();
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    // Le rappel FR-048 est là dès l'ouverture, avant toute validation.
    expect(
      find.text('Les commandes déjà passées ne changent pas de prix.'),
      findsOneWidget,
    );

    await tester.tap(find.text('À partir d\'un montant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Indiquez un montant minimum supérieur à zéro.'),
      findsOneWidget,
    );
    expect(envois, isEmpty,
        reason: 'une saisie qu\'on sait invalide ne doit pas voyager');
  });

  testWidgets('le corps envoyé est celui du contrat', (tester) async {
    _ecranHaut(tester);
    final (container, envois) = _conteneur();
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sur toutes les commandes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(envois, hasLength(1));
    final corps = Map<String, Object?>.from(envois.single.data! as Map);
    expect(corps['offre'], 'toujours');
    expect(corps['seuil_unites'], isNull,
        reason: 'un seuil n\'a de sens que pour « à partir d\'un montant »');
  });
}
