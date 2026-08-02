/// « Mes véhicules » (CPT-04) — la sortie de l'impasse.
///
/// Ce que ces tests tiennent, et contre quelle erreur précise :
///
/// 1. **La flotte envoyée est celle qui est cochée** — le corps est asserté, pas
///    seulement le fait qu'une requête parte. Envoyer autre chose que ce que le
///    coursier a choisi ferait refuser des courses qu'il peut prendre, ou lui en
///    donner qu'il ne peut pas.
/// 2. **Un transport désactivé en zone est MONTRÉ mais jamais renvoyé.** Le
///    serveur refuse tout le corps sur un seul slug hors zone : le renvoyer
///    ferait échouer un enregistrement qui ne le concerne pas.
/// 3. **Une flotte vide ne part pas.** Elle recréerait le blocage que cet écran
///    existe pour lever.
/// 4. **Un refus serveur ne ferme pas l'écran** — le coursier doit pouvoir
///    corriger sans tout recommencer.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/vehicules/ecran_vehicules.dart';
import 'package:mefali_pro/coursier/vehicules/etat_vehicules.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';

/// Corps de `GET /moi/dossier-coursier`, réduit à ce que l'écran lit.
///
/// Tous les champs du modèle GÉNÉRÉ sont là : un seul manquant et la
/// désérialisation échoue à l'exécution, sans qu'aucune assertion ne dise
/// pourquoi (piège payé au cycle PAY 011).
Map<String, Object?> _dossier({
  List<Map<String, Object?>> vehicules = const [
    {
      'type_transport_id': '01900000-0000-7000-8000-000000000301',
      'slug': 'moto',
      'actif_zone': true,
    },
  ],
}) =>
    {
      'compte_id': '01900000-0000-7000-8000-000000000401',
      'piece_mime': 'image/jpeg',
      'referent_nom': 'K. Abou',
      'referent_telephone_e164': '+2250705060708',
      'soumis_le': '2026-07-18T08:00:00Z',
      'statut': 'valide',
      'motif': null,
      'vehicules': vehicules,
    };

Future<ProviderContainer> _monter(
  WidgetTester tester,
  TransportFake transport, {
  List<String> actifs = const ['moto', 'velo'],
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
    // La source des transports est INJECTÉE : le service de config arme un
    // minuteur horaire, et un test widget échoue sur « a Timer is still
    // pending » à la destruction de l'arbre.
    supplements: [
      sourceTransportsActifsProvider.overrideWithValue(() async => actifs),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EcranMesVehicules(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('la flotte déclarée est pré-cochée', (tester) async {
    await _monter(
      tester,
      TransportFake((_) async => reponseJson(_dossier())),
    );

    final moto = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Moto'),
    );
    final velo = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Vélo'),
    );
    expect(moto.selected, isTrue, reason: 'déclarée par le serveur');
    expect(velo.selected, isFalse);
  });

  testWidgets('enregistrer envoie EXACTEMENT les slugs cochés', (tester) async {
    Map<String, Object?>? envoye;
    var cles = <String>[];

    await _monter(
      tester,
      TransportFake((requete) async {
        if (requete.method == 'PUT') {
          cles.add(requete.headers['idempotency-key']! as String);
          envoye = jsonDecode(jsonEncode(requete.data)) as Map<String, Object?>;
          return reponseJson(_dossier());
        }
        return reponseJson(_dossier());
      }),
    );

    // On ajoute le vélo et on retire la moto : les deux sens du geste.
    await tester.tap(find.widgetWithText(FilterChip, 'Vélo'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'Moto'));
    await tester.pump();

    await tester.tap(find.byKey(const Key('vehicules-enregistrer')));
    await tester.pumpAndSettle();

    expect(envoye?['vehicules'], ['velo'],
        reason: 'ce qui part est ce qui est coché — ni plus, ni moins');
    expect(cles.length, 1);
  });

  testWidgets(
    'un transport désactivé en zone est montré, mais jamais renvoyé',
    (tester) async {
      Map<String, Object?>? envoye;
      await _monter(
        tester,
        TransportFake((requete) async {
          if (requete.method == 'PUT') {
            envoye = jsonDecode(jsonEncode(requete.data)) as Map<String, Object?>;
          }
          return reponseJson(
            _dossier(
              vehicules: const [
                {
                  'type_transport_id': '01900000-0000-7000-8000-000000000301',
                  'slug': 'moto',
                  'actif_zone': true,
                },
                // Déclaré autrefois, plus accepté par la zone depuis.
                {
                  'type_transport_id': '01900000-0000-7000-8000-000000000305',
                  'slug': 'voiture',
                  'actif_zone': false,
                },
              ],
            ),
          );
        }),
      );

      // Il est VISIBLE — sinon le coursier ne comprendrait pas pourquoi sa
      // flotte a rétréci — mais il n'est pas cochable.
      final voiture = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Voiture'),
      );
      expect(voiture.onSelected, isNull);
      expect(voiture.selected, isFalse);

      await tester.tap(find.byKey(const Key('vehicules-enregistrer')));
      await tester.pumpAndSettle();

      expect(envoye?['vehicules'], ['moto'],
          reason: 'renvoyer un slug hors zone ferait refuser TOUT le corps');
    },
  );

  testWidgets('sans aucun choix, on n\'enregistre pas', (tester) async {
    var putEnvoye = false;
    await _monter(
      tester,
      TransportFake((requete) async {
        if (requete.method == 'PUT') putEnvoye = true;
        return reponseJson(_dossier());
      }),
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Moto'));
    await tester.pump();

    expect(find.text('Choisissez au moins un véhicule.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vehicules-enregistrer')));
    await tester.pumpAndSettle();

    expect(putEnvoye, isFalse,
        reason: 'une flotte vide recréerait le blocage que cet écran lève');
  });

  testWidgets('un refus serveur s\'affiche et l\'écran RESTE ouvert',
      (tester) async {
    await _monter(
      tester,
      TransportFake((requete) async {
        if (requete.method == 'PUT') {
          return reponseJson(
            {'code': 'corps_invalide', 'message_cle': 'x'},
            statut: 422,
          );
        }
        return reponseJson(_dossier());
      }),
    );

    await tester.tap(find.byKey(const Key('vehicules-enregistrer')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('vehicules-refus')), findsOneWidget);
    expect(find.byType(EcranMesVehicules), findsOneWidget,
        reason: 'le coursier doit pouvoir corriger sans tout recommencer');
  });

  testWidgets('un compte sans dossier le DIT, au lieu d\'un écran vide',
      (tester) async {
    await _monter(
      tester,
      TransportFake(
        (_) async => reponseJson(
          {'code': 'introuvable', 'message_cle': 'x'},
          statut: 404,
        ),
      ),
    );

    expect(
      find.text('Aucun dossier coursier n\'est enregistré pour ce compte.'),
      findsOneWidget,
    );
  });
}
