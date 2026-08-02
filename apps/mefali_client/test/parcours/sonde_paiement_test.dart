/// La sonde de règlement du suivi (cycle PAY 011, FR-016/FR-017) — T085.
///
/// Ce test n'existe que parce que la validation sur appareil a trouvé ce
/// qu'aucun autre ne voyait : le suivi lisait la session **une seule fois**.
/// Une commande réglée continuait donc d'afficher « En attente de votre
/// paiement » et son bouton de règlement — une invitation à payer deux fois —
/// et l'annulation par expiration n'apparaissait jamais d'elle-même, puisque
/// rien ne relisait.
///
/// Les deux issues sont couvertes ici, parce qu'elles échouaient toutes les
/// deux pour la même raison : le paiement qui ARRIVE, et le délai qui PASSE.
///
/// Aucun canal de plateforme : suivi injecté par la portée, session servie par
/// un transport bouché, base drift en mémoire.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/commande/etat_suivi.dart';
import 'package:mefali_client/l10n/app_localizations.dart';
import 'package:mefali_client/parcours/pages_commande.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

const _commande = '01900000-0000-7000-8000-000000000901';

/// Corps de `GET /commandes/{id}` — réduit à ce que le suivi lit.
Map<String, Object?> _suiviJson({required String etat}) => {
      'id': _commande,
      'etat': etat,
      'etat_cle': 'suivi.etat.$etat',
      'etat_le': '2026-08-01T10:00:00Z',
      'montant_articles_unites': 18000,
      'total_unites': 18000,
      'devise': 'XOF',
      'progression': {
        'collectes_faites': 0,
        'collectes_total': 1,
        'arret_courant': null,
      },
      'remise': {
        'code_livraison': '2612',
        'jeton_reception': 'jeton-de-reception',
      },
    };

/// Corps de `GET /commandes/{id}/paiement`.
Map<String, Object?> _sessionJson({required String etat}) => {
      'transaction_id': '019f0000-0000-7000-8000-000000000a01',
      'etat': etat,
      'montant_unites': 18000,
      'devise': 'XOF',
      'moyen': etat == 'reglee' ? 'wave' : 'inconnu',
      'acces_paiement': 'https://paiement.invalid/sim/x',
      'expire_le': '2026-08-01T10:15:00Z',
      'restant_s': 873,
    };

/// Un scénario : ce que rendent les deux lectures, avant puis après bascule.
///
/// La bascule est commandée par le NOMBRE de lectures de session, parce que
/// c'est exactement ce que le défaut trouvé sur appareil mettait en cause :
/// il n'y avait jamais de seconde lecture.
class _Scenario {
  _Scenario({required this.etatApres, required this.sessionApres});

  final String etatApres;
  final String sessionApres;

  /// Lectures de `GET …/paiement` observées — le test compte dessus.
  final lectures = <int>[];

  bool get _bascule => lectures.length > 1;

  /// Le suivi servi par la PORTÉE (constitution XII).
  Future<EtatSuivi> suivi(String _) async => EtatSuivi.depuisJson(
        _suiviJson(etat: _bascule ? etatApres : 'en_attente_paiement'),
      );

  /// La session servie par le transport — elle passe par le client généré,
  /// donc par le vrai chemin de désérialisation.
  FutureOr<ResponseBody> repondre(RequestOptions options) {
    lectures.add(1);
    return reponseJson(
      _sessionJson(etat: _bascule ? sessionApres : 'ouverte'),
    );
  }
}

/// Monte `PageSuivi` sur le scénario donné.
Future<void> _monter(WidgetTester tester, _Scenario scenario) async {
  // Écran LONG : le bandeau vit dans un `ListView`, et une surface courte le
  // laisserait non construit — le test mesurerait alors l'absence d'un widget
  // qui existe (piège payé en phases 7→9).
  tester.view.physicalSize = const Size(1080, 6400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final base = BaseOffline.memoire();
  addTearDown(base.close);
  final container = ProviderContainer(
    retry: pasDeRetry,
    overrides: [
      urlApiProvider.overrideWithValue('http://test.invalid'),
      stockageJetonsProvider.overrideWith(
        (ref) => StockageJetonsMemoire(
          const JetonsSession(acces: 'acces', rafraichissement: 'refresh'),
        ),
      ),
      baseOfflineProvider.overrideWithValue(base),
      sourceSuiviProvider.overrideWithValue(scenario.suivi),
    ],
  );
  addTearDown(container.dispose);
  container.read(clientSessionProvider).dio.httpClientAdapter =
      TransportFake(scenario.repondre);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          MefaliCoreLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const PageSuivi(commandeId: _commande),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un paiement confirmé efface l\'invitation à payer (FR-016)',
      (tester) async {
    final scenario =
        _Scenario(etatApres: 'en_attente_coursier', sessionApres: 'reglee');
    await _monter(tester, scenario);

    // À l'ouverture : la commande attend, l'écran le dit et propose de payer.
    expect(find.text('En attente de votre paiement'), findsOneWidget);
    expect(find.text('Reprendre le paiement'), findsOneWidget);
    expect(scenario.lectures.length, 1, reason: 'une lecture à l\'ouverture');

    // Le règlement arrive pendant que la cliente regarde l'écran. Sans sonde,
    // rien n'apprendrait jamais qu'il est arrivé.
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(find.text('Paiement confirmé'), findsOneWidget);
    expect(find.text('Reprendre le paiement'), findsNothing,
        reason: 'proposer de payer une commande réglée invite au double débit');
    expect(find.textContaining('Temps restant'), findsNothing,
        reason: 'un compte à rebours sous un paiement confirmé inquiète pour '
            'rien (FR-017)');
  });

  testWidgets('une session expirée apparaît D\'ELLE-MÊME (FR-017)',
      (tester) async {
    final scenario =
        _Scenario(etatApres: 'annulee', sessionApres: 'expiree');
    await _monter(tester, scenario);

    expect(find.text('En attente de votre paiement'), findsOneWidget);

    // Personne ne touche à l'écran : c'est tout l'objet du geste 3 du
    // quickstart — l'annulation apparaît sans qu'on ait à ressortir.
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(find.text('Reprendre le paiement'), findsNothing);
    expect(find.textContaining('Temps restant'), findsNothing);
  });

  testWidgets('la sonde s\'arrête quand la session ne bouge plus',
      (tester) async {
    final scenario =
        _Scenario(etatApres: 'en_attente_coursier', sessionApres: 'reglee');
    await _monter(tester, scenario);

    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();
    final apresReglement = scenario.lectures.length;

    // Trois périodes de plus : une sonde qui continuerait de tourner sur une
    // session close dépenserait de la data pour une réponse qui ne changera
    // plus — et laisserait un Timer derrière elle.
    await tester.pump(const Duration(seconds: 33));
    await tester.pumpAndSettle();

    expect(scenario.lectures.length, apresReglement,
        reason: 'plus aucune lecture après le règlement');
  });
}
