import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'etat_course.g.dart';

/// Mode de collecte côté app (scan du QR ou saisie du code de secours).
enum ModeScan {
  /// Scan du QR de la plaque.
  scanQr,

  /// Saisie du code de secours (mode dégradé).
  codeSecours,
}

/// En ligne ? — dérivé de `connectivity_plus`, réduit à un booléen et
/// `.distinct()` : n'émet qu'aux VRAIES transitions (le flux brut envoie de
/// nombreux événements redondants, surtout sur l'émulateur). Sans ce filtre,
/// chaque événement déclencherait un rebuild de la course (tempête observée).
@riverpod
Stream<bool> connectiviteEnLigne(Ref ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((etats) => etats.any((e) => e != ConnectivityResult.none))
      .distinct();
}

/// Un article de la checklist (cycle CRS 010, K3-1a).
///
/// La **coche** est locale et ne quitte jamais l'appareil (R11, FR-079) : le
/// serveur ne connaît que « présente / remplacée / retirée ». C'est un
/// aide-mémoire d'achat, pas un fait métier.
class LigneChecklistVue {
  /// Crée une ligne de checklist.
  const LigneChecklistVue({
    required this.ligneId,
    required this.libelle,
    required this.quantite,
    required this.prixUnitaireUnites,
    required this.preference,
    required this.statut,
    required this.cochee,
  });

  /// Ligne de commande.
  final String ligneId;

  /// Libellé de l'article.
  final String libelle;

  /// Quantité commandée.
  final int quantite;

  /// Prix unitaire VERROUILLÉ à la création (unités mineures).
  final int prixUnitaireUnites;

  /// `remplacer` | `appeler` | `retirer`.
  final String preference;

  /// `presente` | `remplacee` | `retiree`.
  final String statut;

  /// Coche LOCALE.
  final bool cochee;

  /// La ligne est-elle encore à payer ?
  bool get aPayer => statut != 'retiree';

  /// Ce que cette ligne coûte — zéro si elle a été retirée (FR-013).
  int get montantUnites => aPayer ? prixUnitaireUnites * quantite : 0;
}

/// Le client de la course, tel que Yao en a besoin devant la porte.
class ClientCourseVue {
  /// Crée la vue client.
  const ClientCourseVue({
    this.nomUsage,
    this.telephone,
    this.repereTexte,
    this.repereVocalFichier,
    this.repereVocalDureeS,
    this.lieuLat,
    this.lieuLon,
    this.depotAutorise = false,
  });

  /// Nom d'usage — `null` tant que le produit n'en porte aucun.
  final String? nomUsage;

  /// Contact. Effacé du cache à la clôture (R6).
  final String? telephone;

  /// Repère écrit.
  final String? repereTexte;

  /// Chemin LOCAL du fichier audio téléchargé — pas l'URL, qui expire.
  final String? repereVocalFichier;

  /// Durée de la note vocale (s).
  final int? repereVocalDureeS;

  /// Point de livraison.
  final double? lieuLat;

  /// Point de livraison.
  final double? lieuLon;

  /// La voie « dépôt » est-elle ouverte sur cette commande (FR-039) ?
  final bool depotAutorise;
}

/// De quoi confirmer la remise sans réseau (K4).
/// Les seuils de preuve d'échec de la zone (K4-1e).
///
/// Ils voyagent dans le pré-provisionnement — jamais en dur, jamais redemandés
/// au moment où Yao en a besoin : quand il est devant une porte close, c'est
/// souvent qu'il n'a pas de réseau non plus.
///
/// Les valeurs par défaut ne sont **pas** une configuration : elles ne servent
/// qu'au cas où le cache local est vide, et le serveur revalide de toute façon
/// (FR-060).
class SeuilsPreuvesVue {
  /// Crée les seuils.
  const SeuilsPreuvesVue({
    this.appelsMin = 2,
    this.espacementS = 180,
    this.presenceS = 600,
    this.rayonM = 100,
    this.photosMin = 1,
  });

  /// Lit les seuils depuis le JSON mis en cache par le pré-provisionnement.
  factory SeuilsPreuvesVue.depuisJson(String? json) {
    if (json == null || json.isEmpty) return const SeuilsPreuvesVue();
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      const defaut = SeuilsPreuvesVue();
      return SeuilsPreuvesVue(
        appelsMin: (m['appels_min'] as num?)?.toInt() ?? defaut.appelsMin,
        espacementS: (m['espacement_s'] as num?)?.toInt() ?? defaut.espacementS,
        presenceS: (m['presence_s'] as num?)?.toInt() ?? defaut.presenceS,
        rayonM: (m['rayon_m'] as num?)?.toInt() ?? defaut.rayonM,
        photosMin: (m['photos_min'] as num?)?.toInt() ?? defaut.photosMin,
      );
    } on FormatException {
      // Un cache illisible ne doit pas empêcher d'ouvrir l'écran : les seuils
      // par défaut affichent quelque chose, et le serveur tranche.
      return const SeuilsPreuvesVue();
    }
  }

  /// Appels `client_absent` exigés.
  final int appelsMin;

  /// Espacement minimal entre deux appels retenus (s).
  final int espacementS;

  /// Présence continue exigée (s).
  final int presenceS;

  /// Rayon dans lequel un relevé compte (m).
  final int rayonM;

  /// Photos exigées.
  final int photosMin;
}

class RemiseVue {
  /// Crée la vue de remise.
  const RemiseVue({
    this.empreinteCode = '',
    this.empreinteJeton = '',
    this.essaisConsommes = 0,
    this.essaisMax = 3,
    this.codeBloque = false,
    this.montantAEncaisserUnites = 0,
    this.modePaiement = 'cash',
    this.preuves = const SeuilsPreuvesVue(),
    this.arretRemiseId,
    this.arretRemiseStatut,
    this.arriveChezClientLe,
    this.valideeLocalementLe,
  });

  /// Seuils de preuve d'échec de la zone — servis avec la course pour que
  /// K4-1e sache compter **hors ligne** (FR-058).
  final SeuilsPreuvesVue preuves;

  /// Empreinte salée du code — **jamais le code** (FR-037).
  final String empreinteCode;

  /// Empreinte du jeton de réception — **jamais le jeton**.
  final String empreinteJeton;

  /// Essais faux comptés côté serveur au dernier chargement.
  final int essaisConsommes;

  /// Seuil de zone (paramètre du cycle 008).
  final int essaisMax;

  /// Saisie bloquée côté serveur (K4-1d).
  final bool codeBloque;

  /// Total à encaisser chez le client (unités mineures).
  final int montantAEncaisserUnites;

  /// `cash` | `mobile_money`.
  final String modePaiement;

  /// Arrêt de REMISE — la cible de « je suis arrivé chez le client » (FR-053).
  ///
  /// Il n'est pas dans la liste des arrêts, qui ne porte que les collectes :
  /// c'est ce qui permet à [EtatCourse.toutCollecte] d'être vrai. Sans cet
  /// identifiant, le bouton de K3-1c n'aurait rien à envoyer.
  final String? arretRemiseId;

  /// Statut de l'arrêt de remise (`a_collecter` | `en_route` | `arrive`).
  final String? arretRemiseStatut;

  /// Instant SERVEUR d'arrivée chez le client — affiché sur K4-1a (FR-052).
  final DateTime? arriveChezClientLe;

  /// Instant LOCAL d'une remise validée sans réseau (FR-041), en attente de
  /// synchronisation. Nul dès que le serveur a repris la main.
  final DateTime? valideeLocalementLe;

  /// Yao a-t-il déclaré son arrivée chez le client ? C'est ce qui ouvre K4.
  bool get arriveChezClient => arretRemiseStatut == 'arrive';

  /// La remise a-t-elle été validée hors ligne, sans que le serveur l'ait
  /// encore confirmée ? C'est ce qui ferme K4 : sans ce drapeau, l'écran
  /// reproposait de scanner une commande déjà remise (T087).
  bool get valideeLocalement => valideeLocalementLe != null;
}

/// Un arrêt de la course, fusion de la donnée serveur (pré-provisionnement) et
/// de la coche optimiste locale (drift).
class ArretCourse {
  /// Crée un arrêt de course.
  const ArretCourse({
    required this.arretId,
    required this.prestataireId,
    required this.nom,
    required this.empreinteJeton,
    required this.empreinteCode,
    required this.siteLat,
    required this.siteLon,
    required this.montantAvance,
    required this.devise,
    required this.photoExigee,
    required this.distanceMaxM,
    required this.collecte,
    this.statut = 'a_collecter',
    this.collecteLe,
    this.telephoneVendeur,
    this.lignes = const [],
  });

  /// Arrêt à collecter.
  final String arretId;

  /// Prestataire visé.
  final String prestataireId;

  /// Nom du prestataire (affiché sur la carte K3).
  final String nom;

  /// Empreinte du jeton (match hors-ligne).
  final String empreinteJeton;

  /// Empreinte du code de secours (confirmation dégradée hors-ligne).
  final String empreinteCode;

  /// Position attendue du site.
  final double siteLat;

  /// Position attendue du site.
  final double siteLon;

  /// Montant avancé (unités mineures).
  final int montantAvance;

  /// Devise ISO 4217.
  final String devise;

  /// Photo exigée.
  final bool photoExigee;

  /// Rayon max de scan (m) — validation de proximité hors-ligne (R6).
  final int distanceMaxM;

  /// Coché (serveur ou optimiste local).
  final bool collecte;

  /// Statut SERVEUR de l'arrêt (`a_collecter` | `en_route` | `arrive` |
  /// `collecte` | `indisponible`).
  final String statut;

  /// Heure de collecte — affichée sur l'arrêt replié (K3-1b).
  final DateTime? collecteLe;

  /// Contact du vendeur — appel HORS LIGNE (R6). Jamais journalisé.
  final String? telephoneVendeur;

  /// Articles à acheter chez ce vendeur (K3-1a).
  final List<LigneChecklistVue> lignes;

  /// Ce que Yao doit sortir de sa poche à CET arrêt, après retraits (FR-013).
  ///
  /// Les lignes font autorité, pas [montantAvance] : celui-ci vient du dernier
  /// chargement serveur et devient faux dès qu'une ligne est retirée hors ligne.
  int get montantAPayerUnites => lignes.isEmpty
      ? montantAvance
      : lignes.fold(0, (somme, l) => somme + l.montantUnites);

  /// Articles effectivement pris (cochés et non retirés) — le « (2 articles
  /// pris) » de K3-1a.
  int get articlesPris => lignes.where((l) => l.cochee && l.aPayer).length;

  /// Copie avec substitution.
  ArretCourse copieAvec({List<LigneChecklistVue>? lignes}) => ArretCourse(
        arretId: arretId,
        prestataireId: prestataireId,
        nom: nom,
        empreinteJeton: empreinteJeton,
        empreinteCode: empreinteCode,
        siteLat: siteLat,
        siteLon: siteLon,
        montantAvance: montantAvance,
        devise: devise,
        photoExigee: photoExigee,
        distanceMaxM: distanceMaxM,
        collecte: collecte,
        statut: statut,
        collecteLe: collecteLe,
        telephoneVendeur: telephoneVendeur,
        lignes: lignes ?? this.lignes,
      );
}

/// Une action **refusée définitivement** par le serveur au rejeu (FR-086).
///
/// Elle n'est pas une erreur technique : c'est un fait métier que Yao doit
/// pouvoir raconter. « J'ai bien collecté chez Adjoua à 14h32, le serveur dit
/// que la course ne m'est plus attribuée » — sans cette trace, il n'aurait que
/// sa parole, et l'avance qu'il a engagée resterait invisible (SC-016).
class RefusReconciliation {
  /// Crée une ligne de journal.
  const RefusReconciliation({
    required this.uuidClient,
    required this.endpoint,
    required this.motifCle,
    required this.creeLeLocal,
    this.refuseLeLocal,
  });

  /// Identifiant de l'action refusée.
  final String uuidClient;

  /// Endpoint visé — ce que Yao a essayé de faire.
  final String endpoint;

  /// Clé i18n du refus, telle que le serveur l'a rendue.
  final String motifCle;

  /// Quand l'action a été FAITE (heure de l'appareil).
  final DateTime creeLeLocal;

  /// Quand le serveur l'a refusée.
  final DateTime? refuseLeLocal;
}

/// État de la course active : arrêts, client, remise, indicateur hors-ligne.
class EtatCourse {
  /// Crée l'état.
  const EtatCourse({
    this.arrets = const [],
    this.horsLigne = false,
    this.livraisonId,
    this.commandeId,
    this.etat = '',
    this.devise = 'XOF',
    this.client = const ClientCourseVue(),
    this.remise = const RemiseVue(),
    this.actionsEnAttente = 0,
    this.octetsPhotosEnAttente = 0,
    this.refus = const [],
  });

  /// Arrêts de la course, dans l'ordre.
  final List<ArretCourse> arrets;

  /// Vrai si le dernier chargement/collecte s'est fait sans réseau.
  final bool horsLigne;

  /// Livraison active — `null` si aucune course.
  final String? livraisonId;

  /// Commande portée.
  final String? commandeId;

  /// État serveur de la livraison.
  final String etat;

  /// Devise ISO 4217.
  final String devise;

  /// Le client et son repère.
  final ClientCourseVue client;

  /// De quoi confirmer la remise.
  final RemiseVue remise;

  /// Actions encore en file (FR-083).
  final int actionsEnAttente;

  /// Octets de photo restant à transmettre (FR-083).
  final int octetsPhotosEnAttente;

  /// Actions refusées définitivement au rejeu, la plus récente d'abord (FR-086).
  final List<RefusReconciliation> refus;

  /// Une course est-elle en cours ?
  bool get aUneCourse => livraisonId != null;

  /// Prochain arrêt à collecter, ou `null` si tout est collecté.
  ArretCourse? get arretCourant {
    for (final a in arrets) {
      if (!a.collecte && a.statut != 'indisponible') return a;
    }
    return null;
  }

  /// Rang de l'arrêt courant (1-based) — le « Arrêt 1 / 3 » de K3.
  int get rangArretCourant {
    final courant = arretCourant;
    if (courant == null) return arrets.length;
    return arrets.indexWhere((a) => a.arretId == courant.arretId) + 1;
  }

  /// Tous les arrêts sont résolus (bascule EN_LIVRAISON perçue).
  bool get toutCollecte =>
      arrets.isNotEmpty &&
      arrets.every((a) => a.collecte || a.statut == 'indisponible');

  /// Total à encaisser chez le client — vient du SERVEUR, jamais recalculé
  /// localement : il inclut les frais de livraison, que l'app ne connaît pas.
  int get montantAEncaisserUnites => remise.montantAEncaisserUnites;

  /// Copie avec substitution.
  EtatCourse copieAvec({
    List<ArretCourse>? arrets,
    bool? horsLigne,
    String? livraisonId,
    String? commandeId,
    String? etat,
    String? devise,
    ClientCourseVue? client,
    RemiseVue? remise,
    int? actionsEnAttente,
    int? octetsPhotosEnAttente,
    List<RefusReconciliation>? refus,
  }) =>
      EtatCourse(
        arrets: arrets ?? this.arrets,
        horsLigne: horsLigne ?? this.horsLigne,
        livraisonId: livraisonId ?? this.livraisonId,
        commandeId: commandeId ?? this.commandeId,
        etat: etat ?? this.etat,
        devise: devise ?? this.devise,
        client: client ?? this.client,
        remise: remise ?? this.remise,
        actionsEnAttente: actionsEnAttente ?? this.actionsEnAttente,
        octetsPhotosEnAttente:
            octetsPhotosEnAttente ?? this.octetsPhotosEnAttente,
        refus: refus ?? this.refus,
      );
}

/// Course active du coursier (chargement /courses/active + collecte offline-first).
///
/// `AsyncNotifier` (moule des listes, constitution XII). Charge le
/// pré-provisionnement, le met en cache drift (validation hors-ligne), et
/// applique la coche optimiste avant réconciliation serveur.
@riverpod
class EtatCourseActive extends _$EtatCourseActive {
  static const _uuid = Uuid();

  /// Délai avant de retenter un drain qui a échoué sur le réseau.
  ///
  /// Court, parce que Yao attend devant le client ; pas trop, parce qu'un
  /// réseau de marché revient par à-coups et qu'une rafale de tentatives ne
  /// ferait que vider la batterie.
  static const _delaiReprise = Duration(seconds: 5);

  /// Minuteur de reprise en cours, ou `null`.
  Timer? _reprise;

  @override
  Future<EtatCourse> build() async {
    // Session fermée ⇒ provider invalidé ⇒ état vide (patron etat_roles).
    ref.watch(sessionProvider.select((e) => e.connecte));
    final file = ref.read(fileActionsProvider);
    final dio = ref.read(clientSessionProvider).dio;

    // Auto-synchro (V) : au RETOUR du réseau (transition offline→online
    // seulement, via le flux `.distinct()`), on se ré-invalide → build() draine
    // la file puis rafraîchit. `ref.listen` (et non `watch`) : la course ne se
    // reconstruit PAS à chaque événement de connectivité, seulement quand on
    // repasse en ligne. Idempotent (uuid_client) : un drain concurrent ne double
    // rien.
    ref.listen(connectiviteEnLigneProvider, (precedent, actuel) {
      if (actuel.value == true) ref.invalidateSelf();
    });

    // Et si le drain échoue quand même, il se reprogramme (voir `_drainerFile`).
    // Le minuteur meurt avec la portée : un provider disposé ne réveille pas un
    // état qui n'existe plus (constitution XII).
    ref.onDispose(() {
      _reprise?.cancel();
      _reprise = null;
    });

    // 1. Draine la file d'actions en attente AVANT de recharger (réconciliation
    //    serveur — le rejeu idempotent fait foi une seule fois).
    await _drainerFile(file, dio);

    // 2. Recharge la course active (post-drain).
    try {
      final reponse =
          await ref.read(clientSessionProvider).getCoursierApi().courseActive();
      final course = reponse.data;
      if (course == null) {
        // `204` — aucune course. La précédente est effacée, NUMÉROS COMPRIS
        // (R6, FR-034) : une course finie ne laisse pas le téléphone du client
        // sur l'appareil.
        final derniere = await file.courseCache();
        if (derniere != null) {
          await file.effacerCourse(derniere.livraisonId);
          // La note vocale part avec le reste : c'est la voix du client, elle
          // n'a rien à faire sur l'appareil une fois la course finie.
          await const NotesVocalesLocales().effacer(derniere.livraisonId);
        }
        return const EtatCourse();
      }
      await _mettreEnCache(file, course);
      return _depuisCache(file);
    } on DioException {
      // Réseau coupé : on sert le cache pré-provisionné (offline-first, V).
      final etat = await _depuisCache(file);
      return etat.copieAvec(horsLigne: true);
    }
  }

  /// Écrit la course reçue dans le cache local, coches optimistes PRÉSERVÉES.
  ///
  /// Deux préservations, pour deux raisons différentes :
  ///
  /// - les arrêts encore EN ATTENTE de synchro gardent leur coche, sinon le
  ///   rechargement les remettrait « à collecter » et Yao re-scannerait (perte
  ///   silencieuse corrigée au cycle 006) ;
  /// - les coches d'ARTICLES sont préservées par `remplacerChecklist` : elles
  ///   ne sont jamais envoyées au serveur, donc rien ne les rendrait.
  Future<void> _mettreEnCache(FileActions file, CourseActiveComplete c) async {
    final enAttente = <String>{
      for (final a in await file.enAttente()) _arretDeEndpoint(a.endpoint),
    };

    // La note vocale est rapatriée MAINTENANT — pendant qu'il y a du réseau,
    // pas devant le portail (FR-024). L'URL présignée expire en dix minutes ;
    // le fichier local, lui, se joue en mode avion (SC-012).
    final noteVocale = await const NotesVocalesLocales().rapatrier(
      url: c.client.repereVocalUrl,
      cle: c.livraisonId,
      dio: ref.read(clientSessionProvider).dio,
    );

    await file.remplacerCourse(
      CourseCacheTableCompanion.insert(
        livraisonId: c.livraisonId,
        commandeId: c.commandeId,
        etat: c.etat,
        majLeLocal: DateTime.now(),
        devise: Value(c.devise),
        clientNomUsage: Value(c.client.nomUsage ?? ''),
        clientTelephone: Value(c.client.telephone),
        repereTexte: Value(c.client.repereTexte),
        repereVocalFichier: Value(noteVocale),
        repereVocalDureeS: Value(c.client.repereVocalDureeS),
        lieuLat: Value(c.client.lieuLat),
        lieuLon: Value(c.client.lieuLon),
        depotAutorise: Value(c.client.depotAutorise),
        empreinteCode: Value(c.remise.empreinteCode),
        empreinteJeton: Value(c.remise.empreinteJeton),
        essaisConsommes: Value(c.remise.essaisConsommes),
        essaisMax: Value(c.remise.essaisMax),
        codeBloque: Value(c.remise.codeBloque),
        montantAEncaisserUnites: Value(c.remise.montantAEncaisserUnites),
        modePaiement: Value(c.remise.modePaiement),
        seuilsPreuvesJson: Value(jsonEncode({
          'appels_min': c.remise.preuves.appelsMin,
          'espacement_s': c.remise.preuves.espacementS,
          'presence_s': c.remise.preuves.presenceS,
          'rayon_m': c.remise.preuves.rayonM,
          'photos_min': c.remise.preuves.photosMin,
        })),
        arretRemiseId: Value(c.remise.arretRemiseId),
        arretRemiseStatut: Value(c.remise.arretRemiseStatut),
        arriveChezClientLe: Value(c.remise.arriveChezClientLe),
      ),
    );

    await file.remplacerCache([
      for (final a in c.arrets)
        ArretsPreprovisionnesCompanion.insert(
          arretId: a.arretId,
          prestataireId: a.prestataireId,
          nom: Value(a.nom),
          empreinteJeton: a.empreinteJeton,
          empreinteCode: a.empreinteCode,
          siteLat: a.siteLat,
          siteLon: a.siteLon,
          montantAvance: a.montantAvance,
          devise: c.devise,
          photoExigee: a.photoExigee,
          distanceMaxM: Value(a.distanceMaxM),
          statutLocal: Value(a.statut == 'collecte' ? 'collecte' : 'a_collecter'),
        ),
    ]);

    final lignes = <LignesChecklistCompanion>[];
    var ordre = 0;
    for (final a in c.arrets) {
      for (final l in a.lignes) {
        lignes.add(LignesChecklistCompanion.insert(
          ligneId: l.ligneId,
          arretId: a.arretId,
          libelle: l.libelle,
          quantite: Value(l.quantite),
          prixUnitaireUnites: Value(l.prixUnitaireUnites),
          preference: Value(l.preferenceSubstitution),
          statut: Value(l.statut),
          ordre: Value(ordre++),
        ));
      }
    }
    await file.remplacerChecklist(lignes);

    for (final id in enAttente) {
      await file.cocherOptimiste(id);
    }
  }

  /// Rejoue la file d'actions hors-ligne (multipart idempotent), dans l'ordre
  /// de création strict (FR-087).
  ///
  /// **Trois issues, et elles ne se ressemblent pas** (FR-085) :
  ///
  /// - succès ou rejeu idempotent → l'action sort de la file, définitivement ;
  /// - **réseau** toujours coupé → l'action RESTE, son compteur de tentatives
  ///   monte, et on s'arrête là : insister sur les suivantes ne ferait
  ///   qu'allonger un échec déjà connu, et casserait l'ordre de rejeu ;
  /// - **refus métier** → l'action ne réussira JAMAIS (la course a été
  ///   réassignée, l'arrêt est déjà collecté). Elle quitte la file mais garde
  ///   sa trace : derrière une collecte refusée, il y a une avance que Yao a
  ///   réellement engagée, et il doit pouvoir en parler à l'exploitation
  ///   (FR-086, SC-016).
  ///
  /// La coche optimiste est retirée dans le second cas seulement : l'arrêt
  /// redevient « à collecter » et l'écran cesse de mentir (SC-008).
  Future<void> _drainerFile(FileActions file, Dio dio) async {
    for (final action in await file.enAttente()) {
      try {
        // JSON ou multipart selon ce que l'endpoint attend (mémorisé à
        // l'enfilement) : les transitions d'arrêt sont du JSON, et leur envoyer
        // un multipart les faisait toutes échouer au drain.
        final corpsEnvoye = action.multipart
            ? FormData.fromMap({
                'demande': action.payloadJson,
                if (action.photoOctets != null)
                  'photo': MultipartFile.fromBytes(action.photoOctets!,
                      filename: 'photo.jpg'),
              })
            : jsonDecode(action.payloadJson);
        await dio.post<dynamic>(action.endpoint, data: corpsEnvoye);
        await file.retirer(action.uuidClient);
      } on DioException catch (e) {
        if (e.response == null) {
          await file.marquerEchec(action.uuidClient, 'reseau');
          // Réseau toujours coupé : on arrête là, et on REPROGRAMME.
          //
          // Sans cette reprise, un seul drain manqué gelait la file jusqu'au
          // prochain cycle de connectivité : `connectivity_plus` annonce le
          // réseau quelques centaines de millisecondes avant qu'il ne porte
          // vraiment, l'envoi partait trop tôt, échouait — et plus rien ne le
          // relançait. T087 a mesuré cinq minutes d'attente avec trois actions
          // en vol, dont une remise. Il a fallu couper puis rétablir le réseau
          // une seconde fois pour que la course se termine.
          _reprogrammerDrain();
          return;
        }
        // Refus métier réconcilié : l'arrêt reste à collecter, et le motif du
        // serveur — sa clé i18n — devient la ligne du journal.
        final corps = e.response?.data;
        final motif = (corps is Map && corps['code'] is String)
            ? corps['code'] as String
            : 'erreur_interne';
        await file.decocherOptimiste(_arretDeEndpoint(action.endpoint));
        await file.marquerRefusDefinitif(action.uuidClient, motif);
      }
    }
  }

  /// Réarme un drain après un échec réseau, une seule fois à la fois.
  ///
  /// Le minuteur est annulé à la disposition de la portée (constitution XII) :
  /// un provider mort ne doit pas réveiller un état qui n'existe plus.
  void _reprogrammerDrain() {
    if (_reprise != null) return;
    _reprise = Timer(_delaiReprise, () {
      _reprise = null;
      ref.invalidateSelf();
    });
  }

  /// Extrait l'`arret_id` d'un endpoint `/courses/arrets/{id}/collecte`.
  String _arretDeEndpoint(String endpoint) {
    final segments = endpoint.split('/');
    return segments.length > 3 ? segments[3] : '';
  }

  /// Arrêt courant depuis l'état chargé, ou `null`.
  ArretCourse? _arretCache(String arretId) {
    for (final a in state.value?.arrets ?? const <ArretCourse>[]) {
      if (a.arretId == arretId) return a;
    }
    return null;
  }

  /// Validation HORS-LIGNE (R6) contre les empreintes pré-provisionnées : même
  /// ordre que le serveur (proximité, puis correspondance). Renvoie une clé
  /// d'erreur i18n, ou `null` si la collecte peut être enfilée.
  String? _validerOffline(
    ArretCourse arret,
    ModeScan mode,
    String? jeton,
    String? code,
    double lat,
    double lon,
  ) {
    // Proximité grand-cercle vs rayon caché.
    if (_distanceM(lat, lon, arret.siteLat, arret.siteLon) > arret.distanceMaxM) {
      return 'hors_zone';
    }
    if (mode == ModeScan.scanQr) {
      // base16(sha256(jeton)) == empreinte pré-provisionnée ?
      if (jeton == null || _hex(sha256.convert(utf8.encode(jeton)).bytes) != arret.empreinteJeton) {
        return 'plaque_invalide';
      }
    } else {
      // base16(sha256(prestataire_id ‖ code)) — sel = 16 octets de l'UUID.
      if (code == null) return 'code_incorrect';
      final sel = UuidValue.fromString(arret.prestataireId).toBytes();
      final empreinte = _hex(sha256.convert([...sel, ...utf8.encode(code)]).bytes);
      if (empreinte != arret.empreinteCode) return 'code_incorrect';
    }
    return null;
  }

  /// Distance grand-cercle (haversine) en mètres — miroir de `verification.rs`.
  double _distanceM(double lat1, double lon1, double lat2, double lon2) {
    const rayonTerreM = 6371000.0;
    final p1 = lat1 * math.pi / 180, p2 = lat2 * math.pi / 180;
    final dPhi = (lat2 - lat1) * math.pi / 180;
    final dLambda = (lon2 - lon1) * math.pi / 180;
    final a = math.pow(math.sin(dPhi / 2), 2) +
        math.cos(p1) * math.cos(p2) * math.pow(math.sin(dLambda / 2), 2);
    return 2 * rayonTerreM * math.asin(math.sqrt(a.toDouble()));
  }

  /// Hexadécimal base16 minuscule (format des empreintes serveur).
  String _hex(List<int> octets) =>
      octets.map((o) => o.toRadixString(16).padLeft(2, '0')).join();

  /// Reconstitue l'état depuis le cache drift (coches optimistes comprises).
  ///
  /// **Tout se lit d'ici**, y compris en ligne : le cache est la seule vérité
  /// que l'écran consulte, et c'est ce qui rend le passage hors ligne
  /// invisible — il n'y a pas deux chemins de rendu à garder d'accord.
  Future<EtatCourse> _depuisCache(FileActions file, {bool horsLigne = false}) async {
    final arretsCache = await file.arretsCache();
    final checklist = await file.lignesChecklist();
    final course = await file.courseCache();
    final enAttente = await file.enAttente();
    final refuses = await file.refusDefinitifs();

    final parArret = <String, List<LigneChecklistVue>>{};
    for (final l in checklist) {
      parArret.putIfAbsent(l.arretId, () => []).add(LigneChecklistVue(
            ligneId: l.ligneId,
            libelle: l.libelle,
            quantite: l.quantite,
            prixUnitaireUnites: l.prixUnitaireUnites,
            preference: l.preference,
            statut: l.statut,
            cochee: l.cochee,
          ));
    }

    return EtatCourse(
      horsLigne: horsLigne,
      livraisonId: course?.livraisonId,
      commandeId: course?.commandeId,
      etat: course?.etat ?? '',
      devise: course?.devise ?? 'XOF',
      actionsEnAttente: enAttente.length,
      octetsPhotosEnAttente:
          enAttente.fold<int>(0, (n, a) => n + (a.photoOctets?.length ?? 0)),
      refus: [
        for (final r in refuses)
          RefusReconciliation(
            uuidClient: r.uuidClient,
            endpoint: r.endpoint,
            motifCle: r.dernierMotif ?? 'erreur_interne',
            creeLeLocal: r.creeLeLocal,
            refuseLeLocal: r.refuseLeLocal,
          ),
      ],
      client: ClientCourseVue(
        nomUsage: (course?.clientNomUsage ?? '').isEmpty
            ? null
            : course!.clientNomUsage,
        telephone: course?.clientTelephone,
        repereTexte: course?.repereTexte,
        repereVocalFichier: course?.repereVocalFichier,
        repereVocalDureeS: course?.repereVocalDureeS,
        lieuLat: course?.lieuLat,
        lieuLon: course?.lieuLon,
        depotAutorise: course?.depotAutorise ?? false,
      ),
      remise: RemiseVue(
        empreinteCode: course?.empreinteCode ?? '',
        empreinteJeton: course?.empreinteJeton ?? '',
        essaisConsommes: course?.essaisConsommes ?? 0,
        essaisMax: course?.essaisMax ?? 3,
        codeBloque: course?.codeBloque ?? false,
        montantAEncaisserUnites: course?.montantAEncaisserUnites ?? 0,
        modePaiement: course?.modePaiement ?? 'cash',
        preuves: SeuilsPreuvesVue.depuisJson(course?.seuilsPreuvesJson),
        arretRemiseId: course?.arretRemiseId,
        arretRemiseStatut: course?.arretRemiseStatut,
        arriveChezClientLe: course?.arriveChezClientLe,
        valideeLocalementLe: course?.remiseValideeLocalementLe,
      ),
      arrets: [
        for (final l in arretsCache)
          ArretCourse(
            arretId: l.arretId,
            prestataireId: l.prestataireId,
            nom: l.nom,
            empreinteJeton: l.empreinteJeton,
            empreinteCode: l.empreinteCode,
            siteLat: l.siteLat,
            siteLon: l.siteLon,
            montantAvance: l.montantAvance,
            devise: l.devise,
            photoExigee: l.photoExigee,
            distanceMaxM: l.distanceMaxM,
            collecte: l.statutLocal == 'collecte',
            statut: l.statutLocal,
            lignes: parArret[l.arretId] ?? const [],
          ),
      ],
    );
  }

  /// Coche (ou décoche) un article de la checklist — **strictement local**
  /// (R11, FR-079). Aucun appel réseau, aucune entrée dans la file.
  Future<void> cocherArticle(String ligneId, {required bool cochee}) async {
    await ref.read(fileActionsProvider).cocherLigne(ligneId, cochee: cochee);
    ref.invalidateSelf();
  }

  /// Envoie une action de course, ou l'enfile si le réseau manque.
  ///
  /// Le patron unique de TOUTES les actions du cycle (constitution V) : un
  /// `uuid_client`, un passage par la file en cas de coupure, un rejeu
  /// idempotent. Renvoie `null` en cas de succès ou de mise en file, sinon la
  /// clé i18n du refus métier.
  Future<String?> _envoyerOuEnfiler({
    required String endpoint,
    required Map<String, dynamic> payload,
    List<int>? photo,
    bool multipart = true,
  }) async {
    final file = ref.read(fileActionsProvider);
    try {
      final dio = ref.read(clientSessionProvider).dio;
      final corps = multipart
          ? FormData.fromMap({
              'demande': jsonEncode(payload),
              if (photo != null)
                'photo': MultipartFile.fromBytes(photo, filename: 'photo.jpg'),
            })
          : payload;
      await dio.post<dynamic>(endpoint, data: corps);
      ref.invalidateSelf();
      return null;
    } on DioException catch (e) {
      final reponse = e.response;
      if (reponse == null) {
        // Réseau coupé : l'action part dans la file et se rejouera. Yao ne doit
        // jamais rester bloqué devant un vendeur parce que le réseau a sauté.
        await file.enfiler(
          uuidClient: payload['uuid_client'] as String,
          endpoint: endpoint,
          payloadJson: jsonEncode(payload),
          photoOctets: photo,
          creeLeLocal: DateTime.now(),
          multipart: multipart,
        );
        ref.invalidateSelf();
        return null;
      }
      final corps = reponse.data;
      if (corps is Map && corps['code'] is String) return corps['code'] as String;
      return 'erreur_interne';
    }
  }

  /// Transition déclarative d'un arrêt : « je pars » / « je suis arrivé »
  /// (FR-020). Un tap, un `uuid_client`, la file en secours.
  ///
  /// L'horodatage local part avec, mais c'est le SERVEUR qui fait foi :
  /// `arrive_le` fonde une prime d'attente (TRF-06), et une horloge d'appareil
  /// se règle à la main.
  Future<String?> transitionArret({
    required String livraisonId,
    required String arretId,
    required String action,
  }) {
    return _envoyerOuEnfiler(
      endpoint: '/courses/$livraisonId/arrets/$arretId/$action',
      payload: {
        'uuid_client': _uuid.v7(),
        'horodatage_local': DateTime.now().toUtc().toIso8601String(),
      },
      // Les trois transitions déclaratives attendent du JSON : aucune ne porte
      // de photo, et le contrat du cycle 008 est inchangé.
      multipart: false,
    );
  }

  /// Déclare une LIGNE indisponible (FR-016, FR-017) — chemin de substitution
  /// existant, aucune modification serveur.
  ///
  /// `resolution` absente = suivre la préférence du client, dont le défaut sûr
  /// est le retrait : on ne fait jamais payer par défaut.
  Future<String?> declarerLigneIndisponible({
    required String livraisonId,
    required String ligneId,
    String? resolution,
    String? articleProposeId,
    int? prixProposeUnites,
    List<int>? photo,
  }) {
    return _envoyerOuEnfiler(
      endpoint: '/courses/$livraisonId/substitutions',
      payload: {
        'ligne_id': ligneId,
        'uuid_client': _uuid.v7(),
        // `?` plutôt qu'un `if` : la clé disparaît quand la valeur est nulle,
        // et une `resolution: null` explicite serait lue par le serveur comme
        // un choix — alors que son absence signifie « suivre la préférence du
        // client », dont le défaut sûr est le retrait.
        'resolution': ?resolution,
        'article_propose_id': ?articleProposeId,
        'prix_propose_unites': ?prixProposeUnites,
      },
      photo: photo,
    );
  }

  /// Journalise un appel passé via l'app (FR-030 → FR-033) et rend son
  /// `uuid_client`, avec lequel l'issue sera déclarée au retour.
  ///
  /// **Aucun numéro ne part au serveur** : il ne voit pas l'appel, il en garde
  /// l'intention, la direction et le motif (R6).
  ///
  /// Comme toute action du cycle, elle passe par la file si le réseau manque —
  /// un appel passé sous un pont compte autant qu'un autre pour la preuve.
  Future<String> journaliserAppel({
    required String livraisonId,
    required String vers,
    required String motif,
    String? prestataireId,
  }) async {
    final uuidClient = _uuid.v7();
    await _envoyerOuEnfiler(
      endpoint: '/courses/$livraisonId/appels',
      payload: {
        'uuid_client': uuidClient,
        'vers': vers,
        'motif': motif,
        'prestataire_id': ?prestataireId,
        'passe_le_local': DateTime.now().toUtc().toIso8601String(),
      },
      multipart: false,
    );
    return uuidClient;
  }

  /// Déclare l'issue d'un appel au RETOUR (R19). Réseau seulement : une issue
  /// est une observation, pas un fait métier — la perdre ne coûte qu'un
  /// affichage, et l'enfiler encombrerait la file pour rien.
  Future<void> declarerIssueAppel({
    required String livraisonId,
    required String uuidClient,
    required String issue,
  }) async {
    try {
      await ref.read(clientSessionProvider).dio.patch<dynamic>(
        '/courses/$livraisonId/appels',
        data: {'uuid_client': uuidClient, 'issue': issue},
      );
      ref.invalidateSelf();
    } on DioException {
      // Sans réseau, l'issue reste `inconnue` côté serveur. Ce n'est pas une
      // perte : elle n'est JAMAIS un critère de preuve (R19).
    }
  }

  /// Déclare un ARRÊT ENTIER impossible (FR-018) — vendeur fermé, plus rien en
  /// stock. Le montant de l'arrêt tombe à zéro et la course passe au suivant.
  Future<String?> declarerArretIndisponible({
    required String livraisonId,
    required String arretId,
    required String motif,
  }) {
    return _envoyerOuEnfiler(
      endpoint: '/courses/$livraisonId/arrets/$arretId/indisponible',
      payload: {
        'uuid_client': _uuid.v7(),
        'horodatage_local': DateTime.now().toUtc().toIso8601String(),
        'motif': motif,
      },
      multipart: false,
    );
  }

  /// Collecte un arrêt. En ligne : POST multipart immédiat. Hors-ligne (échec
  /// réseau) : coche optimiste + mise en file idempotente (V). Renvoie `null`
  /// en cas de succès/offline, ou une clé d'erreur métier i18n à afficher.
  Future<String?> collecter({
    required String arretId,
    required ModeScan mode,
    String? jeton,
    String? code,
    required double positionLat,
    required double positionLon,
    List<int>? photo,
  }) async {
    final file = ref.read(fileActionsProvider);
    final uuidClient = _uuid.v7();
    final payload = <String, dynamic>{
      'mode': mode == ModeScan.scanQr ? 'scan_qr' : 'code_secours',
      'jeton': jeton,
      'code': code,
      'position_lat': positionLat,
      'position_lon': positionLon,
      'uuid_client': uuidClient,
      'horodatage_local': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final form = FormData.fromMap({
        'demande': jsonEncode(payload),
        if (photo != null)
          'photo': MultipartFile.fromBytes(photo, filename: '$arretId.jpg'),
      });
      final dio = ref.read(clientSessionProvider).dio;
      await dio.post<dynamic>('/courses/arrets/$arretId/collecte', data: form);
      await file.cocherOptimiste(arretId);
      ref.invalidateSelf();
      return null;
    } on DioException catch (e) {
      final reponse = e.response;
      if (reponse == null) {
        // Réseau coupé : on VALIDE d'abord hors-ligne (empreinte + proximité,
        // R6) contre le cache pré-provisionné — on n'enfile pas une action
        // vouée à l'échec, et le coursier a un retour immédiat.
        final arret = _arretCache(arretId);
        if (arret != null) {
          final refus = _validerOffline(arret, mode, jeton, code, positionLat, positionLon);
          if (refus != null) return refus;
        }
        // Validée localement : coche optimiste + file idempotente.
        await file.enfiler(
          uuidClient: uuidClient,
          endpoint: '/courses/arrets/$arretId/collecte',
          payloadJson: jsonEncode(payload),
          photoOctets: photo,
          creeLeLocal: DateTime.now(),
        );
        await file.cocherOptimiste(arretId);
        ref.invalidateSelf();
        return null;
      }
      // Refus métier : renvoie le `message_cle` serveur (clé i18n).
      final corps = reponse.data;
      if (corps is Map && corps['code'] is String) return corps['code'] as String;
      return 'erreur_interne';
    }
  }
}
