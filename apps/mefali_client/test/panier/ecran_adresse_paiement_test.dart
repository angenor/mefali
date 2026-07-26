/// US2 + US3 (CMD-02, CMD-03) — écran adresse et paiement, maquette C3.
///
/// Cadres **3a′** (adresse, repère texte/vocal, cash avec appoint) et **3b**
/// (montant au-dessus du plafond : cash grisé AVEC SA RAISON), puis la
/// confirmation qui remet immédiatement le code et le QR.
///
/// Les deux règles que ces tests tiennent littéralement :
/// - un repère est OBLIGATOIRE, texte **ou** vocal — sans lui le bouton reste
///   désarmé plutôt que d'envoyer une requête vouée au `422` ;
/// - le cash grisé montre POURQUOI : une option morte sans explication fait
///   croire à une panne de l'app.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/panier/ecran_adresse_paiement.dart';
import 'package:mefali_client/panier/etat_confirmation.dart';
import 'package:mefali_client/panier/etat_panier.dart';
import 'package:mefali_core/mefali_core.dart';

import 'ecran_panier_test.dart' show devisJson;

/// Devis dont le cash est REFUSÉ au-dessus du plafond (cadre 3b).
Map<String, Object?> devisCashRefuse() {
  final json = Map<String, Object?>.from(devisJson());
  json['total_unites'] = 28400;
  json['paiement'] = {
    'cash_autorise': false,
    'motif_cle': 'commande.cash.plafond_depasse',
    'plafond_unites': 10000,
  };
  return json;
}

Future<ProviderContainer> monter(
  WidgetTester tester, {
  Map<String, Object?>? devis,
  void Function(Confirmation notifier)? saisie,
  VoidCallback? onConfirmer,
}) async {
  // Écran long : sans une surface haute, le `ListView` ne construit pas le
  // bloc paiement et le test mesurerait l'absence d'un widget qui existe.
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(retry: pasDeRetry);
  addTearDown(container.dispose);
  container.read(panierProvider.notifier)
    ..demarrer(zoneId: 'zone', categorieSlug: 'marche')
    ..poserDevis(DevisPanierVue.depuisJson(devis ?? devisJson()));
  saisie?.call(container.read(confirmationProvider.notifier));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          MefaliCoreLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr')],
        locale: const Locale('fr'),
        home: EcranAdressePaiement(onConfirmer: onConfirmer),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('C3-3a′ — adresse et repère', () {
    testWidgets('sans repère, la confirmation est DÉSARMÉE', (tester) async {
      var confirmations = 0;
      await monter(
        tester,
        saisie: (n) => n.poserPin(5.9050, -4.8300),
        onConfirmer: () => confirmations++,
      );

      // Le libellé porte le total (« Commander · 5 900 FCFA ») : on remonte
      // du texte au bouton plutôt que d'écrire le montant à la main.
      final bouton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.textContaining('Commander'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(
        bouton.onPressed,
        isNull,
        reason: 'mieux vaut un bouton visiblement inerte qu\'un 422 après coup',
      );
      expect(confirmations, 0);
    });

    testWidgets('un repère écrit assez long ARME la confirmation',
        (tester) async {
      var confirmations = 0;
      final container = await monter(
        tester,
        saisie: (n) => n
          ..poserPin(5.9050, -4.8300)
          ..saisirRepere('Près de la pharmacie Sainte-Marie'),
        onConfirmer: () => confirmations++,
      );
      expect(container.read(confirmationProvider).pretAConfirmer, isTrue);
      await tester.pumpAndSettle();
      final bouton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.textContaining('Commander'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(bouton.onPressed, isNotNull);
      await tester.tap(find.textContaining('Commander'));
      await tester.pump();
      expect(confirmations, 1);
    });

    testWidgets('un repère TROP COURT ne suffit pas', (tester) async {
      final container = await monter(
        tester,
        saisie: (n) => n
          ..poserPin(5.9050, -4.8300)
          // 4 caractères < 10 (paramètre de zone).
          ..saisirRepere('cour'),
      );
      expect(container.read(confirmationProvider).pretAConfirmer, isFalse);
      // Le compteur rend la règle visible plutôt que mystérieuse.
      expect(find.text('4 / 10'), findsOneWidget);
    });

    testWidgets('une note VOCALE suffit, sans aucun texte', (tester) async {
      final container = await monter(
        tester,
        saisie: (n) => n
          ..poserPin(5.9050, -4.8300)
          ..poserNoteVocale(
            NoteVocaleCaptee(octets: Uint8List.fromList([1, 2, 3]), dureeS: 12),
          ),
      );
      final etat = container.read(confirmationProvider);
      expect(etat.mode, ModeRepere.vocal);
      expect(etat.repereTexte, isEmpty);
      expect(
        etat.pretAConfirmer,
        isTrue,
        reason: 'texte OU vocal — l\'un des deux suffit (FR-018)',
      );
    });

    testWidgets(
        'une adresse du carnet SANS repère vocal purgé retombe sur le texte',
        (tester) async {
      final container = await monter(
        tester,
        saisie: (n) => n.reutiliser(
          adresseId: 'a1',
          lat: 5.9050,
          lon: -4.8300,
          // Le repère vocal a été purgé (rétention de zone, cycle 003).
        ),
      );
      final etat = container.read(confirmationProvider);
      expect(etat.mode, ModeRepere.texte);
      expect(
        etat.pretAConfirmer,
        isFalse,
        reason: 'un repère purgé est un repère ABSENT : il est redemandé',
      );
    });
  });

  group('C3-3a′ / 3b — paiement', () {
    testWidgets("le cash affiche l'APPOINT EXACT", (tester) async {
      await monter(
        tester,
        saisie: (n) => n
          ..poserPin(5.9050, -4.8300)
          ..saisirRepere('Près de la pharmacie Sainte-Marie'),
      );
      expect(
        find.text("Préparez l'appoint : ${formaterMontant(5900, 'XOF')}"),
        findsOneWidget,
        reason: 'c\'est ce qui évite la scène du gros billet (§7.5-5)',
      );
    });

    testWidgets('au-dessus du plafond, le cash est grisé AVEC SA RAISON',
        (tester) async {
      await monter(
        tester,
        devis: devisCashRefuse(),
        saisie: (n) => n
          ..poserPin(5.9050, -4.8300)
          ..saisirRepere('Près de la pharmacie Sainte-Marie'),
      );

      expect(
        find.text(
          'Espèces indisponibles au-dessus de ${formaterMontant(10000, 'XOF')}.',
        ),
        findsOneWidget,
        reason: 'une option morte sans explication fait croire à une panne',
      );
      final cash = tester.widget<RadioListTile<String>>(
        find.widgetWithText(RadioListTile<String>, 'Espèces à la livraison'),
      );
      expect(cash.enabled, isFalse);
      // L'appoint n'a plus de sens si le cash est refusé.
      expect(find.textContaining("Préparez l'appoint"), findsNothing);
    });
  });

  group('C3 — confirmation', () {
    testWidgets('le code et le QR sont remis IMMÉDIATEMENT', (tester) async {
      await monter(
        tester,
        saisie: (n) => n
          ..poserPin(5.9050, -4.8300)
          ..saisirRepere('Près de la pharmacie Sainte-Marie')
          ..poserCommande(const CommandeCreeeVue(
            id: '01900000-0000-7000-8000-000000000901',
            etat: 'nouvelle',
            totalUnites: 5900,
            devise: 'XOF',
            codeLivraison: '7341',
            jetonReception: 'jeton-de-reception-de-test',
          )),
      );

      expect(find.text('Commande confirmée'), findsOneWidget);
      expect(find.text('À la livraison'), findsOneWidget);
      for (final chiffre in ['7', '3', '4', '1']) {
        expect(find.text(chiffre), findsOneWidget);
      }
      expect(find.text(formaterMontant(5900, 'XOF')), findsOneWidget);
    });
  });
}
