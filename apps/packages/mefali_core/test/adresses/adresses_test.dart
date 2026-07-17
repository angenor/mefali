import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

const String _idMaison = '01900000-0000-7000-8000-0000000000a1';
const String _idChantier = '01900000-0000-7000-8000-0000000000a2';

/// Fixture = wireNames RÉELS du backend (contrat `Adresse`).
Map<String, Object?> _adresse(
  String id,
  String libelle, {
  bool aRepereVocal = true,
  String? repereTexte = 'Derrière la pharmacie, portail bleu',
  int? dureeS = 12,
}) => {
      'id': id,
      'libelle': libelle,
      'lat': 5.898,
      'lng': -4.823,
      'repere_texte': ?repereTexte,
      'a_repere_vocal': aRepereVocal,
      'repere_vocal_duree_s': ?dureeS,
      'zone_id': '01900000-0000-7000-8000-000000000002',
      'cree_le': '2026-07-14T10:00:00Z',
      'derniere_utilisation_le': '2026-07-14T12:00:00Z',
    };

/// Conteneur monté sur un transport factice, session connectée. On surcharge les
/// DÉPENDANCES (stockage via `jetons`, transport) ; JAMAIS `sessionProvider`.
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

/// Montage des écrans de LISTE (Consumer) — sous la portée du conteneur.
Widget _monterListe(ProviderContainer container, Widget enfant) => harnaisApp(
      container: container,
      localizationsDelegates: MefaliCoreLocalizations.localizationsDelegates,
      supportedLocales: MefaliCoreLocalizations.supportedLocales,
      home: enfant,
    );

/// Montage NU des widgets sans état de liste (FeuilleEnregistrerAdresse ne lit
/// aucun provider — FR-011/FR-009) : MaterialApp simple, aucune portée requise.
Widget _monter(Widget enfant) => MaterialApp(
      theme: MefaliTheme.light,
      localizationsDelegates: MefaliCoreLocalizations.localizationsDelegates,
      supportedLocales: MefaliCoreLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: enfant,
    );

void main() {
  group('ListeAdresses (FR-021)', () {
    testWidgets('liste les adresses avec leur repère', (tester) async {
      final (container, _) = _conteneur((_) => reponseJson([_adresse(_idMaison, 'Maison')]));
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monterListe(container, const ListeAdresses()));
      await tester.pumpAndSettle();

      expect(find.text('Maison'), findsOneWidget);
      expect(find.text('Écouter le repère'), findsOneWidget);
      expect(find.text('Derrière la pharmacie, portail bleu'), findsOneWidget);
      expect(find.text('12 s'), findsOneWidget);
    });

    testWidgets('une adresse au repère PURGÉ reste utilisable et en redemande un (FR-022)',
        (tester) async {
      final (container, _) = _conteneur(
        (_) => reponseJson([
          _adresse(_idChantier, 'Chantier',
              aRepereVocal: false, repereTexte: null, dureeS: null),
        ]),
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monterListe(container, const ListeAdresses()));
      await tester.pumpAndSettle();

      expect(
        find.text('Chantier'),
        findsOneWidget,
        reason: 'FR-022 — la purge du repère n\'emporte PAS l\'adresse',
      );
      expect(
        find.textContaining('Mefali vous en redemandera un'),
        findsOneWidget,
        reason: 'un blanc se lirait comme une perte : on dit ce qui s\'est passé',
      );
      expect(find.text('Écouter le repère'), findsNothing);
    });

    testWidgets('écouter demande une URL présignée FRAÎCHE et joue les octets',
        (tester) async {
      String? joue;
      final (container, transport) = _conteneur((requete) {
        if (requete.path.contains('repere-vocal')) {
          return reponseJson({
            'url': 'http://garage.invalid/comptes/reperes/x?sig=abc',
            'expire_le': '2026-07-15T12:10:00Z',
          });
        }
        return reponseJson([_adresse(_idMaison, 'Maison')]);
      });
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(
        _monterListe(
          container,
          ListeAdresses(jouerNote: (url) async => joue = url),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Écouter le repère'));
      await tester.pumpAndSettle();

      expect(joue, 'http://garage.invalid/comptes/reperes/x?sig=abc');
      expect(
        transport.recues.where((r) => r.path.contains('repere-vocal')).length,
        1,
        reason: 'l\'URL est présignée 10 min : on la redemande à chaque écoute '
            'plutôt que de garder un lien qui périmera',
      );
    });

    testWidgets('supprimer confirme puis appelle DELETE et recharge', (tester) async {
      final (container, transport) = _conteneur(
        (requete) => requete.method == 'DELETE'
            // 204 sans corps — le contrat.
            ? ResponseBody.fromString('', 204)
            : reponseJson([_adresse(_idMaison, 'Maison')]),
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monterListe(container, const ListeAdresses()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer « Maison » ?'), findsOneWidget);
      expect(
        find.text('Vos livraisons passées n\'en sont pas affectées.'),
        findsOneWidget,
        reason: 'FR-021 — le changement ne vaut que pour l\'avenir, et on le dit',
      );

      await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(
        transport.recues.any((r) => r.method == 'DELETE' && r.path.contains(_idMaison)),
        isTrue,
      );
    });

    testWidgets('renommer envoie un PATCH avec le seul libellé', (tester) async {
      final (container, transport) = _conteneur(
        (requete) => requete.method == 'PATCH'
            // Le PATCH rend l'adresse, pas la liste : c'est le contrat.
            ? reponseJson(_adresse(_idMaison, 'Chez maman'))
            : reponseJson([_adresse(_idMaison, 'Maison')]),
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monterListe(container, const ListeAdresses()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Renommer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Chez maman');
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      final patch = transport.recues.firstWhere((r) => r.method == 'PATCH');
      expect(patch.path, contains(_idMaison));
      expect((patch.data as Map)['libelle'], 'Chez maman');
      expect(
        (patch.data as Map).containsKey('repere_texte'),
        isFalse,
        reason: 'un champ ABSENT n\'est pas un champ à null : le repère survit',
      );
    });

    testWidgets('un échec réseau affiche un message, pas un écran blanc', (tester) async {
      final (container, _) = _conteneur((_) => reponseJson({'code': 'x'}, statut: 500));
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monterListe(container, const ListeAdresses()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Impossible de charger vos adresses'), findsOneWidget);
    });

    testWidgets('sans adresse, l\'écran explique quand il s\'en créera', (tester) async {
      final (container, _) = _conteneur((_) => reponseJson(<Object>[]));
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monterListe(container, const ListeAdresses()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Aucune adresse enregistrée'), findsOneWidget);
    });
  });

  group('FeuilleEnregistrerAdresse (FR-019)', () {
    /// Double de la capture : `record` passe par un canal de plateforme qu'un
    /// test widget ne sert pas.
    Future<NoteVocaleCaptee?> capturerFixe() async => NoteVocaleCaptee(
          octets: Uint8List.fromList(utf8.encode('octets-note')),
          dureeS: 9,
        );

    testWidgets('la proposition est refusable sans friction', (tester) async {
      var enregistre = false;
      await tester.pumpWidget(
        _monter(
          Builder(
            builder: (context) => Scaffold(
              body: FeuilleEnregistrerAdresse(
                lat: 5.898,
                lng: -4.823,
                dureeMaxS: 30,
                onEnregistrer: (_) => enregistre = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pas maintenant'), findsOneWidget);
      expect(
        enregistre,
        isFalse,
        reason: 'FR-019 — l\'enregistrement n\'est JAMAIS obligatoire',
      );
    });

    testWidgets('un libellé est requis, une puce suffit', (tester) async {
      AdresseASoumettre? recue;
      await tester.pumpWidget(
        _monter(
          Scaffold(
            body: FeuilleEnregistrerAdresse(
              lat: 5.898,
              lng: -4.823,
              dureeMaxS: 30,
              onEnregistrer: (a) => recue = a,
            ),
          ),
        ),
      );

      final action = find.widgetWithText(FilledButton, 'Garder cette adresse');
      expect(
        tester.widget<FilledButton>(action).onPressed,
        isNull,
        reason: 'sans libellé, rien à garder',
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Maison'));
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(recue?.libelle, 'Maison');
      expect(recue?.lat, 5.898, reason: 'le pin GPS de la livraison est repris tel quel');
      expect(recue?.lng, -4.823);
    });

    testWidgets('un libellé libre désélectionne la puce', (tester) async {
      AdresseASoumettre? recue;
      await tester.pumpWidget(
        _monter(
          Scaffold(
            body: FeuilleEnregistrerAdresse(
              lat: 5.898,
              lng: -4.823,
              onEnregistrer: (a) => recue = a,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Bureau'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Chez tantie');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Garder cette adresse'));
      await tester.pumpAndSettle();

      expect(
        recue?.libelle,
        'Chez tantie',
        reason: 'la puce et le champ libre se contrediraient : le dernier geste gagne',
      );
    });

    testWidgets('le repère saisi et la note vocale remontent ensemble', (tester) async {
      AdresseASoumettre? recue;
      await tester.pumpWidget(
        _monter(
          Scaffold(
            body: FeuilleEnregistrerAdresse(
              lat: 5.898,
              lng: -4.823,
              dureeMaxS: 30,
              capturerNote: capturerFixe,
              onEnregistrer: (a) => recue = a,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Maison'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Portail bleu');
      await tester.tap(find.text('Enregistrer un repère vocal'));
      await tester.pumpAndSettle();

      // La note captée s'annonce, avec sa durée.
      expect(find.textContaining('Repère vocal de 9 s'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Garder cette adresse'));
      await tester.pumpAndSettle();

      expect(recue?.repereTexte, 'Portail bleu');
      expect(recue?.note?.dureeS, 9);
      expect(utf8.decode(recue!.note!.octets), 'octets-note');
    });

    testWidgets('la borne de durée affichée vient de la ZONE, jamais d\'une constante',
        (tester) async {
      await tester.pumpWidget(
        _monter(
          const Scaffold(
            body: FeuilleEnregistrerAdresse(
              lat: 5.898,
              lng: -4.823,
              dureeMaxS: 20,
              onEnregistrer: _ignorer,
            ),
          ),
        ),
      );
      expect(find.text('20 s au maximum'), findsOneWidget);
    });

    testWidgets('sans borne connue, on n\'en invente pas', (tester) async {
      await tester.pumpWidget(
        _monter(
          const Scaffold(
            body: FeuilleEnregistrerAdresse(
              lat: 5.898,
              lng: -4.823,
              onEnregistrer: _ignorer,
            ),
          ),
        ),
      );
      expect(
        find.textContaining('au maximum'),
        findsNothing,
        reason: 'FR-024 — pas de 30 en dur : le serveur tranchera',
      );
    });
  });

  group('ConfigDistante — vues dérivées de /config', () {
    test('les vues dérivées dont les apps dépendent sont lues par clé', () {
      final config = ConfigDistante.depuisJson({
        'zone': '01900000-0000-7000-8000-000000000002',
        'version': 'abc',
        'transports_actifs': ['a_pied', 'moto'],
        'note_vocale_duree_max_s': 30,
        'consentement_artci_version': '2026-07',
      });

      expect(config.transportsActifs, ['a_pied', 'moto']);
      expect(config.noteVocaleDureeMaxS, 30);
      expect(config.consentementArtciVersion, '2026-07');
    });

    test('une config sans ces vues ne fabrique pas de valeurs', () {
      final config = ConfigDistante.depuisJson({
        'zone': '01900000-0000-7000-8000-000000000002',
        'version': 'abc',
      });

      expect(config.transportsActifs, isEmpty);
      expect(
        config.noteVocaleDureeMaxS,
        isNull,
        reason: 'FR-024 — aucune borne inventée côté client',
      );
      expect(
        config.consentementArtciVersion,
        isNull,
        reason: 'FR-006 — pas de version de consentement inventée côté client',
      );
    });
  });
}

void _ignorer(AdresseASoumettre _) {}
