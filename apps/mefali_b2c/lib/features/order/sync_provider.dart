import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_offline/mefali_offline.dart';

import 'saved_addresses_provider.dart';

/// Provider that starts the SyncProcessor on app init.
/// Watch this provider early (e.g. in main or root widget) to activate sync.
final syncProcessorProvider = Provider<SyncProcessor>((ref) {
  final db = ref.watch(mefaliDatabaseProvider);
  final dio = ref.watch(dioProvider);

  final processor = SyncProcessor(
    db: db,
    handler: (entry) => _handleSyncEntry(dio, entry),
  );

  processor.start();
  ref.onDispose(processor.stop);
  return processor;
});

Future<SyncResult> _handleSyncEntry(Dio dio, SyncQueueEntry entry) async {
  final payload = jsonDecode(entry.payload) as Map<String, dynamic>;

  switch (entry.entityType) {
    case 'rating':
      return _syncRating(dio, payload);
    default:
      // Unknown entity type — remove from queue.
      return SyncResult.success;
  }
}

Future<SyncResult> _syncRating(Dio dio, Map<String, dynamic> payload) async {
  final orderId = payload['order_id'] as String;
  final request = SubmitRatingRequest(
    merchantScore: payload['merchant_score'] as int,
    driverScore: payload['driver_score'] as int,
    merchantComment: payload['merchant_comment'] as String?,
    driverComment: payload['driver_comment'] as String?,
  );

  try {
    final endpoint = RatingEndpoint(dio);
    await endpoint.submitRating(orderId, request);
    return SyncResult.success;
  } on DioException catch (e) {
    if (e.response?.statusCode == 409) {
      // Already rated — treat as success (AC #7 / Task 9.3).
      return SyncResult.conflict;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return SyncResult.retryable;
    }
    // Other HTTP errors (400, 403, 500) — retryable, will dead-letter after max retries.
    return SyncResult.retryable;
  }
}
