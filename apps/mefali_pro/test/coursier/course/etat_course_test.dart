/// L'état de course au NOUVEAU contrat (cycle CRS 010, T016/T017).
///
/// Le contrat de `GET /courses/active` a changé de forme : il porte désormais
/// les lignes d'articles, le client et les empreintes de remise. Ce fichier
/// prouve que ce que le cycle 006 avait livré tient toujours — la coche
/// optimiste, la validation hors ligne, le drain de file — **et** que ce que le
/// cycle 010 ajoute se comporte comme la maquette le dit.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_pro/coursier/course/etat_course.dart';

ArretCourse _arret({
  String id = 'arret-1',
  bool collecte = false,
  String statut = 'a_collecter',
  int montantAvance = 2000,
  int montantArticlesUnites = 0,
  int retenueAppliqueeUnites = 0,
  List<LigneChecklistVue> lignes = const [],
}) =>
    ArretCourse(
      arretId: id,
      prestataireId: 'presta-1',
      nom: 'Étal Adjoua',
      empreinteJeton: 'jeton',
      empreinteCode: 'code',
      siteLat: 5.898,
      siteLon: -4.823,
      montantAvance: montantAvance,
      montantArticlesUnites: montantArticlesUnites,
      retenueAppliqueeUnites: retenueAppliqueeUnites,
      devise: 'XOF',
      photoExigee: false,
      distanceMaxM: 100,
      collecte: collecte,
      statut: statut,
      lignes: lignes,
    );

LigneChecklistVue _ligne({
  String id = 'ligne-1',
  int prix = 400,
  int quantite = 2,
  String statut = 'presente',
  bool cochee = false,
}) =>
    LigneChecklistVue(
      ligneId: id,
      libelle: 'Tomates',
      quantite: quantite,
      prixUnitaireUnites: prix,
      preference: 'appeler',
      statut: statut,
      cochee: cochee,
    );

void main() {
  group('Montant de l\'arrêt (FR-013, SC-002)', () {
    test('le montant suit les LIGNES, pas la colonne du dernier chargement', () {
      final arret = _arret(
        montantAvance: 2000,
        lignes: [_ligne(prix: 400, quantite: 2), _ligne(id: 'l2', prix: 1200, quantite: 1)],
      );
      expect(arret.montantAPayerUnites, 2000);

      // Une ligne retirée hors ligne : le serveur n'a rien pu dire, mais Yao
      // doit voir le bon montant TOUT DE SUITE.
      final apresRetrait = arret.copieAvec(lignes: [
        _ligne(prix: 400, quantite: 2),
        _ligne(id: 'l2', prix: 1200, quantite: 1, statut: 'retiree'),
      ]);
      expect(apresRetrait.montantAPayerUnites, 800,
          reason: 'sans ce recalcul, Yao avancerait 2 000 pour 800 de marchandise');
    });

    test('la livraison offerte se déduit du net, articles et retenue visibles',
        () {
      // VND-08 (cycle PAY 011, FR-092). L'arrêt facture 2 000 d'articles, le
      // vendeur prend 500 de livraison à sa charge : Yao sort 1 500.
      final arret = _arret(
        montantAvance: 1500,
        retenueAppliqueeUnites: 500,
        lignes: [_ligne(prix: 400, quantite: 5)],
      );

      expect(arret.montantArticlesAPayerUnites, 2000, reason: 'le brut');
      expect(arret.montantAPayerUnites, 1500, reason: 'le net que Yao sort');
      expect(arret.aUneRetenue, isTrue);
      expect(arret.retenueEcretee, isFalse);
    });

    test('une retenue plus grande que les articles ne rend JAMAIS un net négatif',
        () {
      // FR-052 : le coursier ne finance rien. Le cas arrive pour de vrai quand
      // des lignes sont retirées après le devis.
      final arret = _arret(
        montantAvance: 0,
        retenueAppliqueeUnites: 2500,
        lignes: [_ligne(prix: 400, quantite: 2)],
      );

      expect(arret.montantAPayerUnites, 0);
      expect(arret.retenueEcretee, isTrue,
          reason: "l'écrêtage doit être VISIBLE : sans lui, l'écran afficherait "
              '0 sans dire pourquoi');
    });

    test('sans retenue, aucune explication ne s\'affiche', () {
      expect(_arret(lignes: [_ligne()]).aUneRetenue, isFalse);
    });

    test('un arrêt SANS ligne retombe sur le montant serveur', () {
      // Cas d'une course chargée avant que la checklist n'existe (cycle 006) :
      // on n'affiche pas 0 FCFA à un coursier qui doit bien payer quelque chose.
      expect(_arret(montantAvance: 1500).montantAPayerUnites, 1500);
    });

    test('« N articles pris » ne compte que les lignes cochées ET à payer', () {
      final arret = _arret(lignes: [
        _ligne(cochee: true),
        _ligne(id: 'l2', cochee: false),
        _ligne(id: 'l3', cochee: true, statut: 'retiree'),
      ]);
      expect(arret.articlesPris, 1,
          reason: 'une ligne retirée cochée par erreur ne compte pas');
    });
  });

  group('Progression de la course (K3)', () {
    test('l\'arrêt courant est le premier non résolu', () {
      const etat = EtatCourse(livraisonId: 'liv-1');
      expect(etat.arretCourant, isNull);

      final avecArrets = EtatCourse(livraisonId: 'liv-1', arrets: [
        _arret(id: 'a1', collecte: true, statut: 'collecte'),
        _arret(id: 'a2'),
        _arret(id: 'a3'),
      ]);
      expect(avecArrets.arretCourant?.arretId, 'a2');
      expect(avecArrets.rangArretCourant, 2, reason: 'le « Arrêt 2 / 3 » de K3');
      expect(avecArrets.toutCollecte, isFalse);
    });

    test('un arrêt INDISPONIBLE est résolu — la course continue sans lui', () {
      final etat = EtatCourse(livraisonId: 'liv-1', arrets: [
        _arret(id: 'a1', collecte: true, statut: 'collecte'),
        _arret(id: 'a2', statut: 'indisponible'),
      ]);
      expect(etat.arretCourant, isNull);
      expect(etat.toutCollecte, isTrue,
          reason: 'un vendeur fermé ne bloque pas la livraison (FR-018)');
    });

    test('sans livraison, il n\'y a pas de course — pas une course vide', () {
      const etat = EtatCourse();
      expect(etat.aUneCourse, isFalse);
      expect(etat.toutCollecte, isFalse);
    });
  });

  group('Montant à encaisser (FR-023)', () {
    test('il vient du SERVEUR et n\'est jamais recalculé localement', () {
      // L'app ne connaît pas les frais de livraison : recalculer le total
      // depuis les seules lignes afficherait un montant trop bas au moment de
      // l'encaissement — c'est-à-dire de l'argent perdu pour Yao.
      final etat = EtatCourse(
        livraisonId: 'liv-1',
        arrets: [_arret(lignes: [_ligne(prix: 400, quantite: 2)])],
        remise: const RemiseVue(montantAEncaisserUnites: 5800),
      );
      expect(etat.montantAEncaisserUnites, 5800);
      expect(etat.arrets.first.montantAPayerUnites, 800);
    });
  });

  group('Remise pré-provisionnée (K4)', () {
    test('seules les empreintes sont portées, avec le seuil du cycle 008', () {
      const remise = RemiseVue(
        empreinteCode: 'a1b2',
        empreinteJeton: 'c3d4',
        essaisConsommes: 1,
        essaisMax: 3,
      );
      expect(remise.empreinteCode, 'a1b2');
      expect(remise.essaisMax, 3);
      expect(remise.codeBloque, isFalse);
      expect(remise.modePaiement, 'cash');
    });

    test('le dépôt est FERMÉ par défaut (FR-039)', () {
      const client = ClientCourseVue();
      expect(client.depotAutorise, isFalse);
      expect(client.nomUsage, isNull,
          reason: 'aucune donnée nominative n\'existe au MVP');
    });
  });

  group('File hors-ligne (FR-083)', () {
    test('le compteur d\'actions et le poids des photos sont portés', () {
      const etat = EtatCourse(
        livraisonId: 'liv-1',
        actionsEnAttente: 2,
        octetsPhotosEnAttente: 51200,
      );
      expect(etat.actionsEnAttente, 2);
      expect(etat.octetsPhotosEnAttente, 51200);
    });
  });
}
