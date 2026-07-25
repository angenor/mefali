/// Base locale hors-ligne (constitution V ; data-model 006 §8, 008 §8).
///
/// `drift` (SQLite) : durable (survit au kill), transactionnel, et capable de
/// porter des OCTETS de photo — `shared_preferences` ne conviendrait pas.
///
/// Quatre tables :
///
/// | Table | Cycle | Rôle |
/// |---|---|---|
/// | `actions_en_attente` | QRC 006 | file idempotente des POST à rejouer |
/// | `arrets_preprovisionnes` | QRC 006 | cache de course coursier (empreintes) |
/// | `brouillons_panier` | CMD 008 | panier CLIENT modifiable hors ligne |
/// | `commandes_cache` | CMD 008 | dernier état connu + code et QR de remise |
///
/// Les deux tables du cycle CMD servent l'app CLIENTE : le panier se compose
/// sans réseau (maquette C3-3c) et le bloc « À la livraison » se rend
/// **uniquement** depuis le cache (C4-4d) — Awa n'a jamais besoin d'internet au
/// moment où le coursier arrive.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'action_en_attente.g.dart';

/// File des actions POST à rejouer au retour réseau. Idempotence par
/// `uuidClient` (clé primaire) : un rejeu ne crée jamais de doublon.
@DataClassName('ActionEnAttente')
class ActionsEnAttente extends Table {
  /// Clé d'idempotence (UUIDv7) générée à l'action — PK.
  TextColumn get uuidClient => text()();

  /// Endpoint cible (ex. `/courses/arrets/{id}/collecte`).
  TextColumn get endpoint => text()();

  /// Méthode HTTP (MVP : `POST`).
  TextColumn get methode => text().withDefault(const Constant('POST'))();

  /// Corps JSON sérialisé de la demande.
  TextColumn get payloadJson => text()();

  /// Photo de récupération (si exigée) — octets bruts, facultatif.
  BlobColumn get photoOctets => blob().nullable()();

  /// Horodatage LOCAL de création (journalisé, jamais fait autorité).
  DateTimeColumn get creeLeLocal => dateTime()();

  /// Nombre de tentatives de rejeu.
  IntColumn get tentatives => integer().withDefault(const Constant(0))();

  /// Dernier motif d'échec (clé i18n ou message serveur), le cas échéant.
  TextColumn get dernierMotif => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuidClient};
}

/// Cache de la course active (pré-provisionnement R6) : empreintes + sites +
/// montants + politique photo résolue. Permet la validation HORS-LIGNE.
@DataClassName('ArretPreprovisionne')
class ArretsPreprovisionnes extends Table {
  /// Arrêt à collecter — PK.
  TextColumn get arretId => text()();

  /// Prestataire visé.
  TextColumn get prestataireId => text()();

  /// Nom du prestataire (affiché sur la carte K3).
  TextColumn get nom => text().withDefault(const Constant(''))();

  /// base16(sha256(jeton)) — match hors-ligne du QR scanné.
  TextColumn get empreinteJeton => text()();

  /// base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
  TextColumn get empreinteCode => text()();

  /// Position attendue du site (proximité).
  RealColumn get siteLat => real()();

  /// Position attendue du site.
  RealColumn get siteLon => real()();

  /// Montant avancé (unités mineures).
  IntColumn get montantAvance => integer()();

  /// Devise ISO 4217.
  TextColumn get devise => text()();

  /// Photo exigée (politique résolue).
  BoolColumn get photoExigee => boolean()();

  /// Rayon max de scan (m) — validation de proximité HORS-LIGNE (R6).
  IntColumn get distanceMaxM => integer().withDefault(const Constant(100))();

  /// Coche optimiste locale avant réconciliation serveur
  /// (`a_collecter` | `collecte`).
  TextColumn get statutLocal =>
      text().withDefault(const Constant('a_collecter'))();

  @override
  Set<Column> get primaryKey => {arretId};
}

/// Brouillon de panier CLIENT, modifiable **hors connexion** (CMD-01,
/// maquette C3-3c).
///
/// Aucune table serveur ne lui correspond : rien n'est engagé tant que la
/// commande n'est pas créée (research R8). Le total porté ici est donc
/// **estimé** — les frais réels sortent du devis serveur, jamais de l'app.
@DataClassName('BrouillonPanier')
class BrouillonsPanier extends Table {
  /// Un seul brouillon à la fois par zone — PK.
  TextColumn get zoneId => text()();

  /// Catégorie de service en cours de composition.
  TextColumn get categorieSlug => text()();

  /// Lignes sérialisées (prestataire, article, quantité, préférence).
  TextColumn get lignesJson => text()();

  /// Total ESTIMÉ des articles, unités mineures (jamais les frais — hors ligne,
  /// l'app ne connaît pas le devis).
  IntColumn get montantArticlesEstimeUnites =>
      integer().withDefault(const Constant(0))();

  /// Devise ISO 4217.
  TextColumn get devise => text().withDefault(const Constant('XOF'))();

  /// Dernière modification locale.
  DateTimeColumn get majLeLocal => dateTime()();

  @override
  Set<Column> get primaryKey => {zoneId};
}

/// Cache de commande CLIENT : dernier état connu, progression, et surtout le
/// **code et le jeton QR de remise** (CMD-05, FR-042/043).
///
/// C'est la table qui rend le bloc « À la livraison » disponible **sans
/// réseau** : il se rend uniquement d'ici, aucun appel n'est émis sur ce
/// chemin. Le code et le jeton sont écrits dès la création de la commande —
/// pas au moment de la remise, où le réseau peut manquer.
@DataClassName('CommandeCache')
class CommandesCache extends Table {
  /// Commande — PK.
  TextColumn get commandeId => text()();

  /// Dernier état connu du tronc (`nouvelle`, `en_cours`…). Annoncé COMME TEL
  /// hors ligne : l'app ne prétend jamais que c'est l'état courant.
  TextColumn get etat => text()();

  /// Clé i18n de l'état, pour l'affichage en langage clair.
  TextColumn get etatCle => text().withDefault(const Constant(''))();

  /// Collectes faites (la remise n'en est pas une — P1).
  IntColumn get collectesFaites => integer().withDefault(const Constant(0))();

  /// Total de collectes.
  IntColumn get collectesTotal => integer().withDefault(const Constant(0))();

  /// Code de remise à 4 chiffres — lisible par le CLIENT seul.
  TextColumn get codeLivraison => text()();

  /// Jeton encodé dans le QR de réception.
  TextColumn get jetonReception => text()();

  /// Total à régler, unités mineures.
  IntColumn get totalUnites => integer().withDefault(const Constant(0))();

  /// Devise ISO 4217.
  TextColumn get devise => text().withDefault(const Constant('XOF'))();

  /// Dernière position connue du coursier (nulle si aucune).
  RealColumn get positionLat => real().nullable()();

  /// Dernière position connue du coursier.
  RealColumn get positionLon => real().nullable()();

  /// Âge de la position AU MOMENT DE LA MISE EN CACHE (secondes). L'app y
  /// ajoute le temps écoulé depuis [majLeLocal] : elle n'invente jamais une
  /// position fraîche (FR-040).
  IntColumn get positionAgeS => integer().nullable()();

  /// Horodatage local de la mise en cache — base du calcul d'ancienneté.
  DateTimeColumn get majLeLocal => dateTime()();

  @override
  Set<Column> get primaryKey => {commandeId};
}

/// Base locale drift : file coursier (006) + cache client (008).
@DriftDatabase(
  tables: [
    ActionsEnAttente,
    ArretsPreprovisionnes,
    BrouillonsPanier,
    CommandesCache,
  ],
)
class BaseOffline extends _$BaseOffline {
  /// Ouvre la base sur le fichier fourni (production : répertoire application ;
  /// tests : base en mémoire via [BaseOffline.memoire]).
  BaseOffline(super.e);

  /// Base éphémère en mémoire — tests uniquement.
  BaseOffline.memoire() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2 (cycle QRC) : nom du prestataire + rayon de scan au cache de
          // course (affichage K3 + validation de proximité hors-ligne, R6).
          if (from < 2) {
            await m.addColumn(arretsPreprovisionnes, arretsPreprovisionnes.nom);
            await m.addColumn(
                arretsPreprovisionnes, arretsPreprovisionnes.distanceMaxM);
          }
          // v3 (cycle CMD) : les deux tables du CLIENT — brouillon de panier
          // hors ligne et cache de commande (code + QR de remise). Créées, pas
          // migrées : elles n'existaient pas.
          if (from < 3) {
            await m.createTable(brouillonsPanier);
            await m.createTable(commandesCache);
          }
        },
      );

  /// Ouvre (ou crée) le fichier de base dans le répertoire application.
  static BaseOffline ouvrir() {
    return BaseOffline(
      LazyDatabase(() async {
        final dossier = await getApplicationDocumentsDirectory();
        final fichier = File(p.join(dossier.path, 'mefali_offline.sqlite'));
        return NativeDatabase.createInBackground(fichier);
      }),
    );
  }
}
