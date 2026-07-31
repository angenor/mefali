/// Base locale hors-ligne (constitution V ; data-model 006 §8, 008 §8).
///
/// `drift` (SQLite) : durable (survit au kill), transactionnel, et capable de
/// porter des OCTETS de photo — `shared_preferences` ne conviendrait pas.
///
/// Huit tables :
///
/// | Table | Cycle | Rôle |
/// |---|---|---|
/// | `actions_en_attente` | QRC 006 | file idempotente des POST à rejouer |
/// | `arrets_preprovisionnes` | QRC 006 | cache de course coursier (empreintes) |
/// | `brouillons_panier` | CMD 008 | panier CLIENT modifiable hors ligne |
/// | `commandes_cache` | CMD 008 | dernier état connu + code et QR de remise |
/// | `course_cache` | CRS 010 | client, repère, empreintes de remise, montant |
/// | `lignes_checklist` | CRS 010 | articles à acheter, avec leur coche LOCALE |
/// | `essais_remise` | CRS 010 | codes faux consommés hors ligne, par livraison |
/// | `releves_presence_locaux` | CRS 010 | échantillons de présence en attente |
///
/// Les deux tables du cycle CMD servent l'app CLIENTE : le panier se compose
/// sans réseau (maquette C3-3c) et le bloc « À la livraison » se rend
/// **uniquement** depuis le cache (C4-4d) — Awa n'a jamais besoin d'internet au
/// moment où le coursier arrive.
///
/// Les quatre du cycle CRS servent l'app PRO, et toutes pour la même raison :
/// une course doit fonctionner **de bout en bout** sans réseau (FR-028). Elles
/// s'ajoutent, aucune existante n'est modifiée — `arrets_preprovisionnes` est
/// conservée telle quelle et gagne ce qui lui manque par jointure logique avec
/// `course_cache`, pour que la file en vol au moment de la mise à jour continue
/// de fonctionner (data-model 010 §4).
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

  /// L'action voyage-t-elle en `multipart/form-data` ?
  ///
  /// **Toutes ne le sont pas, et c'est le contrat qui le dit** : seules celles
  /// qui peuvent porter une photo (collecte, substitution, remise, preuve) sont
  /// multipart ; les transitions d'arrêt attendent du JSON. Envoyer tout de la
  /// même façon faisait échouer la moitié des endpoints au drain — bug attrapé
  /// par le test qui fait foi du module.
  BoolColumn get multipart => boolean().withDefault(const Constant(true))();

  /// `en_attente` (rejouable) ou `refuse` (refus DÉFINITIF du serveur).
  ///
  /// Les deux issues d'un rejeu n'ont rien à voir (FR-085) : un échec RÉSEAU se
  /// réessaie indéfiniment ; un refus MÉTIER — course réassignée, arrêt déjà
  /// collecté — ne se réessaiera jamais avec succès, et insister le ferait
  /// compter comme une panne. Une action refusée sort donc de la file… mais pas
  /// de la trace : Yao doit pouvoir savoir ce qui est arrivé à une collecte
  /// qu'il a réellement faite (FR-086).
  TextColumn get statut => text().withDefault(const Constant('en_attente'))();

  /// Instant LOCAL du refus définitif — l'ordre du journal de réconciliation.
  DateTimeColumn get refuseLeLocal => dateTime().nullable()();

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

/// Cache de la course COMPLÈTE (cycle CRS 010) : le client, son repère, les
/// empreintes de remise, le montant à encaisser.
///
/// C'est ce qui rend K3 et K4 utilisables sans réseau. Une seule ligne à la
/// fois — la course active.
///
/// ⚠ Deux données personnelles y vivent : le numéro du CLIENT et celui du
/// vendeur (porté par [ArretsPreprovisionnes] côté serveur, ici pour le client).
/// L'appel doit marcher hors ligne, donc ils doivent être là ; ils sont
/// **effacés à la clôture de la course** (R6, FR-034) et n'entrent dans aucun
/// journal.
@DataClassName('CourseCache')
class CourseCacheTable extends Table {
  @override
  String get tableName => 'course_cache';

  /// Livraison active — PK.
  TextColumn get livraisonId => text()();

  /// Commande portée.
  TextColumn get commandeId => text()();

  /// Dernier état connu de la livraison.
  TextColumn get etat => text()();

  /// Devise ISO 4217.
  TextColumn get devise => text().withDefault(const Constant('XOF'))();

  /// Nom d'usage du client — jamais l'état civil.
  TextColumn get clientNomUsage => text().withDefault(const Constant(''))();

  /// Contact du client. EFFACÉ à la clôture (R6).
  TextColumn get clientTelephone => text().nullable()();

  /// Repère écrit.
  TextColumn get repereTexte => text().nullable()();

  /// Chemin du fichier audio TÉLÉCHARGÉ — pas l'URL présignée, qui expire.
  /// C'est le fichier local qui rend la note jouable en mode avion (FR-024).
  TextColumn get repereVocalFichier => text().nullable()();

  /// Durée de la note vocale (s).
  IntColumn get repereVocalDureeS => integer().nullable()();

  /// Point de livraison.
  RealColumn get lieuLat => real().nullable()();

  /// Point de livraison.
  RealColumn get lieuLon => real().nullable()();

  /// La voie « dépôt » est-elle ouverte sur CETTE commande (FR-039) ?
  BoolColumn get depotAutorise =>
      boolean().withDefault(const Constant(false))();

  /// Empreinte salée du code à 4 chiffres — jamais le code (FR-037).
  TextColumn get empreinteCode => text().withDefault(const Constant(''))();

  /// Empreinte du jeton de réception — jamais le jeton.
  TextColumn get empreinteJeton => text().withDefault(const Constant(''))();

  /// Essais faux déjà comptés côté SERVEUR au moment du cache.
  IntColumn get essaisConsommes => integer().withDefault(const Constant(0))();

  /// Seuil de zone (paramètre du cycle 008, `commande.essais_code_livraison`).
  IntColumn get essaisMax => integer().withDefault(const Constant(3))();

  /// Saisie du code bloquée côté serveur (K4-1d).
  BoolColumn get codeBloque => boolean().withDefault(const Constant(false))();

  /// Total à encaisser chez le client (unités mineures).
  IntColumn get montantAEncaisserUnites =>
      integer().withDefault(const Constant(0))();

  /// `cash` | `mobile_money` — décide s'il y a quelque chose à encaisser.
  TextColumn get modePaiement => text().withDefault(const Constant('cash'))();

  /// Seuils de preuve de la zone, sérialisés — l'écran des preuves doit savoir
  /// compter hors ligne (le serveur revérifie de toute façon, FR-060).
  TextColumn get seuilsPreuvesJson =>
      text().withDefault(const Constant('{}'))();

  /// Arrêt de REMISE — la cible de « je suis arrivé chez le client » (FR-053).
  ///
  /// Il n'est pas dans `arrets_preprovisionnes`, qui ne porte que les collectes
  /// (c'est ce qui permet de savoir que tout est collecté). Sans lui, le bouton
  /// de K3-1c n'aurait rien à transitionner, hors ligne comme en ligne.
  TextColumn get arretRemiseId => text().nullable()();

  /// Statut de l'arrêt de remise (`a_collecter` | `en_route` | `arrive`).
  TextColumn get arretRemiseStatut => text().nullable()();

  /// Instant SERVEUR d'arrivée chez le client — affiché sur K4-1a (FR-052).
  DateTimeColumn get arriveChezClientLe => dateTime().nullable()();

  /// Dernière mise en cache (local).
  DateTimeColumn get majLeLocal => dateTime()();

  @override
  Set<Column> get primaryKey => {livraisonId};
}

/// Les articles à acheter chez chaque vendeur, et leur **coche locale**
/// (cycle CRS 010, K3-1a).
///
/// La coche n'est JAMAIS envoyée au serveur (R11, FR-079) : c'est un
/// aide-mémoire d'achat, pas un fait métier. Le serveur ne connaît que « ligne
/// présente / remplacée / retirée » ; inventer un état serveur « article
/// coché » créerait une troisième vérité que rien ne consomme.
@DataClassName('LigneChecklist')
class LignesChecklist extends Table {
  /// Ligne de commande — PK.
  TextColumn get ligneId => text()();

  /// Arrêt auquel elle appartient.
  TextColumn get arretId => text()();

  /// Libellé figé à la création de la commande.
  TextColumn get libelle => text()();

  /// Quantité commandée.
  IntColumn get quantite => integer().withDefault(const Constant(1))();

  /// Prix unitaire VERROUILLÉ (unités mineures).
  IntColumn get prixUnitaireUnites => integer().withDefault(const Constant(0))();

  /// Ce que le client a choisi si l'article manque
  /// (`remplacer` | `appeler` | `retirer`).
  TextColumn get preference => text().withDefault(const Constant('appeler'))();

  /// Statut SERVEUR (`presente` | `remplacee` | `retiree`).
  TextColumn get statut => text().withDefault(const Constant('presente'))();

  /// Coche LOCALE — jamais synchronisée.
  BoolColumn get cochee => boolean().withDefault(const Constant(false))();

  /// Rang d'affichage dans l'arrêt.
  IntColumn get ordre => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {ligneId};
}

/// Essais du code de remise consommés **hors ligne** (cycle CRS 010, R5).
///
/// Ils ne partent pas un par un dans la file : les envoyer ferait voyager des
/// codes faux sans aucun bénéfice. L'app compte ici, et transporte le total
/// **avec** la demande de remise ; le serveur retient `max(serveur, local)`.
@DataClassName('EssaiRemise')
class EssaisRemise extends Table {
  /// Livraison — PK.
  TextColumn get livraisonId => text()();

  /// Essais faux comptés localement depuis la dernière consolidation.
  IntColumn get essaisHorsLigne => integer().withDefault(const Constant(0))();

  /// Dernier essai (local).
  DateTimeColumn get dernierEssaiLocal => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {livraisonId};
}

/// Échantillons de présence en attente d'envoi (cycle CRS 010, FR-061).
///
/// Une **distance arrondie**, jamais un couple lat/lon : la minimisation ARTCI
/// vaut aussi sur l'appareil (R8). Ils partent en LOT, parce que la file peut
/// en avoir accumulé plusieurs minutes.
@DataClassName('RelevePresenceLocal')
class RelevesPresenceLocaux extends Table {
  /// Clé d'idempotence de l'échantillon (UUIDv7) — PK.
  TextColumn get uuidClient => text()();

  /// Livraison concernée.
  TextColumn get livraisonId => text()();

  /// Distance ARRONDIE au point de livraison (m).
  IntColumn get distanceM => integer()();

  /// Horodatage local de l'échantillon.
  DateTimeColumn get releveLeLocal => dateTime()();

  /// Envoyé et accepté par le serveur — la ligne peut être purgée.
  BoolColumn get envoye => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uuidClient};
}

/// Base locale drift : file coursier (006) + cache client (008) + course
/// complète, checklist, essais et présence (010).
@DriftDatabase(
  tables: [
    ActionsEnAttente,
    ArretsPreprovisionnes,
    BrouillonsPanier,
    CommandesCache,
    CourseCacheTable,
    LignesChecklist,
    EssaisRemise,
    RelevesPresenceLocaux,
  ],
)
class BaseOffline extends _$BaseOffline {
  /// Ouvre la base sur le fichier fourni (production : répertoire application ;
  /// tests : base en mémoire via [BaseOffline.memoire]).
  BaseOffline(super.e);

  /// Base éphémère en mémoire — tests uniquement.
  BaseOffline.memoire() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 7;

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
          // v4 (cycle CRS) : les quatre tables de la course coursier. Migration
          // strictement ADDITIVE — aucune table existante n'est touchée, en
          // particulier `actions_en_attente` : une file qui contient des
          // collectes non rejouées au moment de la mise à jour doit survivre au
          // passage de version. Perdre une action en vol, c'est perdre l'argent
          // que Yao a déjà avancé.
          if (from < 4) {
            await m.createTable(courseCacheTable);
            await m.createTable(lignesChecklist);
            await m.createTable(essaisRemise);
            await m.createTable(relevesPresenceLocaux);
          }
          // v5 (cycle CRS, T039) : l'arrêt de REMISE dans le cache de course.
          // Découvert en branchant K4 — « je suis arrivé chez le client » n'avait
          // aucune cible : la liste d'arrêts ne porte que les collectes. Trois
          // colonnes AJOUTÉES, aucune touchée.
          if (from < 5) {
            await m.addColumn(courseCacheTable, courseCacheTable.arretRemiseId);
            await m.addColumn(
                courseCacheTable, courseCacheTable.arretRemiseStatut);
            await m.addColumn(
                courseCacheTable, courseCacheTable.arriveChezClientLe);
          }
          // v6 (cycle CRS, T046/T047) : l'issue d'un rejeu se classe. Deux
          // colonnes AJOUTÉES sur `actions_en_attente` — la table la plus
          // sensible du dépôt : les actions déjà en vol gardent leur défaut
          // `en_attente` et continuent de se rejouer exactement comme avant.
          if (from < 6) {
            await m.addColumn(actionsEnAttente, actionsEnAttente.statut);
            await m.addColumn(actionsEnAttente, actionsEnAttente.refuseLeLocal);
          }
          // v7 : le drain distingue JSON et multipart. Défaut `true` — c'est ce
          // que faisait le code d'avant, donc les actions DÉJÀ en vol se
          // rejouent exactement comme elles auraient été envoyées.
          if (from < 7) {
            await m.addColumn(actionsEnAttente, actionsEnAttente.multipart);
          }
        },
      );

  /// Efface tout ce qui appartient à une course terminée — **numéros de
  /// téléphone compris** (R6, FR-034).
  ///
  /// Appelée à la clôture, quelle qu'en soit l'issue (livrée, échec, course
  /// retirée). Les actions ENCORE EN ATTENTE ne sont pas touchées : elles
  /// portent ce qui n'a pas encore été dit au serveur, et les jeter reviendrait
  /// à effacer une collecte que Yao a réellement faite.
  Future<void> effacerCourse(String livraisonId) async {
    await transaction(() async {
      await (delete(courseCacheTable)
            ..where((t) => t.livraisonId.equals(livraisonId)))
          .go();
      await (delete(essaisRemise)
            ..where((t) => t.livraisonId.equals(livraisonId)))
          .go();
      await (delete(relevesPresenceLocaux)
            ..where((t) => t.livraisonId.equals(livraisonId) & t.envoye.equals(true)))
          .go();
      // La checklist se rattache aux arrêts de la course : ils partent avec.
      await delete(lignesChecklist).go();
      await delete(arretsPreprovisionnes).go();
    });
  }

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
