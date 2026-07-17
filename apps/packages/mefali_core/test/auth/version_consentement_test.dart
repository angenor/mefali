import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

/// FR-006/FR-024 — la version du texte ARTCI que l'app RENVOIE doit être celle
/// que la ZONE sert, jamais une constante de code.
///
/// Le piège que ces tests ferment : une constante « de repli » qui devient le
/// seul chemin réel rend le paramètre de zone INERTE — l'admin éditerait la
/// version sans aucun effet, et le consentement serait horodaté sur un texte
/// que personne n'a plus.

Map<String, Object?> _sessionOuverte() => {
      'resultat': 'session',
      'jetons': {'acces': 'jwt', 'rafraichissement': 'r'},
      'compte': {
        'id': '01900000-0000-7000-8000-000000000401',
        'telephone_e164': '+2250701020304',
        'zone_id': '01900000-0000-7000-8000-000000000002',
        'roles': <Object>[],
        'cree_le': '2026-07-15T10:00:00Z',
      },
    };

(ProviderContainer, TransportFake) _conteneur() {
  final transport = TransportFake((requete) {
    if (requete.path.contains('/auth/otp/demander')) {
      return reponseJson({'message_cle': 'comptes.otp.envoye_si_valide'},
          statut: 202);
    }
    if (requete.path.contains('/auth/otp/verifier')) {
      return reponseJson(
          {'resultat': 'consentement_requis', 'jeton_inscription': 'jet0n'});
    }
    return reponseJson(_sessionOuverte(), statut: 201);
  });
  final container = conteneurMefali(transport: transport);
  return (container, transport);
}

Widget _monter(ProviderContainer container, Widget enfant) => harnaisApp(
      container: container,
      localizationsDelegates: MefaliCoreLocalizations.localizationsDelegates,
      supportedLocales: MefaliCoreLocalizations.supportedLocales,
      home: enfant,
    );

/// Mène le parcours jusqu'à l'écran de consentement, case cochée.
///
/// (L'écran OTP n'a qu'UN `TextField` — les 6 « cases » sont un décor peint
/// par-dessus, pas six champs.)
Future<void> _allerJusquAuConsentement(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), '0701020304');
  await tester.tap(find.text('Recevoir le code'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField), '123456');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Valider'));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(Checkbox));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la version envoyée est celle de la ZONE, pas une constante',
      (tester) async {
    final (container, transport) = _conteneur();
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).charger();

    await tester.pumpWidget(
      _monter(
        container,
        ParcoursAuth(
          onConnecte: () {},
          // Une zone qui a fait évoluer son texte : c'est CETTE version qui
          // doit partir, et elle ne ressemble à aucun défaut de code.
          versionConsentement: '2027-03',
        ),
      ),
    );

    await _allerJusquAuConsentement(tester);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    final inscription = transport.recues.firstWhere(
      (r) => r.path.contains('/auth/inscription'),
    );
    expect(
      (inscription.data as Map)['consentement_version'],
      '2027-03',
      reason: 'FR-024 — la version vient de la config de zone ; une constante '
          'en dur ici rendrait le paramètre INERTE',
    );
  });

  testWidgets('sans version connue, l\'inscription est refusée au lieu d\'inventer',
      (tester) async {
    final (container, transport) = _conteneur();
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).charger();

    await tester.pumpWidget(
      _monter(
        container,
        ParcoursAuth(
          onConnecte: () {},
          // Config jamais chargée.
          versionConsentement: null,
        ),
      ),
    );

    await _allerJusquAuConsentement(tester);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(
      transport.recues.any((r) => r.path.contains('/auth/inscription')),
      isFalse,
      reason: 'FR-006 — on n\'horodate pas un consentement sur une version que '
          'l\'on ne connaît pas : mieux vaut un refus qu\'un faux consentement',
    );
    expect(container.read(sessionProvider).connecte, isFalse);
  });
}
