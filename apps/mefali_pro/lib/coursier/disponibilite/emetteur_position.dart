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

/// Permet à un test d'injecter un flux de positions déterministe.
///
/// `dependencies: []` la déclare **surchargeable par portée** : sans cette
/// déclaration, un `ProviderScope` imbriqué qui la surcharge serait ignoré —
/// Riverpod hébergerait l'émetteur dans le conteneur parent, où l'override
/// n'existe pas, et un test widget ouvrirait le vrai capteur.
@Riverpod(keepAlive: true, dependencies: [])
FluxPositions sourcePositions(Ref ref) => fluxGeolocator;

/// Émetteur de position — **jetable** (`@riverpod` nu, autoDispose) : il ne vit
/// que tant qu'un écran de dispatch l'observe.
///
/// C'est délibérément l'inverse du porteur de disponibilité, qui est
/// `keepAlive` : l'INTENTION d'être en ligne traverse les écrans, la
/// PUBLICATION ne le peut pas (constitution XII, deux moules opposés).
@Riverpod(dependencies: [sourcePositions])
class EmetteurPosition extends _$EmetteurPosition {
  static const _uuid = Uuid();
  StreamSubscription<Position>? _abonnement;

  @override
  int build() {
    // Ne publie que si Yao s'est déclaré en ligne : rien ne sert d'arroser le
    // serveur de positions qu'il répondra `204`.
    final enLigne = ref.watch(disponibiliteProvider.select((e) => e.enLigne));
    final periode = ref.watch(disponibiliteProvider.select((e) => e.periodePositionS));
    if (!enLigne) return 0;

    final source = ref.read(sourcePositionsProvider);
    _abonnement = source(
      LocationSettings(
        accuracy: precisionPosition,
        distanceFilter: filtreDistanceM,
        // La périodicité est un PARAMÈTRE DE ZONE, jamais une constante d'app.
        timeLimit: Duration(seconds: periode * 3),
      ),
    ).listen(_publier);

    ref.onDispose(() {
      _abonnement?.cancel();
      _abonnement = null;
    });
    return 0;
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
