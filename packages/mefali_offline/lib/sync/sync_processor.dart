import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/mefali_database.dart';

/// Result of processing a single sync queue entry.
enum SyncResult {
  /// Entry processed successfully — remove from queue.
  success,
  /// Conflict (e.g. 409) — treat as success and remove from queue.
  conflict,
  /// Transient failure — retry later.
  retryable,
}

/// Processes offline sync queue entries when connectivity resumes.
///
/// Usage:
/// ```dart
/// final processor = SyncProcessor(
///   db: db,
///   handler: (entry) async {
///     // POST to API based on entry.entityType
///     return SyncResult.success;
///   },
/// );
/// processor.start();
/// ```
class SyncProcessor {
  SyncProcessor({
    required this.db,
    required this.handler,
    this.maxRetries = 5,
  });

  final MefaliDatabase db;
  final Future<SyncResult> Function(SyncQueueEntry entry) handler;
  final int maxRetries;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isProcessing = false;

  /// Start listening for connectivity changes.
  void start() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any(
        (r) => r != ConnectivityResult.none,
      );
      if (hasConnection) {
        processQueue();
      }
    });
    // Also process immediately in case we're already online.
    processQueue();
  }

  /// Stop listening for connectivity changes.
  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Process all pending entries in the queue.
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final entries = await db.getPendingSyncEntries();
      for (final entry in entries) {
        if (entry.retryCount >= maxRetries) {
          // Dead letter — remove after max retries.
          await db.removeSyncEntry(entry.id);
          continue;
        }

        try {
          final result = await handler(entry);
          switch (result) {
            case SyncResult.success:
            case SyncResult.conflict:
              await db.removeSyncEntry(entry.id);
            case SyncResult.retryable:
              await db.incrementRetryCount(entry.id);
          }
        } catch (_) {
          await db.incrementRetryCount(entry.id);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}
