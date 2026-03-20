import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Queue locale pour les acceptations de mission en mode offline.
/// Stocke les missions acceptees dans un fichier JSON local.
/// Le sync avec le serveur sera effectue au retour de connexion (story 5.3).
class PendingAcceptQueue {
  PendingAcceptQueue._();
  static final instance = PendingAcceptQueue._();

  static const _fileName = 'pending_accepts.json';

  /// Ajouter une mission acceptee en attente de sync.
  /// [missionData] stocke le snapshot complet pour recovery offline.
  Future<void> enqueue(
    String deliveryId,
    String orderId, [
    Map<String, dynamic>? missionData,
  ]) async {
    final entries = await _readEntries();
    entries.add({
      'delivery_id': deliveryId,
      'order_id': orderId,
      'accepted_at': DateTime.now().toIso8601String(),
      if (missionData != null) 'mission_data': missionData,
    });
    await _writeEntries(entries);
    debugPrint('PendingAcceptQueue: queued accept for delivery $deliveryId');
  }

  /// Recuperer toutes les actions en attente.
  Future<List<Map<String, dynamic>>> getPending() async {
    return _readEntries();
  }

  /// Retirer une action apres sync reussi.
  Future<void> remove(String deliveryId) async {
    final entries = await _readEntries();
    entries.removeWhere((e) => e['delivery_id'] == deliveryId);
    await _writeEntries(entries);
  }

  /// Verifier si des actions sont en attente.
  Future<bool> get hasPending async {
    final entries = await _readEntries();
    return entries.isNotEmpty;
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Map<String, dynamic>>> _readEntries() async {
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

  Future<void> _writeEntries(List<Map<String, dynamic>> entries) async {
    final file = await _file;
    await file.writeAsString(jsonEncode(entries));
  }
}
