/// Émetteur de position du coursier (DSP-01, FR-001/FR-002).
///
/// Publie la position à la période de zone (`suivi.position_periode_s`, rendue
/// par `GET /moi/disponibilite`) **tant qu'un écran de dispatch est monté** et
/// que Yao est en ligne.
///
/// **Limite assumée et documentée** (research R15) : sans service de premier
/// plan Android, l'app cesse de publier dès qu'elle passe en arrière-plan, et
/// le coursier sort du pool par expiration. C'est **conforme** à DSP-01 — « un
/// coursier muet sort du pool » — et honnête vis-à-vis de Yao, qui voit son
/// bandeau de reconnexion. Le suivi en arrière-plan appartient à CRS, avec sa
/// propre décision de dépendance et sa permission.
///
/// **Aucune dépendance nouvelle** : `geolocator` est déjà dans `mefali_pro`
/// (porte de présence du cycle QRC).
///
/// ⚠ Une position n'entre **pas** dans la file hors-ligne (dérogation déclarée
/// au principe V) : rejouer au retour du réseau une position vieille de dix
/// minutes réinscrirait le coursier au pool avec une localisation fausse, et le
/// dispatch lui offrirait une course à 4 km de là où il est.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'etat_disponibilite.dart';

part 'emetteur_position.g.dart';

/// Distance minimale (mètres) entre deux relevés du flux `geolocator`.
///
/// Filtre de CAPTEUR, pas un seuil métier : il évite les micro-relevés d'un
/// téléphone posé sur une table. La périodicité, elle, vient de la zone.
const int filtreDistanceM = 10;

/// Précision demandée au capteur — `high` suffit pour un rayon de 4 km, et
/// `best` viderait la batterie d'un Android d'entrée de gamme en une matinée.
const LocationAccuracy precisionPosition = LocationAccuracy.high;

/// Source de positions — extraite pour que les tests puissent la remplacer sans
/// capteur ni permission.
typedef FluxPositions = Stream<Position> Function(LocationSettings reglages);

/// La source réelle : le flux du capteur.
Stream<Position> fluxGeolocator(LocationSettings reglages) =>
    Geolocator.getPositionStream(locationSettings: reglages);

/// Demande de permission de position — extraite pour la même raison : un test
/// widget ne doit ouvrir aucun dialogue système.
typedef DemandePermission = Future<bool> Function();

/// La demande réelle, sur le patron du scan de collecte (cycle QRC 006).
///
/// **Sans elle, DSP-01 ne fonctionne pas du tout sur un appareil neuf** : le
/// flux du capteur reste muet, le coursier ne publie jamais et n'entre jamais
/// dans le pool — tout en lisant « en attente de courses ». Défaut trouvé à la
/// validation sur émulateur (T071), après qu'une réinstallation a révoqué la
/// permission accordée à la main.
Future<bool> demanderPermissionGeolocator() async {
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  return perm != LocationPermission.denied &&
      perm != LocationPermission.deniedForever;
}

/// Permet à un test d'injecter un flux de positions déterministe.
///
/// `dependencies: []` la déclare **surchargeable par portée** : sans cette
/// déclaration, un `ProviderScope` imbriqué qui la surcharge serait ignoré —
/// Riverpod hébergerait l'émetteur dans le conteneur parent, où l'override
/// n'existe pas, et un test widget ouvrirait le vrai capteur.
@Riverpod(keepAlive: true, dependencies: [])
FluxPositions sourcePositions(Ref ref) => fluxGeolocator;

/// Relevé PONCTUEL, demandé à la cadence de zone — distinct du flux.
typedef PositionPonctuelle = Future<Position?> Function();

/// Le relevé réel. `null` si le capteur ne répond pas : on ne publie alors
/// rien, et Yao sort du pool — c'est honnête, et son écran le dit.
Future<Position?> positionGeolocator() async {
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: precisionPosition),
    );
  } on Object catch (e) {
    // Un capteur muet n'est pas une panne d'app : on se tait, et le TTL fait
    // sortir du pool.
    debugPrint('position ponctuelle indisponible : $e');
    return null;
  }
}

/// Permet à un test de court-circuiter la demande de permission.
///
/// Même raison que [sourcePositions], et même `dependencies: []` : sans cette
/// déclaration, un `ProviderScope` imbriqué qui la surcharge serait ignoré.
@Riverpod(keepAlive: true, dependencies: [])
DemandePermission permissionPosition(Ref ref) => demanderPermissionGeolocator;

/// Permet à un test de fournir un relevé ponctuel déterministe.
@Riverpod(keepAlive: true, dependencies: [])
PositionPonctuelle relevePonctuel(Ref ref) => positionGeolocator;

/// Émetteur de position — **jetable** (`@riverpod` nu, autoDispose) : il ne vit
/// que tant qu'un écran de dispatch l'observe.
///
/// C'est délibérément l'inverse du porteur de disponibilité, qui est
/// `keepAlive` : l'INTENTION d'être en ligne traverse les écrans, la
/// PUBLICATION ne le peut pas (constitution XII, deux moules opposés).
@Riverpod(dependencies: [sourcePositions, permissionPosition, relevePonctuel])
class EmetteurPosition extends _$EmetteurPosition {
  static const _uuid = Uuid();
  StreamSubscription<Position>? _abonnement;

  /// Horloge de la CADENCE de zone — distincte du capteur.
  Timer? _cadence;

  /// Vrai tant que ce porteur n'a pas été éliminé — garde des reprises `async`.
  ///
  /// ⚠ Réarmé à CHAQUE `build`. `build` est rejoué quand Yao passe en ligne, et
  /// Riverpod exécute les `onDispose` de la construction précédente avant : sans
  /// ce réarmement, le drapeau resterait à `false` et la demande de permission
  /// rendrait la main dans le vide — l'abonnement au capteur ne serait jamais
  /// posé, précisément au passage en ligne.
  bool _vivant = true;

  /// Numéro de la construction en cours — arbitre des démarrages CONCURRENTS.
  ///
  /// `_vivant` ne suffit pas, et c'est subtil : il est réarmé à chaque `build`.
  /// Une bascule en ligne → hors ligne → en ligne assez rapide laisse donc DEUX
  /// `_demarrer` en vol, tous deux suspendus sur la demande de permission, tous
  /// deux se croyant vivants au réveil. Le second écrasait `_abonnement` et
  /// `_cadence` du premier : le `Timer.periodic` remplacé n'était plus annulé
  /// par personne — publication en double et réveil du GPS sur un porteur que
  /// plus rien ne référence.
  int _generation = 0;

  @override
  int build() {
    _vivant = true;
    _generation += 1;
    final generation = _generation;
    // Ne publie que si Yao s'est déclaré en ligne : rien ne sert d'arroser le
    // serveur de positions qu'il répondra `204`.
    final enLigne = ref.watch(disponibiliteProvider.select((e) => e.enLigne));
    final periode = ref.watch(disponibiliteProvider.select((e) => e.periodePositionS));
    ref.onDispose(() {
      _vivant = false;
      _abonnement?.cancel();
      _abonnement = null;
      _cadence?.cancel();
      _cadence = null;
    });
    if (!enLigne) return 0;

    unawaited(_demarrer(periode, generation));
    return 0;
  }

  /// Demande la permission, PUIS s'abonne au capteur et lance la cadence.
  ///
  /// L'ordre compte : `getPositionStream` sur un appareil qui n'a pas accordé la
  /// position reste muet, sans erreur — le coursier n'entrerait jamais dans le
  /// pool tout en lisant « en attente de courses ».
  Future<void> _demarrer(int periode, int generation) async {
    final accordee = await ref.read(permissionPositionProvider)();
    // Périmé : une construction plus récente a pris la main pendant l'attente.
    // Continuer ici écraserait SON abonnement et SA cadence, et laisserait un
    // `Timer.periodic` que plus personne n'annule.
    if (!_vivant || generation != _generation) return;
    if (!accordee) {
      // Rien à publier : le porteur de disponibilité le dira à l'écran, qui
      // n'affiche « en attente de courses » que si le serveur confirme la
      // présence au pool.
      return;
    }

    final source = ref.read(sourcePositionsProvider);
    _abonnement = source(
      LocationSettings(
        accuracy: precisionPosition,
        distanceFilter: filtreDistanceM,
        // La périodicité est un PARAMÈTRE DE ZONE, jamais une constante d'app.
        timeLimit: Duration(seconds: periode * 3),
      ),
    ).listen(_surReleve);

    // ── La CADENCE, et pourquoi elle est indispensable ──────────────────────
    //
    // Le capteur ne parle que si Yao BOUGE (`distanceFilter`). Or le cas
    // nominal de DSP-01 est un coursier ARRÊTÉ : il attend au carrefour, moteur
    // coupé, et son écran dit « en attente de courses ». Sans cette horloge, il
    // ne publie plus rien et sort du pool par expiration du TTL au bout de 90 s
    // — sans que rien ne le lui dise. Il croit travailler ; aucune course ne
    // peut plus lui parvenir.
    //
    // Défaut trouvé à la validation sur émulateur (T071) : le pool était vide
    // pendant que K1 affichait « en attente de courses ».
    //
    // C'est aussi ce que le contrat annonce déjà : `prochaine_publication_s` est
    // une CADENCE, et le serveur la rend à chaque publication.
    _cadence = Timer.periodic(Duration(seconds: periode.clamp(5, 300)), (_) {
      unawaited(_relever());
    });
    // Un premier relevé TOUT DE SUITE : sans lui, un coursier immobile
    // attendrait une cadence entière avant d'entrer dans le pool, et le flux ne
    // dirait rien puisqu'il ne bouge pas.
    unawaited(_relever());
  }

  /// Un relevé du capteur — Yao a bougé : on publie tout de suite.
  void _surReleve(Position position) {
    unawaited(_publier(position));
  }

  /// Relevé de CADENCE : on redemande la position au capteur.
  ///
  /// Redemander plutôt que rejouer la dernière connue, et la raison est de
  /// fond : rejouer une position stockée est un RE-ENVOI, et une position
  /// vieille de dix minutes réinscrirait Yao là où il n'est plus — exactement
  /// ce que la dérogation au principe V refuse pour la file hors-ligne. Un
  /// relevé ponctuel, lui, est toujours vrai à l'instant où il part.
  ///
  /// Et si le capteur ne répond pas, il ne rend rien : on se tait, Yao sort du
  /// pool par expiration, et son écran cesse de dire qu'il attend des courses.
  Future<void> _relever() async {
    final position = await ref.read(relevePonctuelProvider)();
    if (!_vivant || position == null) return;
    await _publier(position);
  }

  Future<void> _publier(Position position) async {
    final dansLePool = await ref.read(disponibiliteProvider.notifier).publierPosition(
          // UUID client par publication (constitution V) : le serveur rejoue
          // sans doubler, et son propre horodatage fait foi.
          uuidClient: _uuid.v7(),
          lat: position.latitude,
          lon: position.longitude,
          precisionM: position.accuracy.round(),
        );
    if (dansLePool) state = state + 1;
  }
}
