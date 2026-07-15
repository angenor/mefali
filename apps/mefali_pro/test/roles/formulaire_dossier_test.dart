import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/roles/ecran_etat_demande.dart';
import 'package:mefali_pro/roles/etat_roles.dart';
import 'package:mefali_pro/roles/formulaire_dossier.dart';

/// Adaptateur dio qui répond des réponses PRÉ-ÉCRITES, sans réseau.
class _Transport implements HttpClientAdapter {
  _Transport(this.repondre);

  final ResponseBody Function(RequestOptions requete) repondre;
  final List<RequestOptions> recues = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    recues.add(options);
    return repondre(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object corps, {int statut = 200}) => ResponseBody.fromString(
      jsonEncode(corps),
      statut,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, Object?> _dossier() => {
      'statut': 'en_attente',
      'referent_nom': 'K. Abou',
      'referent_telephone_e164': '+2250705060708',
      'vehicules': <Object>[],
      'soumis_le': '2026-07-15T10:00:00Z',
    };

(SessionAuth, _Transport) _session(ResponseBody Function(RequestOptions) repondre) {
  final transport = _Transport(repondre);
  final client = MefaliApiClient(basePathOverride: 'http://test.invalid');
  client.dio.httpClientAdapter = transport;
  final session = SessionAuth(
    stockage: StockageJetonsMemoire(
      const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    ),
    client: client,
  );
  return (session, transport);
}

Widget _monter(Widget enfant) => MaterialApp(
      theme: MefaliTheme.light,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: enfant,
    );

/// Double du sélecteur de pièce : `image_picker` passe par un canal de
/// plateforme qu'un test widget ne sert pas. On double la FONCTION.
ChoisirPiece _pieceFixe({bool annule = false}) => (source) async => annule
    ? null
    : PieceChoisie(
        octets: Uint8List.fromList(utf8.encode('octets-piece')),
        nom: 'cni.jpg',
        mime: 'image/jpeg',
      );

Future<void> _remplirReferent(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextField, 'Nom du référent'), 'K. Abou');
  await tester.enterText(
    find.widgetWithText(TextField, 'Téléphone du référent'),
    '0705060708',
  );
  await tester.pump();
}

void main() {
  group('FormulaireDossierCoursier (FR-015)', () {
    testWidgets('un dossier incomplet ne peut pas être envoyé', (tester) async {
      final (session, transport) = _session((_) => _json(_dossier(), statut: 201));

      await tester.pumpWidget(
        _monter(
          FormulaireDossierCoursier(
            session: session,
            transportsActifs: const ['a_pied', 'velo', 'moto'],
            choisirPiece: _pieceFixe(),
          ),
        ),
      );

      final envoyer = find.widgetWithText(FilledButton, 'Envoyer mon dossier');
      expect(
        tester.widget<FilledButton>(envoyer).onPressed,
        isNull,
        reason: 'FR-015 scénario 1 — dossier vide : rien à envoyer',
      );

      // Pièce seule : toujours incomplet.
      await tester.tap(find.text('Photographier'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(envoyer).onPressed, isNull);

      // + véhicule : toujours incomplet (référent manquant).
      await tester.tap(find.widgetWithText(FilterChip, 'Moto'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(envoyer).onPressed, isNull);

      // + référent : complet.
      await _remplirReferent(tester);
      expect(
        tester.widget<FilledButton>(envoyer).onPressed,
        isNotNull,
        reason: 'pièce + véhicule + référent = dossier complet',
      );

      expect(
        transport.recues,
        isEmpty,
        reason: 'aucun aller-retour réseau tant que le dossier est incomplet',
      );
    });

    testWidgets('un dossier complet part en multipart, avec sa clé d\'idempotence',
        (tester) async {
      final (session, transport) = _session((_) => _json(_dossier(), statut: 201));

      await tester.pumpWidget(
        _monter(
          FormulaireDossierCoursier(
            session: session,
            transportsActifs: const ['a_pied', 'velo', 'moto'],
            choisirPiece: _pieceFixe(),
          ),
        ),
      );

      await tester.tap(find.text('Photographier'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Moto'));
      await tester.pumpAndSettle();
      await _remplirReferent(tester);

      await tester.tap(find.text('Envoyer mon dossier'));
      await tester.pumpAndSettle();

      expect(transport.recues.length, 1);
      final requete = transport.recues.single;
      expect(requete.method, 'POST');
      expect(requete.path, '/moi/dossier-coursier');
      expect(
        requete.headers['Idempotency-Key'],
        isNotNull,
        reason: 'R14 — l\'en-tête est REQUIS côté serveur',
      );
      expect(
        requete.data,
        isA<FormData>(),
        reason: 'la pièce voyage en multipart, via le client GÉNÉRÉ',
      );
      final formulaire = requete.data as FormData;
      expect(formulaire.files.map((f) => f.key), contains('piece'));
      expect(
        formulaire.fields.where((f) => f.key == 'vehicules').map((f) => f.value),
        ['moto'],
        reason: 'le slug part tel quel — c\'est le référentiel de la zone',
      );
      expect(
        formulaire.fields.firstWhere((f) => f.key == 'referent_telephone').value,
        '0705060708',
        reason: 'la saisie locale part BRUTE : la normalisation E.164 est au serveur',
      );
    });

    testWidgets('la clé d\'idempotence ne change pas d\'un essai à l\'autre (R14)',
        (tester) async {
      var appels = 0;
      final (session, transport) = _session((_) {
        appels++;
        // Premier envoi : le réseau lâche APRÈS que le serveur a reçu.
        if (appels == 1) return _json({'code': 'x', 'message_cle': 'y'}, statut: 500);
        return _json(_dossier(), statut: 200);
      });

      await tester.pumpWidget(
        _monter(
          FormulaireDossierCoursier(
            session: session,
            transportsActifs: const ['moto'],
            choisirPiece: _pieceFixe(),
          ),
        ),
      );
      await tester.tap(find.text('Photographier'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Moto'));
      await tester.pumpAndSettle();
      await _remplirReferent(tester);

      await tester.tap(find.text('Envoyer mon dossier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Envoyer mon dossier'));
      await tester.pumpAndSettle();

      expect(transport.recues.length, 2);
      expect(
        transport.recues[0].headers['Idempotency-Key'],
        transport.recues[1].headers['Idempotency-Key'],
        reason: 'R14 — c\'est TOUT l\'intérêt : le renvoi rejoue la même clé, '
            'donc le serveur rend l\'état courant au lieu d\'un doublon',
      );
    });

    testWidgets('un 422 du serveur s\'affiche sans perdre la saisie', (tester) async {
      final (session, _) = _session(
        (_) => _json(
          {'code': 'corps_invalide', 'message_cle': 'comptes.erreur.corps_invalide'},
          statut: 422,
        ),
      );

      await tester.pumpWidget(
        _monter(
          FormulaireDossierCoursier(
            session: session,
            transportsActifs: const ['moto'],
            choisirPiece: _pieceFixe(),
          ),
        ),
      );
      await tester.tap(find.text('Photographier'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Moto'));
      await tester.pumpAndSettle();
      await _remplirReferent(tester);

      await tester.tap(find.text('Envoyer mon dossier'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Mefali n\'a pas accepté ce dossier'),
        findsOneWidget,
        reason: 'le refus du serveur est DIT, pas avalé',
      );
      expect(
        find.text('K. Abou'),
        findsOneWidget,
        reason: 'la saisie survit à l\'erreur — la retaper serait une punition',
      );
    });

    testWidgets('sans config de zone, le formulaire le dit au lieu d\'un cul-de-sac',
        (tester) async {
      final (session, _) = _session((_) => _json(_dossier(), statut: 201));

      await tester.pumpWidget(
        _monter(
          FormulaireDossierCoursier(
            session: session,
            transportsActifs: const [],
            choisirPiece: _pieceFixe(),
          ),
        ),
      );

      expect(find.textContaining('Impossible de charger les véhicules'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('seuls les véhicules ACTIFS de la zone sont proposés (scénario 6)',
        (tester) async {
      final (session, _) = _session((_) => _json(_dossier(), statut: 201));

      await tester.pumpWidget(
        _monter(
          FormulaireDossierCoursier(
            session: session,
            transportsActifs: const ['a_pied', 'velo', 'moto'],
            choisirPiece: _pieceFixe(),
          ),
        ),
      );

      expect(find.widgetWithText(FilterChip, 'À pied'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Vélo'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Moto'), findsOneWidget);
      expect(
        find.widgetWithText(FilterChip, 'Camion'),
        findsNothing,
        reason: 'le camion existe au référentiel mais n\'est pas actif à Tiassalé',
      );
    });

    testWidgets('annuler la prise de photo ne casse rien', (tester) async {
      final (session, _) = _session((_) => _json(_dossier(), statut: 201));

      await tester.pumpWidget(
        _monter(
          FormulaireDossierCoursier(
            session: session,
            transportsActifs: const ['moto'],
            choisirPiece: _pieceFixe(annule: true),
          ),
        ),
      );

      await tester.tap(find.text('Photographier'));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Envoyer mon dossier'))
            .onPressed,
        isNull,
      );
    });
  });

  group('EcranEtatDemande — porte vers le dossier (T019)', () {
    testWidgets('sans rôle, l\'action principale est de constituer le dossier',
        (tester) async {
      final (session, _) = _session(
        (_) => _json({
          'id': '01900000-0000-7000-8000-000000000401',
          'telephone_e164': '+2250701020304',
          'zone_id': '01900000-0000-7000-8000-000000000002',
          'roles': [
            {'role': 'client', 'statut': 'valide'},
          ],
          'cree_le': '2026-07-14T10:00:00Z',
        }),
      );
      final etat = EtatRoles(session: session);
      addTearDown(etat.dispose);
      // `charger()` fait un vrai appel dio : `testWidgets` fait tourner une
      // horloge SIMULÉE, et l'attendre directement le suspendrait pour
      // toujours. `runAsync` le rend à l'horloge réelle.
      await tester.runAsync(() async {
        await session.charger();
        await etat.charger();
      });

      await tester.pumpWidget(_monter(EcranEtatDemande(etat: etat)));
      await tester.pumpAndSettle();

      expect(find.text('Constituer mon dossier'), findsOneWidget);
    });

    testWidgets('après un refus, l\'action devient « corriger et renvoyer »', (tester) async {
      final (session, _) = _session(
        (_) => _json({
          'id': '01900000-0000-7000-8000-000000000401',
          'telephone_e164': '+2250701020304',
          'zone_id': '01900000-0000-7000-8000-000000000002',
          'roles': [
            {'role': 'client', 'statut': 'valide'},
            {'role': 'coursier', 'statut': 'refuse', 'motif': 'Pièce illisible'},
          ],
          'cree_le': '2026-07-14T10:00:00Z',
        }),
      );
      final etat = EtatRoles(session: session);
      addTearDown(etat.dispose);
      // `charger()` fait un vrai appel dio : `testWidgets` fait tourner une
      // horloge SIMULÉE, et l'attendre directement le suspendrait pour
      // toujours. `runAsync` le rend à l'horloge réelle.
      await tester.runAsync(() async {
        await session.charger();
        await etat.charger();
      });

      await tester.pumpWidget(_monter(EcranEtatDemande(etat: etat)));
      await tester.pumpAndSettle();

      expect(find.text('Corriger et renvoyer mon dossier'), findsOneWidget);
      expect(
        find.text('Pièce illisible'),
        findsOneWidget,
        reason: 'on ne redemande pas un dossier sans dire ce qui clochait',
      );
    });

    testWidgets('en attente, on ne re-soumet pas — on actualise', (tester) async {
      final (session, _) = _session(
        (_) => _json({
          'id': '01900000-0000-7000-8000-000000000401',
          'telephone_e164': '+2250701020304',
          'zone_id': '01900000-0000-7000-8000-000000000002',
          'roles': [
            {'role': 'client', 'statut': 'valide'},
            {'role': 'coursier', 'statut': 'en_attente'},
          ],
          'cree_le': '2026-07-14T10:00:00Z',
        }),
      );
      final etat = EtatRoles(session: session);
      addTearDown(etat.dispose);
      // `charger()` fait un vrai appel dio : `testWidgets` fait tourner une
      // horloge SIMULÉE, et l'attendre directement le suspendrait pour
      // toujours. `runAsync` le rend à l'horloge réelle.
      await tester.runAsync(() async {
        await session.charger();
        await etat.charger();
      });

      await tester.pumpWidget(_monter(EcranEtatDemande(etat: etat)));
      await tester.pumpAndSettle();

      expect(find.text('Actualiser'), findsOneWidget);
      expect(
        find.text('Constituer mon dossier'),
        findsNothing,
        reason: 'un dossier déjà en attente n\'est pas à refaire (FR-015)',
      );
    });
  });
}
