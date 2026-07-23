import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
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

/// Un arrêt de la course, fusion de la donnée serveur (pré-provisionnement) et
/// de la coche optimiste locale (drift).
class ArretCourse {
  /// Crée un arrêt de course.
  const ArretCourse({
    required this.arretId,
    required this.prestataireId,
    required this.empreinteJeton,
    required this.empreinteCode,
    required this.siteLat,
    required this.siteLon,
    required this.montantAvance,
    required this.devise,
    required this.photoExigee,
    required this.collecte,
  });

  /// Arrêt à collecter.
  final String arretId;

  /// Prestataire visé.
  final String prestataireId;

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

  /// Coché (serveur ou optimiste local).
  final bool collecte;
}

/// État de la course active : arrêts + indicateur hors-ligne.
class EtatCourse {
  /// Crée l'état.
  const EtatCourse({this.arrets = const [], this.horsLigne = false});

  /// Arrêts de la course, dans l'ordre.
  final List<ArretCourse> arrets;

  /// Vrai si le dernier chargement/collecte s'est fait sans réseau.
  final bool horsLigne;

  /// Prochain arrêt à collecter, ou `null` si tout est collecté.
  ArretCourse? get arretCourant {
    for (final a in arrets) {
      if (!a.collecte) return a;
    }
    return null;
  }

  /// Tous les arrêts sont collectés (bascule EN_LIVRAISON perçue).
  bool get toutCollecte => arrets.isNotEmpty && arrets.every((a) => a.collecte);

  /// Copie avec substitution.
  EtatCourse copieAvec({List<ArretCourse>? arrets, bool? horsLigne}) => EtatCourse(
        arrets: arrets ?? this.arrets,
        horsLigne: horsLigne ?? this.horsLigne,
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

  @override
  Future<EtatCourse> build() async {
    // Session fermée ⇒ provider invalidé ⇒ état vide (patron etat_roles).
    ref.watch(sessionProvider.select((e) => e.connecte));
    final file = ref.read(fileActionsProvider);
    final dio = ref.read(clientSessionProvider).dio;

    // Auto-synchro (V) : au RETOUR du réseau, on se ré-invalide → build() draine
    // la file puis rafraîchit. Idempotent (uuid_client) : un drain concurrent ne
    // double rien.
    final sub = Connectivity().onConnectivityChanged.listen((etats) {
      final enLigne = etats.any((e) => e != ConnectivityResult.none);
      if (enLigne) ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

    // 1. Draine la file d'actions en attente AVANT de recharger (réconciliation
    //    serveur — le rejeu idempotent fait foi une seule fois).
    await _drainerFile(file, dio);

    // 2. Recharge la course active (post-drain).
    try {
      final reponse = await ref.read(clientSessionProvider).getQrApi().courseActive();
      final arrets = reponse.data?.arrets.toList() ?? const <ArretPreProvisionne>[];
      // Arrêts encore EN ATTENTE de synchro = coches optimistes à PRÉSERVER
      // (sinon `remplacerCache` les remettrait « à collecter » et le coursier
      // re-scannerait — perte silencieuse corrigée).
      final enAttente = <String>{
        for (final a in await file.enAttente()) _arretDeEndpoint(a.endpoint),
      };
      await file.remplacerCache([
        for (final a in arrets)
          ArretsPreprovisionnesCompanion.insert(
            arretId: a.arretId,
            prestataireId: a.prestataireId,
            empreinteJeton: a.empreinteJeton,
            empreinteCode: a.empreinteCode,
            siteLat: a.siteLat,
            siteLon: a.siteLon,
            montantAvance: a.montantAvance,
            devise: a.devise,
            photoExigee: a.photoExigee,
          ),
      ]);
      for (final id in enAttente) {
        await file.cocherOptimiste(id);
      }
      return _depuisCache(file);
    } on DioException {
      // Réseau coupé : on sert le cache pré-provisionné (offline-first, V).
      final etat = await _depuisCache(file);
      return etat.copieAvec(horsLigne: true);
    }
  }

  /// Rejoue la file d'actions hors-ligne (multipart idempotent). Succès ou
  /// idempotent → retire ; refus métier DÉFINITIF → réconcilie (décoche + retire,
  /// l'arrêt reste à collecter, SC-008) ; réseau toujours coupé → conserve et
  /// s'arrête (inutile d'insister sur les suivantes).
  Future<void> _drainerFile(FileActions file, Dio dio) async {
    for (final action in await file.enAttente()) {
      try {
        final form = FormData.fromMap({
          'demande': action.payloadJson,
          if (action.photoOctets != null)
            'photo': MultipartFile.fromBytes(action.photoOctets!, filename: 'photo.jpg'),
        });
        await dio.post<dynamic>(action.endpoint, data: form);
        await file.retirer(action.uuidClient);
      } on DioException catch (e) {
        if (e.response == null) {
          await file.marquerEchec(action.uuidClient, 'reseau');
          return; // réseau toujours coupé
        }
        // Refus métier réconcilié : l'arrêt reste à collecter.
        await file.decocherOptimiste(_arretDeEndpoint(action.endpoint));
        await file.retirer(action.uuidClient);
      }
    }
  }

  /// Extrait l'`arret_id` d'un endpoint `/courses/arrets/{id}/collecte`.
  String _arretDeEndpoint(String endpoint) {
    final segments = endpoint.split('/');
    return segments.length > 3 ? segments[3] : '';
  }

  /// Reconstitue l'état depuis le cache drift (coches optimistes comprises).
  Future<EtatCourse> _depuisCache(FileActions file, {bool horsLigne = false}) async {
    final lignes = await file.arretsCache();
    return EtatCourse(
      horsLigne: horsLigne,
      arrets: [
        for (final l in lignes)
          ArretCourse(
            arretId: l.arretId,
            prestataireId: l.prestataireId,
            empreinteJeton: l.empreinteJeton,
            empreinteCode: l.empreinteCode,
            siteLat: l.siteLat,
            siteLon: l.siteLon,
            montantAvance: l.montantAvance,
            devise: l.devise,
            photoExigee: l.photoExigee,
            collecte: l.statutLocal == 'collecte',
          ),
      ],
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
        // Pas de réponse = réseau coupé : coche optimiste + file idempotente.
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
