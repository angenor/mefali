/// File d'actions coursier hors-ligne (constitution V, data-model 006 §8).
///
/// `drift` (SQLite) : durable (survit au kill), transactionnel, et capable de
/// porter des OCTETS de photo — `shared_preferences` ne conviendrait pas. Deux
/// tables : la file idempotente `action_en_attente` (clé = `uuid_client`
/// UUIDv7) et le cache de course `arret_preprovisionne` (empreintes, jamais de
/// secret — R6), qui permet scan, proximité et confirmation par code HORS-LIGNE.
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

/// Base locale drift de la file offline coursier.
@DriftDatabase(tables: [ActionsEnAttente, ArretsPreprovisionnes])
class BaseOffline extends _$BaseOffline {
  /// Ouvre la base sur le fichier fourni (production : répertoire application ;
  /// tests : base en mémoire via [BaseOffline.memoire]).
  BaseOffline(super.e);

  /// Base éphémère en mémoire — tests uniquement.
  BaseOffline.memoire() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

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
