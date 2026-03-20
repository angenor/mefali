import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:path_provider/path_provider.dart';

/// Queue locale pour les actions de mission (accept/refuse) en mode offline.
/// Stocke les actions dans un fichier JSON local et synchronise au retour
/// de connexion.
class PendingAcceptQueue {
  PendingAcceptQueue._();
  static final instance = PendingAcceptQueue._();

  static const _fileName = 'pending_accepts.json';

  /// Lock pour serialiser les operations fichier et eviter les races.
  Completer<void>? _ioLock;

  Future<T> _withLock<T>(Future<T> Function() fn) async {
    while (_ioLock != null) {
      await _ioLock!.future;
    }
    _ioLock = Completer<void>();
    try {
      return await fn();
    } finally {
      _ioLock!.complete();
      _ioLock = null;
    }
  }

  /// Ajouter une action en attente de sync.
  /// [action] est 'accept' ou 'refuse'.
  /// [reason] est la raison du refus (obligatoire si action='refuse').
  Future<void> enqueue(
    String deliveryId,
    String orderId, {
    Map<String, dynamic>? missionData,
    String action = 'accept',
    String? reason,
  }) async {
    return _withLock(() async {
      final entries = await _readEntriesUnsafe();
      entries.add({
        'delivery_id': deliveryId,
        'order_id': orderId,
        'action': action,
        'created_at': DateTime.now().toIso8601String(),
        if (reason != null) 'reason': reason,
        if (missionData != null) 'mission_data': missionData,
      });
      await _writeEntriesUnsafe(entries);
      debugPrint('PendingAcceptQueue: queued $action for delivery $deliveryId');
    });
  }

  /// Recuperer toutes les actions en attente.
  Future<List<Map<String, dynamic>>> getPending() async {
    return _withLock(() => _readEntriesUnsafe());
  }

  /// Retirer une action apres sync reussi.
  Future<void> remove(String deliveryId) async {
    return _withLock(() => _removeUnsafe(deliveryId));
  }

  /// Verifier si des actions sont en attente.
  Future<bool> get hasPending async {
    return _withLock(() async {
      final entries = await _readEntriesUnsafe();
      return entries.isNotEmpty;
    });
  }

  /// Synchroniser toutes les actions en attente avec le serveur.
  /// Appellee au retour de connectivite et au demarrage de l'app.
  Future<void> syncPendingActions(Dio dio) async {
    return _withLock(() => _syncUnsafe(dio));
  }

  /// Sync interne (assume que le lock est deja tenu).
  Future<void> _syncUnsafe(Dio dio) async {
    final entries = await _readEntriesUnsafe();
    if (entries.isEmpty) return;

    final endpoint = DeliveryEndpoint(dio);
    final toRemove = <String>[];

    for (final entry in entries) {
      final deliveryId = entry['delivery_id'] as String;
      final action = entry['action'] as String? ?? 'accept';

      try {
        if (action == 'accept') {
          await endpoint.acceptMission(deliveryId);
        } else if (action == 'refuse') {
          final reason = entry['reason'] as String? ?? 'other';
          await endpoint.refuseMission(deliveryId, reason);
        } else if (action == 'confirm_pickup') {
          await endpoint.confirmPickup(deliveryId);
        } else if (action == 'confirm_delivery') {
          final missionData = entry['mission_data'] as Map<String, dynamic>?;
          final lat = (missionData?['lat'] as num?)?.toDouble() ?? 0;
          final lng = (missionData?['lng'] as num?)?.toDouble() ?? 0;
          await endpoint.confirmDelivery(deliveryId, lat, lng);
        } else if (action == 'client_absent') {
          final missionData = entry['mission_data'] as Map<String, dynamic>?;
          final lat = (missionData?['lat'] as num?)?.toDouble() ?? 0;
          final lng = (missionData?['lng'] as num?)?.toDouble() ?? 0;
          await endpoint.reportClientAbsent(deliveryId, lat, lng);
        } else if (action == 'resolve_absent') {
          final missionData = entry['mission_data'] as Map<String, dynamic>?;
          final resolution = missionData?['resolution'] as String? ?? 'returned_to_base';
          final lat = (missionData?['lat'] as num?)?.toDouble() ?? 0;
          final lng = (missionData?['lng'] as num?)?.toDouble() ?? 0;
          await endpoint.resolveClientAbsent(deliveryId, resolution, lat, lng);
        }
        toRemove.add(deliveryId);
        // Brief delay between requests to avoid server rate-limiting
        await Future<void>.delayed(const Duration(milliseconds: 300));
        debugPrint('PendingAcceptQueue: synced $action for $deliveryId');
      } on DioException catch (e) {
        if (e.response?.statusCode == 409 || e.response?.statusCode == 404) {
          toRemove.add(deliveryId);
          debugPrint(
            'PendingAcceptQueue: removed $deliveryId (${e.response?.statusCode})',
          );
        } else {
          debugPrint('PendingAcceptQueue: retry later for $deliveryId: $e');
        }
      }
    }

    for (final id in toRemove) {
      await _removeUnsafe(id);
    }
  }

  /// Remove interne (assume que le lock est deja tenu).
  Future<void> _removeUnsafe(String deliveryId) async {
    final entries = await _readEntriesUnsafe();
    entries.removeWhere((e) => e['delivery_id'] == deliveryId);
    await _writeEntriesUnsafe(entries);
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Map<String, dynamic>>> _readEntriesUnsafe() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final list = jsonDecode(content) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('PendingAcceptQueue: read error $e');
      return [];
    }
  }

  Future<void> _writeEntriesUnsafe(List<Map<String, dynamic>> entries) async {
    final file = await _file;
    await file.writeAsString(jsonEncode(entries));
  }
}
