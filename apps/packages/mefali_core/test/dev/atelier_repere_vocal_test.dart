import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

const String _idAdresse = '01900000-0000-7000-8000-0000000000b1';

/// Fixture = wireNames RÉELS du contrat `Adresse` (comme adresses_test).
Map<String, Object?> _adresse({bool aRepereVocal = true, int? dureeS = 9}) => {
  'id': _idAdresse,
  'libelle': 'Maison',
  'lat': 5.898,
  'lng': -4.823,
  'repere_texte': 'Portail bleu',
  'a_repere_vocal': aRepereVocal,
  'repere_vocal_duree_s': ?dureeS,
  'zone_id': '01900000-0000-7000-8000-000000000002',
  'cree_le': '2026-07-18T10:00:00Z',
  'derniere_utilisation_le': '2026-07-18T10:00:00Z',
};

(ProviderContainer, TransportFake) _conteneur(
  ResponseBody Function(RequestOptions requete) repondre,
) {
  final transport = TransportFake(repondre);
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
  );
  return (container, transport);
}

Widget _monter(ProviderContainer container, Widget enfant) => harnaisApp(
  container: container,
  localizationsDelegates: MefaliCoreLocalizations.localizationsDelegates,
  supportedLocales: MefaliCoreLocalizations.supportedLocales,
  home: enfant,
);

/// Démonte l'arbre PUIS dispose le conteneur, DANS le corps du test.
///
/// `AtelierRepereVocal` lit `serviceConfigProvider` (borne de zone), dont
/// `ServiceConfig` porte un Timer horaire `keepAlive`. `addTearDown(container.dispose)`
/// s'exécute APRÈS le contrôle « Timer still pending » de flutter_test — trop
/// tard. On démonte (plus personne ne lit le conteneur) puis on dispose ici :
/// `serviceConfig.onDispose` annule le Timer SYNCHRONEMENT (cf. session_auth_test).
Future<void> _fin(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
}

/// Double de la capture : `record` passe par un canal de plateforme.
Future<NoteVocaleCaptee?> _capturerFixe() async => NoteVocaleCaptee(
  octets: Uint8List.fromList(utf8.encode('m4a-octets')),
  dureeS: 9,
);

/// Déroule la feuille jusqu'à une capture avec note, dans l'atelier déjà monté.
Future<void> _capter(WidgetTester tester) async {
  await tester.tap(find.text('Ouvrir la feuille d\'enregistrement'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, 'Maison'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Enregistrer un repère vocal'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Garder cette adresse'));
  await tester.pumpAndSettle();
}

void main() {
  group('AtelierRepereVocal (DEV)', () {
    testWidgets('capture → envoie pour de vrai → réécoute serveur → nettoie', (
      tester,
    ) async {
      String? urlServeur;
      final (container, transport) = _conteneur((requete) {
        if (requete.method == 'POST' && requete.path == '/moi/adresses') {
          return reponseJson(_adresse(), statut: 201);
        }
        if (requete.path.contains('repere-vocal')) {
          return reponseJson({
            'url': 'http://garage.invalid/comptes/reperes/x?sig=abc',
            'expire_le': '2026-07-18T10:10:00Z',
          });
        }
        if (requete.method == 'DELETE') {
          return ResponseBody.fromString('', 204);
        }
        return reponseJson(<Object>[]);
      });
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(
        _monter(
          container,
          AtelierRepereVocal(
            capturerNote: _capturerFixe,
            jouerLocal: (_) async {},
            jouerReseau: (url) async => urlServeur = url,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _capter(tester);

      // La capture s'affiche, avec la taille des octets et un lecteur LOCAL.
      expect(find.text('Repère capté'), findsOneWidget);
      expect(find.textContaining('octets captés'), findsOneWidget);
      expect(
        find.text('Écouter le repère'),
        findsOneWidget,
        reason: 'réécoute LOCALE avant envoi',
      );

      // Envoi RÉEL.
      await tester.tap(
        find.widgetWithText(FilledButton, 'Envoyer (POST /moi/adresses)'),
      );
      // Deux temps : `pumpAndSettle` dispatche l'appel réseau (futur résolu sur
      // microtâche), un `pump` de plus reconstruit sur l'état posé au retour.
      await tester.pumpAndSettle();
      await tester.pump();

      // Le POST est parti avec sa clé d'idempotence (R14) et un corps multipart.
      final post = transport.recues.firstWhere(
        (r) => r.method == 'POST' && r.path == '/moi/adresses',
      );
      final cle = post.headers.entries
          .firstWhere((e) => e.key.toLowerCase() == 'idempotency-key')
          .value;
      expect(
        cle,
        isNotNull,
        reason: 'R14 — la clé DEVIENT l\'id de l\'adresse',
      );
      expect(
        post.data,
        isA<FormData>(),
        reason: 'la note part en multipart, jamais en JSON',
      );
      expect(
        (post.data as FormData).files.map((f) => f.key),
        contains('note_vocale'),
        reason: 'les octets captés sont bien joints',
      );

      // L'adresse enregistrée s'affiche, avec l'id rendu par le serveur.
      expect(find.textContaining(_idAdresse), findsOneWidget);

      // Réécoute SERVEUR : URL présignée fraîche (SC-007). Le second lecteur
      // (celui de la carte « envoyée ») est en bas — on l'amène à l'écran.
      await tester.ensureVisible(find.text('Écouter le repère').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Écouter le repère').last);
      await tester.pumpAndSettle();
      await tester.pump();
      expect(urlServeur, 'http://garage.invalid/comptes/reperes/x?sig=abc');
      expect(
        transport.recues.where((r) => r.path.contains('repere-vocal')).length,
        1,
      );

      // Nettoyage : DELETE de l'adresse de test.
      await tester.ensureVisible(find.text('Supprimer l\'adresse de test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer l\'adresse de test'));
      await tester.pumpAndSettle();
      await tester.pump();
      expect(
        transport.recues.any(
          (r) => r.method == 'DELETE' && r.path.contains(_idAdresse),
        ),
        isTrue,
      );
      expect(find.textContaining(_idAdresse), findsNothing);

      await _fin(tester, container);
    });

    testWidgets(
      'un envoi refusé affiche le diagnostic HTTP, pas un écran blanc',
      (tester) async {
        final (container, _) = _conteneur((requete) {
          if (requete.method == 'POST' && requete.path == '/moi/adresses') {
            return reponseJson({'code': 'corps_invalide'}, statut: 422);
          }
          return reponseJson(<Object>[]);
        });
        await container.read(sessionProvider.notifier).charger();

        await tester.pumpWidget(
          _monter(
            container,
            AtelierRepereVocal(
              capturerNote: _capturerFixe,
              jouerLocal: (_) async {},
              jouerReseau: (_) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _capter(tester);
        await tester.tap(
          find.widgetWithText(FilledButton, 'Envoyer (POST /moi/adresses)'),
        );
        await tester.pumpAndSettle();
        await tester.pump();

        expect(find.textContaining('Échec de l\'envoi'), findsOneWidget);
        expect(find.textContaining('HTTP 422'), findsOneWidget);

        await _fin(tester, container);
      },
    );
  });
}
