import 'dart:convert';

import 'package:dio/dio.dart';
// `KeepAliveLink` vit dans `misc.dart` depuis Riverpod 3 : la durée de vie
// explicite de ce provider (R15) l'exige nommément.
import 'package:flutter_riverpod/misc.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../course/etat_course.dart';
import 'verificateur_empreinte.dart';

part 'etat_remise.g.dart';

/// Voie de confirmation choisie par le coursier (K4-1a, hiérarchisées).
enum VoieRemise {
  /// Scan du QR de réception du client — l'action **principale** (aléa long).
  qr,

  /// Code à 4 chiffres dicté par le client — voie secondaire.
  code,

  /// Dépôt convenu, photographié et géolocalisé — lien discret, et seulement
  /// si l'exploitation a ouvert le drapeau sur cette commande (FR-039).
  depot,
}

/// Ce que l'écran de confirmation doit savoir à tout instant.
///
/// **Un processus, pas une vue** : les essais consommés et le blocage ne
/// doivent pas se réinitialiser parce que l'écran s'est reconstruit. D'où le
/// moule `Notifier` et une durée de vie explicitement liée à la course (R15).
class EtatRemise {
  /// Crée l'état de remise.
  const EtatRemise({
    this.voie = VoieRemise.qr,
    this.essaisHorsLigne = 0,
    this.essaisServeur = 0,
    this.essaisMax = 3,
    this.bloqueServeur = false,
    this.confirmee = false,
    this.validationLocale = false,
    this.erreurCle,
  });

  /// Voie actuellement choisie.
  final VoieRemise voie;

  /// Essais faux consommés **sans réseau**, comptés localement (R5).
  final int essaisHorsLigne;

  /// Essais faux déjà connus du serveur au dernier chargement.
  final int essaisServeur;

  /// Seuil de zone (`commande.essais_code_livraison`) — jamais en dur.
  final int essaisMax;

  /// Le serveur a posé le blocage durable (K4-1d).
  final bool bloqueServeur;

  /// La remise a abouti (localement ou côté serveur).
  final bool confirmee;

  /// La confirmation a été validée **hors ligne** : l'écran doit le dire
  /// (FR-041) et ne jamais prétendre que la course est close côté serveur.
  final bool validationLocale;

  /// Clé i18n du dernier refus, ou `null`.
  final String? erreurCle;

  /// Compteur RETENU — le plus élevé des deux, exactement comme le serveur
  /// tranchera au rejeu (FR-045). L'afficher autrement ferait mentir « il reste
  /// N essais ».
  int get essaisRetenus =>
      essaisHorsLigne > essaisServeur ? essaisHorsLigne : essaisServeur;

  /// Essais restants avant blocage — jamais négatif.
  int get essaisRestants {
    final reste = essaisMax - essaisRetenus;
    return reste < 0 ? 0 : reste;
  }

  /// La saisie par code est-elle fermée ?
  ///
  /// ⚠ **Le scan QR, lui, reste ouvert** (FR-043, K4-1d) : le jeton est un aléa
  /// long, le plafond n'a jamais eu à le protéger. Confondre les deux
  /// laisserait un coursier honnête sans aucun moyen de clore une course qu'il
  /// a faite, parce que le client a mal dicté son code trois fois.
  bool get codeBloque => bloqueServeur || essaisRestants == 0;

  /// Copie avec substitution.
  EtatRemise copieAvec({
    VoieRemise? voie,
    int? essaisHorsLigne,
    int? essaisServeur,
    int? essaisMax,
    bool? bloqueServeur,
    bool? confirmee,
    bool? validationLocale,
    String? erreurCle,
    bool effacerErreur = false,
  }) =>
      EtatRemise(
        voie: voie ?? this.voie,
        essaisHorsLigne: essaisHorsLigne ?? this.essaisHorsLigne,
        essaisServeur: essaisServeur ?? this.essaisServeur,
        essaisMax: essaisMax ?? this.essaisMax,
        bloqueServeur: bloqueServeur ?? this.bloqueServeur,
        confirmee: confirmee ?? this.confirmee,
        validationLocale: validationLocale ?? this.validationLocale,
        erreurCle: effacerErreur ? null : (erreurCle ?? this.erreurCle),
      );
}

/// Processus de confirmation de remise (CRS-04, K4).
///
/// `Notifier` et non `AsyncNotifier` : ce n'est pas un chargement de liste,
/// c'est un **processus** (constitution XII, R15).
///
/// **Durée de vie : `keepAlive` PENDANT LA COURSE, pas au-delà.** Un
/// `autoDispose` nu remettrait les essais à zéro à chaque reconstruction de
/// l'écran — le plafond ne protégerait plus rien. Un `keepAlive: true` les
/// garderait après la course, et le coursier suivant hériterait d'un compteur
/// qui n'est pas le sien. D'où le lien explicite, pris à [charger] et relâché à
/// [reinitialiser] : la durée de vie est celle de la remise en cours, et elle
/// est écrite, pas subie.
@riverpod
class EtatRemiseNotifier extends _$EtatRemiseNotifier {
  static const _uuid = Uuid();

  /// `uuid_client` de la remise EN COURS. Stable tant que la remise n'a pas
  /// abouti : c'est ce qui rend le rejeu idempotent (R4). Le régénérer à chaque
  /// tentative produirait autant de clôtures que de rejeux.
  String? _uuidRemise;

  /// Lien qui maintient le provider en vie tant que la remise est en cours.
  KeepAliveLink? _lien;

  @override
  EtatRemise build() {
    // `retry: pasDeRetry` est posé par la PORTÉE (`conteneurMefali`) —
    // constitution XII : aucune portée de cette app ne réessaie toute seule.
    ref.onDispose(() => _lien = null);
    return const EtatRemise();
  }

  /// Recharge les compteurs depuis le cache local et le pré-provisionnement.
  ///
  /// À appeler à l'ouverture de l'écran : le compteur hors ligne survit à un
  /// redémarrage de l'app (il est en base locale), et le compteur serveur vient
  /// du dernier `GET /courses/active`.
  Future<void> charger(String livraisonId) async {
    _lien ??= ref.keepAlive();
    final file = ref.read(fileActionsProvider);
    final essaisLocaux = await file.essaisHorsLigne(livraisonId);
    final course = ref.read(etatCourseActiveProvider).value;
    final remise = course?.remise ?? const RemiseVue();
    state = state.copieAvec(
      essaisHorsLigne: essaisLocaux,
      essaisServeur: remise.essaisConsommes,
      essaisMax: remise.essaisMax,
      bloqueServeur: remise.codeBloque,
      // Le dépôt n'est proposé que si l'exploitation l'a ouvert (FR-039) ; à
      // défaut, la voie principale de la maquette.
      voie: VoieRemise.qr,
      effacerErreur: true,
    );
  }

  /// Remet le processus à neuf — course terminée, ou course suivante.
  ///
  /// Relâche le lien de survie : au-delà de la course, cet état n'a plus de
  /// raison d'occuper la mémoire ni de risquer de contaminer la suivante.
  void reinitialiser() {
    _uuidRemise = null;
    state = const EtatRemise();
    _lien?.close();
    _lien = null;
  }

  /// Choisit une voie. Le dépôt refuse de s'ouvrir si le drapeau de la commande
  /// est fermé : la garde est des deux côtés (FR-048), et proposer une voie que
  /// le serveur refusera fait perdre du temps à Yao devant la porte.
  void choisirVoie(VoieRemise voie) {
    if (voie == VoieRemise.depot) {
      final course = ref.read(etatCourseActiveProvider).value;
      if (!(course?.client.depotAutorise ?? false)) {
        state = state.copieAvec(erreurCle: 'depot_non_autorise');
        return;
      }
    }
    if (voie == VoieRemise.code && state.codeBloque) {
      state = state.copieAvec(erreurCle: 'code_epuise');
      return;
    }
    state = state.copieAvec(voie: voie, effacerErreur: true);
  }

  /// Vérifie un secret **localement** (FR-040), puis confirme.
  ///
  /// Trois issues, et une seule d'entre elles engage quelque chose :
  ///
  /// - secret faux → refus immédiat, compteur local incrémenté s'il s'agit du
  ///   code (le jeton n'a pas de compteur : il ne se devine pas) ;
  /// - secret bon, réseau présent → le serveur revalide et clôt ;
  /// - secret bon, réseau absent → l'action part dans la file avec ses essais,
  ///   l'écran affiche « validation locale — sera synchronisée » (FR-041) et
  ///   Yao peut repartir. **Rien n'est clos** tant que le serveur n'a pas parlé.
  Future<bool> confirmer({
    required String livraisonId,
    required String commandeId,
    String? jeton,
    String? code,
    List<int>? photo,
    double? depotLat,
    double? depotLon,
  }) async {
    final file = ref.read(fileActionsProvider);
    final course = ref.read(etatCourseActiveProvider).value;
    final verificateur = VerificateurEmpreinte(
      commandeId: commandeId,
      empreinteCode: course?.remise.empreinteCode ?? '',
      empreinteJeton: course?.remise.empreinteJeton ?? '',
    );

    switch (state.voie) {
      case VoieRemise.qr:
        if (jeton == null || !verificateur.jetonCorrect(jeton)) {
          state = state.copieAvec(erreurCle: 'remise_incorrecte');
          return false;
        }
      case VoieRemise.code:
        if (state.codeBloque) {
          state = state.copieAvec(erreurCle: 'code_epuise');
          return false;
        }
        if (code == null || !verificateur.codeCorrect(code)) {
          final essais = await file.ajouterEssaiHorsLigne(livraisonId);
          state = state.copieAvec(
            essaisHorsLigne: essais,
            erreurCle: 'remise_incorrecte',
          );
          return false;
        }
      case VoieRemise.depot:
        // FR-048 : « photo sur place ET position ». Le serveur refuse de toute
        // façon, mais le dire ici évite un aller-retour inutile hors ligne.
        if (photo == null || depotLat == null || depotLon == null) {
          state = state.copieAvec(erreurCle: 'depot_preuve_incomplete');
          return false;
        }
    }

    final uuidClient = _uuidRemise ??= _uuid.v7();
    final payload = <String, dynamic>{
      'uuid_client': uuidClient,
      'mode': switch (state.voie) {
        VoieRemise.qr => 'qr',
        VoieRemise.code => 'code',
        VoieRemise.depot => 'depot',
      },
      'jeton': ?jeton,
      'code': ?code,
      'depot_lat': ?depotLat,
      'depot_lon': ?depotLon,
      // Les essais faux comptés sans réseau voyagent AVEC la demande, jamais un
      // par un : le serveur retient `max(serveur, local)` (R5).
      'essais_hors_ligne': state.essaisHorsLigne,
      'confirme_le_local': DateTime.now().toUtc().toIso8601String(),
    };
    final endpoint = '/courses/$livraisonId/remise';

    try {
      final dio = ref.read(clientSessionProvider).dio;
      final form = FormData.fromMap({
        'demande': jsonEncode({...payload, 'hors_ligne': false}),
        if (photo != null)
          'photo': MultipartFile.fromBytes(photo, filename: 'depot.jpg'),
      });
      await dio.post<dynamic>(endpoint, data: form);
      // Le serveur a accusé réception des essais : les garder les ferait
      // compter deux fois à la remise suivante.
      await file.consoliderEssais(livraisonId);
      state = state.copieAvec(confirmee: true, validationLocale: false, effacerErreur: true);
      ref.invalidate(etatCourseActiveProvider);
      return true;
    } on DioException catch (e) {
      final reponse = e.response;
      if (reponse == null) {
        // Réseau coupé. La validation locale a déjà eu lieu : Yao peut repartir,
        // et l'action se rejouera. Le compteur local n'est PAS purgé — il n'est
        // consolidé qu'une fois le serveur informé.
        await file.enfiler(
          uuidClient: uuidClient,
          endpoint: endpoint,
          payloadJson: jsonEncode({...payload, 'hors_ligne': true}),
          photoOctets: photo,
          creeLeLocal: DateTime.now(),
        );
        state = state.copieAvec(
          confirmee: true,
          validationLocale: true,
          effacerErreur: true,
        );
        ref.invalidate(etatCourseActiveProvider);
        return true;
      }
      final corps = reponse.data;
      final cle = (corps is Map && corps['code'] is String)
          ? corps['code'] as String
          : 'erreur_interne';
      state = state.copieAvec(
        erreurCle: cle,
        bloqueServeur: cle == 'code_epuise' ? true : null,
      );
      return false;
    }
  }
}
