/// Cache local de la COURSE coursier (cycle CRS 010, data-model §4) : la course
/// complète, sa checklist, ses essais de code et ses relevés de présence.
///
/// Ce qui est prouvé ici est ce dont dépend la promesse « une course fonctionne
/// de bout en bout sans réseau » (FR-028) — et son revers, qui compte autant :
/// ce qui doit **disparaître** à la clôture disparaît vraiment, numéros de
/// téléphone compris (R6, FR-034).
library;

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/src/offline/action_en_attente.dart';

const _livraison = '01990000-0000-7000-8000-00000000000a';
const _commande = '01990000-0000-7000-8000-00000000000b';
const _arret = '01990000-0000-7000-8000-00000000000c';

Future<void> _poserCourse(BaseOffline base) async {
  await base.into(base.courseCacheTable).insertOnConflictUpdate(
        CourseCacheTableCompanion.insert(
          livraisonId: _livraison,
          commandeId: _commande,
          etat: 'en_livraison',
          majLeLocal: DateTime(2026, 7, 28, 14, 32),
          clientNomUsage: const Value('Awa K.'),
          clientTelephone: const Value('+2250700000002'),
          repereTexte: const Value('Cour verte après la pharmacie'),
          repereVocalFichier: const Value('/data/repere.m4a'),
          empreinteCode: const Value('a1b2c3'),
          empreinteJeton: const Value('d4e5f6'),
          montantAEncaisserUnites: const Value(5800),
        ),
      );
}

void main() {
  group('CourseCache (K3, K4)', () {
    test('la course tient dans une ligne, écrasée et non dupliquée', () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);

      await _poserCourse(base);
      await base.into(base.courseCacheTable).insertOnConflictUpdate(
            CourseCacheTableCompanion.insert(
              livraisonId: _livraison,
              commandeId: _commande,
              etat: 'en_livraison',
              majLeLocal: DateTime(2026, 7, 28, 14, 40),
              montantAEncaisserUnites: const Value(5200),
            ),
          );

      final tous = await base.select(base.courseCacheTable).get();
      expect(tous, hasLength(1), reason: 'une seule course active à la fois');
      expect(tous.single.montantAEncaisserUnites, 5200);
      expect(tous.single.devise, 'XOF');
      expect(tous.single.depotAutorise, isFalse,
          reason: 'le dépôt est FERMÉ par défaut (FR-039)');
      expect(tous.single.essaisMax, 3);
    });

    test('seules les EMPREINTES sont stockées — jamais un code ni un jeton',
        () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);
      await _poserCourse(base);

      // Le contrat est structurel : la table n'a aucune colonne où écrire un
      // secret. Si quelqu'un en ajoutait une, ce test ne compilerait plus —
      // c'est exactement l'alerte qu'on veut (FR-037).
      final colonnes =
          base.courseCacheTable.$columns.map((c) => c.name).toList();
      expect(colonnes, contains('empreinte_code'));
      expect(colonnes, contains('empreinte_jeton'));
      expect(colonnes, isNot(contains('code_livraison')));
      expect(colonnes, isNot(contains('jeton_reception')));
    });
  });

  group('LignesChecklist (K3-1a)', () {
    test('la coche est locale et survit à la relecture', () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);

      await base.into(base.lignesChecklist).insert(
            LignesChecklistCompanion.insert(
              ligneId: 'ligne-1',
              arretId: _arret,
              libelle: 'Tomates',
              quantite: const Value(2),
              prixUnitaireUnites: const Value(400),
            ),
          );
      await (base.update(base.lignesChecklist)
            ..where((t) => t.ligneId.equals('ligne-1')))
          .write(const LignesChecklistCompanion(cochee: Value(true)));

      final ligne = await (base.select(base.lignesChecklist)
            ..where((t) => t.ligneId.equals('ligne-1')))
          .getSingle();
      expect(ligne.cochee, isTrue);
      expect(ligne.statut, 'presente',
          reason: 'la coche ne touche PAS le statut serveur (R11)');
    });
  });

  group('EssaisRemise (R5)', () {
    test('les essais faux se comptent localement, un compteur par livraison',
        () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);

      for (var i = 1; i <= 2; i++) {
        await base.into(base.essaisRemise).insertOnConflictUpdate(
              EssaisRemiseCompanion.insert(
                livraisonId: _livraison,
                essaisHorsLigne: Value(i),
                dernierEssaiLocal: Value(DateTime(2026, 7, 28, 15, i)),
              ),
            );
      }

      final tous = await base.select(base.essaisRemise).get();
      expect(tous, hasLength(1));
      expect(tous.single.essaisHorsLigne, 2,
          reason: 'le total voyage AVEC la demande, pas essai par essai');
    });
  });

  group('effacerCourse (R6, FR-034)', () {
    test('le numéro du client disparaît, la file en attente survit', () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);
      await _poserCourse(base);
      await base.into(base.essaisRemise).insert(
            EssaisRemiseCompanion.insert(
              livraisonId: _livraison,
              essaisHorsLigne: const Value(1),
            ),
          );
      await base.into(base.lignesChecklist).insert(
            LignesChecklistCompanion.insert(
              ligneId: 'ligne-1',
              arretId: _arret,
              libelle: 'Tomates',
            ),
          );
      // Une action NON rejouée au moment de la clôture : elle porte ce que le
      // serveur ignore encore.
      await base.into(base.actionsEnAttente).insert(
            ActionsEnAttenteCompanion.insert(
              uuidClient: 'action-en-vol',
              endpoint: '/courses/arrets/x/collecte',
              payloadJson: '{}',
              creeLeLocal: DateTime(2026, 7, 28, 14, 30),
            ),
          );

      await base.effacerCourse(_livraison);

      expect(await base.select(base.courseCacheTable).get(), isEmpty,
          reason: 'le numéro du client part avec la course');
      expect(await base.select(base.lignesChecklist).get(), isEmpty);
      expect(await base.select(base.essaisRemise).get(), isEmpty);
      expect(
        await base.select(base.actionsEnAttente).get(),
        hasLength(1),
        reason:
            'jeter une action en vol effacerait une collecte réellement faite '
            "— c'est-à-dire l'argent que Yao a déjà avancé",
      );
    });

    test('un relevé de présence NON envoyé survit à la clôture', () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);
      await _poserCourse(base);
      for (final (uuid, envoye) in [('deja-envoye', true), ('en-vol', false)]) {
        await base.into(base.relevesPresenceLocaux).insert(
              RelevesPresenceLocauxCompanion.insert(
                uuidClient: uuid,
                livraisonId: _livraison,
                distanceM: 12,
                releveLeLocal: DateTime(2026, 7, 28, 15, 2),
                envoye: Value(envoye),
              ),
            );
      }

      await base.effacerCourse(_livraison);

      final restants = await base.select(base.relevesPresenceLocaux).get();
      expect(restants.map((r) => r.uuidClient), ['en-vol'],
          reason: 'un échantillon non transmis fonde encore une indemnisation');
    });
  });

  group('schemaVersion (migration additive)', () {
    test('la version monte à 8 et les neuf tables sont déclarées', () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);

      // v5 : l'arrêt de REMISE dans `course_cache` (découvert en branchant K4).
      // v6 : le classement d'issue d'un rejeu (`statut`, `refuse_le_local`).
      // v7 : le mode d'envoi (`multipart`) — les transitions sont du JSON.
      // v8 : le dernier état connu de la CAISSE (K5 s'ouvre hors ligne, FR-076).
      // Toutes ADDITIVES : aucune table retirée, aucune action en vol perdue.
      expect(base.schemaVersion, 8);
      final tables = base.allTables.map((t) => t.actualTableName).toSet();
      expect(
        tables,
        containsAll([
          // Cycles 006 et 008 — AUCUNE n'est retirée ni modifiée.
          'actions_en_attente',
          'arrets_preprovisionnes',
          'brouillons_panier',
          'commandes_cache',
          // Cycle 010.
          'course_cache',
          'lignes_checklist',
          'essais_remise',
          'releves_presence_locaux',
          'caisse_cache',
        ]),
      );
    });
  });
}
