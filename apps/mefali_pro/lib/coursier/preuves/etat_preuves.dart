import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../course/etat_course.dart';

part 'etat_preuves.g.dart';

/// État d'une preuve, tel que K4-1e le dessine.
enum EtatPreuve {
  /// Réunie — pastille verte pleine.
  faite,

  /// En progression — pastille orange « … », avec un décompte.
  enCours,

  /// Pas commencée — pastille vide.
  aFaire,
}

/// La preuve « appels » vue par l'app (FR-056).
class PreuveAppelsVue {
  /// Crée la preuve.
  const PreuveAppelsVue({
    this.faits = 0,
    this.requis = 2,
    this.espacementS = 180,
    this.espacementOk = true,
    this.horodatages = const [],
    this.candidats = 0,
  });

  /// Espacement exigé par la zone (s) — affiché tel quel quand deux appels ont
  /// été trop rapprochés. Un nombre écrit en dur ici mentirait dès qu'une zone
  /// règle son seuil autrement.
  final int espacementS;

  /// Appels `client_absent` **retenus** (espacement respecté).
  final int faits;

  /// Appels exigés par la zone.
  final int requis;

  /// Faux dès qu'un appel a été écarté pour cause d'espacement.
  final bool espacementOk;

  /// Horodatages des appels retenus — affichés « 15:02 et 15:06 ».
  final List<DateTime> horodatages;

  /// Appels `client_absent` passés, retenus ou non.
  final int candidats;

  /// Preuve réunie.
  bool get ok => faits >= requis;

  /// L'état de la pastille (K4-1e).
  EtatPreuve get etat => ok
      ? EtatPreuve.faite
      : (candidats > 0 ? EtatPreuve.enCours : EtatPreuve.aFaire);
}

/// La preuve « présence » vue par l'app (FR-056).
class PreuvePresenceVue {
  /// Crée la preuve.
  const PreuvePresenceVue({
    this.secondes = 0,
    this.requis = 600,
    this.gpsIndisponible = false,
    this.horsRayon = false,
    this.distanceM,
  });

  /// Durée retenue (s).
  final int secondes;

  /// Durée exigée.
  final int requis;

  /// Aucun échantillon : GPS coupé ou permission refusée.
  final bool gpsIndisponible;

  /// Des échantillons arrivent, mais tous hors du rayon.
  final bool horsRayon;

  /// Dernière distance mesurée (m), pour dire de combien Yao est trop loin.
  final int? distanceM;

  /// Preuve réunie.
  bool get ok => secondes >= requis;

  /// Minutes restantes, arrondies au supérieur — « encore 4 min ».
  int get minutesRestantes => ok ? 0 : ((requis - secondes) / 60).ceil();

  /// L'état de la pastille.
  EtatPreuve get etat => ok
      ? EtatPreuve.faite
      : (secondes > 0 ? EtatPreuve.enCours : EtatPreuve.aFaire);
}

/// La preuve « photo » vue par l'app (FR-056).
class PreuvePhotosVue {
  /// Crée la preuve.
  const PreuvePhotosVue({this.faites = 0, this.requis = 1});

  /// Photos déposées ou enfilées.
  final int faites;

  /// Photos exigées.
  final int requis;

  /// Preuve réunie.
  bool get ok => faites >= requis;

  /// L'état de la pastille — une photo n'a pas d'état intermédiaire.
  EtatPreuve get etat => ok ? EtatPreuve.faite : EtatPreuve.aFaire;
}

/// L'état des trois preuves, et **ce qui manque** (K4-1e).
///
/// Le serveur calcule exactement la même chose (`GET /preuves`) et **revalide**
/// à la déclaration (FR-060) : cet état est une projection locale, optimiste
/// comme la coche de K3, jamais une décision. C'est ce qui permet à l'écran de
/// fonctionner devant une porte close sans réseau — la situation où la preuve
/// sert précisément le plus.
class EtatPreuvesVue {
  /// Crée l'état.
  const EtatPreuvesVue({
    this.appels = const PreuveAppelsVue(),
    this.presence = const PreuvePresenceVue(),
    this.photos = const PreuvePhotosVue(),
    this.enAttenteDeSynchro = false,
    this.erreurCle,
  });

  /// Preuve « appels ».
  final PreuveAppelsVue appels;

  /// Preuve « présence ».
  final PreuvePresenceVue presence;

  /// Preuve « photo ».
  final PreuvePhotosVue photos;

  /// Des preuves attendent d'être envoyées : l'écran le dit, plutôt que de
  /// laisser croire que le serveur les connaît déjà (FR-041).
  final bool enAttenteDeSynchro;

  /// Clé i18n du dernier refus, ou `null`.
  final String? erreurCle;

  /// Nombre total de preuves — trois, et le compteur de K4-1e le dit.
  static const int total = 3;

  /// Combien sont réunies.
  int get reuniesSur =>
      (appels.ok ? 1 : 0) + (presence.ok ? 1 : 0) + (photos.ok ? 1 : 0);

  /// Les trois sont réunies : le bouton s'active (FR-058).
  bool get reunies => reuniesSur == total;

  /// Copie avec substitution.
  EtatPreuvesVue copieAvec({
    PreuveAppelsVue? appels,
    PreuvePresenceVue? presence,
    PreuvePhotosVue? photos,
    bool? enAttenteDeSynchro,
    String? erreurCle,
    bool effacerErreur = false,
  }) =>
      EtatPreuvesVue(
        appels: appels ?? this.appels,
        presence: presence ?? this.presence,
        photos: photos ?? this.photos,
        enAttenteDeSynchro: enAttenteDeSynchro ?? this.enAttenteDeSynchro,
        erreurCle: effacerErreur ? null : (erreurCle ?? this.erreurCle),
      );
}

/// Retient les appels **suffisamment espacés** — la même règle que le serveur.
///
/// Dupliquée volontairement plutôt que demandée au réseau : sans elle, l'écran
/// afficherait « 2 appels » là où le serveur n'en compte qu'un, et Yao verrait
/// sa déclaration refusée après avoir cru avoir fini. Le serveur reste juge
/// (FR-060) ; l'app, elle, doit dire la vérité tout de suite.
List<DateTime> appelsRetenus(List<DateTime> appels, int espacementS) {
  final tries = [...appels]..sort();
  final retenus = <DateTime>[];
  for (final a in tries) {
    // Compté depuis le dernier RETENU, jamais depuis le dernier appel : sinon
    // une rafale les validerait tous, quelques secondes à la fois.
    if (retenus.isEmpty ||
        a.difference(retenus.last).inSeconds >= espacementS) {
      retenus.add(a);
    }
  }
  return retenus;
}

/// Somme les intervalles de présence, trous exclus — la règle du serveur (R8).
int dureePresence(
  List<({DateTime quand, int distanceM})> releves, {
  required int rayonM,
  required int trouMaxS,
}) {
  final tries = [...releves]..sort((a, b) => a.quand.compareTo(b.quand));
  var total = 0;
  for (var i = 1; i < tries.length; i++) {
    final avant = tries[i - 1];
    final apres = tries[i];
    // Les DEUX bouts doivent être sur place : sinon un aller-retour compterait
    // comme une attente.
    if (avant.distanceM > rayonM || apres.distanceM > rayonM) continue;
    final delta = apres.quand.difference(avant.quand).inSeconds;
    if (delta > 0 && delta <= trouMaxS) total += delta;
  }
  return total;
}

/// Processus des trois preuves d'échec (CRS-05, K4-1e).
///
/// `Notifier` et non `AsyncNotifier` (constitution XII, R15) : ce n'est pas un
/// chargement de liste, c'est un **processus** qui dure — dix minutes d'attente
/// devant une porte, échantillonnées.
///
/// **Durée de vie : `keepAlive` PENDANT LA COURSE.** Un `autoDispose` nu
/// remettrait le décompte à zéro à chaque reconstruction de l'écran, et Yao
/// recommencerait ses dix minutes parce qu'il a regardé sa checklist. Le lien
/// est pris à [charger] et relâché à [reinitialiser] — patron `EtatRemise`.
///
/// ⚠ **Aucune minuterie ici.** Le rafraîchissement d'affichage (« encore 4 min »)
/// est une minuterie **locale au widget** : un `Timer` dans un provider survit à
/// l'écran et fait échouer les tests widget par « a Timer is still pending »
/// (piège du cycle 004). Ce qui vit ici, c'est l'échantillonnage — déclenché,
/// pas cadencé.
@riverpod
class EtatPreuvesNotifier extends _$EtatPreuvesNotifier {
  static const _uuid = Uuid();

  KeepAliveLink? _lien;

  /// Horodatages des appels `client_absent` passés depuis cette course.
  final List<DateTime> _appels = [];

  /// Photos de preuve déposées ou enfilées.
  int _photos = 0;

  /// Instant du dernier échantillon de présence RETENU — garde de cadence
  /// contre le doublon écran-ouvert / écran-éteint (T081).
  DateTime? _dernierEchantillon;

  @override
  EtatPreuvesVue build() {
    ref.onDispose(() => _lien = null);
    return const EtatPreuvesVue();
  }

  /// Ouvre le processus sur une livraison et recalcule tout.
  Future<void> charger(String livraisonId) async {
    _lien ??= ref.keepAlive();
    await _recalculer(livraisonId);
  }

  /// Remet le processus à neuf — course close, ou course suivante.
  void reinitialiser() {
    _appels.clear();
    _photos = 0;
    _dernierEchantillon = null;
    state = const EtatPreuvesVue();
    _lien?.close();
    _lien = null;
  }

  /// Note qu'un appel `client_absent` vient d'être passé (FR-035).
  ///
  /// ⚠ **Ne journalise rien.** La journalisation serveur a UN seul chemin —
  /// `ActionsAppel`, qui enfile l'intention puis compose le numéro puis demande
  /// l'issue au retour (FR-030, R19). Doubler ce chemin ici produirait deux
  /// appels journalisés pour un seul appel passé, et la preuve compterait un
  /// tour d'avance sur la réalité.
  ///
  /// Ce que cette méthode fait, et rien d'autre : tenir le décompte **local**
  /// pour que K4-1e s'actualise tout de suite, y compris sans réseau.
  Future<void> noterAppelClientAbsent(String livraisonId) async {
    _appels.add(DateTime.now());
    await _recalculer(livraisonId);
  }

  /// Prend un échantillon de présence (FR-061, SC-019).
  ///
  /// ⚠ **Une distance, jamais une position** : la position sert au calcul et
  /// n'est jamais envoyée (R8). Une position indisponible n'est pas une erreur —
  /// c'est un motif de non-progression que l'écran doit DIRE, plutôt que de
  /// laisser un compteur figé sans explication.
  ///
  /// **Cadencé, pas seulement déclenché** (T081). Deux sources l'appellent —
  /// l'écran des preuves au premier plan, le service continu écran éteint — et
  /// il existe un instant où les deux tournent : Yao éteint son écran avec
  /// K4-1e ouvert. Deux relevés à quelques secondes d'intervalle ne mesurent
  /// rien de plus, mais doublent le GPS et la file. La garde vit ICI plutôt
  /// qu'au point d'appel : un appelant de plus l'oublierait.
  Future<void> echantillonnerPresence(
    String livraisonId, {
    Future<Position?> Function()? obtenirPosition,
  }) async {
    final depuis = _dernierEchantillon;
    if (depuis != null &&
        DateTime.now().difference(depuis) < _cadenceMinEchantillon) {
      return;
    }
    _dernierEchantillon = DateTime.now();
    final course = ref.read(etatCourseActiveProvider).value;
    final lat = course?.client.lieuLat;
    final lon = course?.client.lieuLon;
    if (lat == null || lon == null) {
      state = state.copieAvec(
        presence: PreuvePresenceVue(
          secondes: state.presence.secondes,
          requis: state.presence.requis,
          gpsIndisponible: true,
        ),
      );
      return;
    }

    final position = await (obtenirPosition ?? _positionCourante)();
    if (position == null) {
      state = state.copieAvec(
        presence: PreuvePresenceVue(
          secondes: state.presence.secondes,
          requis: state.presence.requis,
          gpsIndisponible: true,
        ),
      );
      return;
    }

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lon,
    ).round();

    final file = ref.read(fileActionsProvider);
    await file.enfilerPresence(
      uuidClient: _uuid.v7(),
      livraisonId: livraisonId,
      distanceM: distance,
      releveLeLocal: DateTime.now(),
    );
    await _recalculer(livraisonId);
  }

  /// Dépose une photo de preuve (FR-056).
  ///
  /// Elle voyage **avec** la demande, donc dans la file : une preuve qui
  /// exigerait du réseau au moment de la prise serait une preuve impossible à
  /// réunir là où elle sert.
  Future<void> deposerPhoto(String livraisonId, List<int> octets) async {
    await _enfilerOuEnvoyer(
      endpoint: '/courses/$livraisonId/preuves/photo',
      payload: {'prise_le_local': DateTime.now().toUtc().toIso8601String()},
      photo: octets,
    );
    _photos += 1;
    await _recalculer(livraisonId);
  }

  /// Déclare l'échec — refusé si les trois preuves ne sont pas réunies.
  ///
  /// La garde est locale ET serveur : ici pour ne pas faire perdre de temps à
  /// Yao, là-bas parce que c'est le serveur qui décide (FR-059, FR-060).
  Future<bool> declarerEchec({
    required String livraisonId,
    required String typeIssue,
    required String motifCle,
  }) async {
    if (!state.reunies) {
      state = state.copieAvec(erreurCle: 'preuves_incompletes');
      return false;
    }
    final abouti = await _enfilerOuEnvoyer(
      endpoint: '/courses/$livraisonId/echec',
      payload: {'type_issue': typeIssue, 'motif_cle': motifCle},
    );
    if (abouti) {
      ref.invalidate(etatCourseActiveProvider);
    }
    return abouti;
  }

  /// Recalcule les trois preuves depuis les seuils de zone et l'état local.
  ///
  /// Aucun appel réseau : les seuils sont dans le pré-provisionnement, les
  /// relevés en base locale, les appels en mémoire de processus. C'est ce qui
  /// fait tenir l'écran sans couverture.
  Future<void> _recalculer(String livraisonId) async {
    final course = ref.read(etatCourseActiveProvider).value;
    final seuils = course?.remise.preuves ?? const SeuilsPreuvesVue();
    final file = ref.read(fileActionsProvider);
    final locaux = await file.presenceEnAttente(livraisonId);

    final releves = [
      for (final r in locaux) (quand: r.releveLeLocal, distanceM: r.distanceM),
    ];
    final secondes = dureePresence(
      releves,
      rayonM: seuils.rayonM,
      // Le trou de zone n'est pas servi à l'app (il n'a pas d'usage
      // d'affichage) : le pas d'échantillonnage borne déjà les intervalles, et
      // le serveur tranche. On retient le double de l'espacement des relevés.
      trouMaxS: _trouMaxS,
    );
    final retenus = appelsRetenus(_appels, seuils.espacementS);

    state = state.copieAvec(
      appels: PreuveAppelsVue(
        faits: retenus.length,
        requis: seuils.appelsMin,
        espacementS: seuils.espacementS,
        espacementOk: retenus.length == _appels.length,
        horodatages: retenus,
        candidats: _appels.length,
      ),
      presence: PreuvePresenceVue(
        secondes: secondes,
        requis: seuils.presenceS,
        gpsIndisponible: releves.isEmpty,
        horsRayon: releves.isNotEmpty &&
            !releves.any((r) => r.distanceM <= seuils.rayonM),
        distanceM: releves.isEmpty ? null : releves.last.distanceM,
      ),
      photos: PreuvePhotosVue(faites: _photos, requis: seuils.photosMin),
      enAttenteDeSynchro: locaux.isNotEmpty,
      effacerErreur: true,
    );
  }

  /// Envoie tout de suite si le réseau répond, enfile sinon — jamais d'échec
  /// visible pour Yao à cause du réseau (FR-026).
  Future<bool> _enfilerOuEnvoyer({
    required String endpoint,
    required Map<String, dynamic> payload,
    List<int>? photo,
  }) async {
    final uuidClient = _uuid.v7();
    final corps = {'uuid_client': uuidClient, ...payload};
    final file = ref.read(fileActionsProvider);
    try {
      final dio = ref.read(clientSessionProvider).dio;
      if (photo != null) {
        await dio.post<dynamic>(
          endpoint,
          data: FormData.fromMap({
            'demande': jsonEncode(corps),
            'photo': MultipartFile.fromBytes(photo, filename: 'preuve.jpg'),
          }),
        );
      } else {
        await dio.post<dynamic>(endpoint, data: corps);
      }
      return true;
    } on DioException catch (e) {
      if (e.response == null) {
        await file.enfiler(
          uuidClient: uuidClient,
          endpoint: endpoint,
          payloadJson: jsonEncode(corps),
          photoOctets: photo,
          creeLeLocal: DateTime.now(),
        );
        state = state.copieAvec(enAttenteDeSynchro: true, effacerErreur: true);
        return true;
      }
      final data = e.response?.data;
      state = state.copieAvec(
        erreurCle: (data is Map && data['code'] is String)
            ? data['code'] as String
            : 'erreur_interne',
      );
      return false;
    }
  }

  Future<Position?> _positionCourante() async {
    try {
      return await Geolocator.getCurrentPosition();
    } on Exception {
      // Permission refusée, GPS coupé, capteur muet : tous des motifs de
      // non-progression, aucun une erreur à remonter à l'écran.
      return null;
    }
  }
}

/// Intervalle au-delà duquel deux relevés ne comptent plus comme continus.
///
/// Miroir **local** de `coursier.preuve_presence_trou_max_s` : le serveur ne le
/// sert pas à l'app (il n'a aucun usage d'affichage), et le seul risque d'un
/// écart est un décompte local légèrement optimiste que le serveur corrigera.
const int _trouMaxS = 120;

/// Période d'échantillonnage de la présence, écran allumé comme écran éteint.
///
/// La moitié du trou toléré : chaque intervalle compte alors intégralement,
/// même si un échantillon est perdu.
const Duration periodeEchantillonPresence = Duration(seconds: 60);

/// Écart minimal entre deux échantillons RETENUS.
///
/// La moitié de la période : deux sources peuvent se chevaucher (l'écran des
/// preuves et le service continu, T081), et un relevé de plus toutes les
/// secondes ne mesurerait rien de mieux — il allumerait le GPS deux fois plus
/// souvent sur un téléphone d'entrée de gamme.
const Duration _cadenceMinEchantillon = Duration(seconds: 30);
