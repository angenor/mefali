import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import 'app.dart';
import 'features/delivery/pending_accept_queue.dart';
import 'features/notification/deep_link_handler.dart';
import 'features/notification/push_notification_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — gracefully skipped if config files missing
  try {
    await Firebase.initializeApp();
    PushNotificationHandler.instance.initialize();
  } catch (e) {
    debugPrint('Firebase init skipped (config missing): $e');
  }

  // Deep link handler for SMS fallback
  await DeepLinkHandler.instance.initialize();

  // Sync any pending offline actions on app startup
  _syncPendingOnStartup();

  // Sync on reconnect (AC #4: < 60s after connectivity returns)
  _setupConnectivitySync();

  runApp(const ProviderScope(child: MefaliLivreurApp()));
}

/// Listen for connectivity changes and sync pending actions on reconnect.
void _setupConnectivitySync() {
  Connectivity().onConnectivityChanged.listen(
    (results) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) return;
      try {
        if (await PendingAcceptQueue.instance.hasPending) {
          final dio = await _createAuthenticatedDio();
          if (dio != null) {
            await PendingAcceptQueue.instance.syncPendingActions(dio);
          }
        }
      } catch (e) {
        debugPrint('Connectivity sync failed: $e');
      }
    },
  );
}

/// Create a Dio instance with stored auth token.
Future<Dio?> _createAuthenticatedDio() async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');
  if (token == null) return null;
  return createDio()..options.headers['Authorization'] = 'Bearer $token';
}

/// Fire-and-forget sync of queued accept/refuse actions.
void _syncPendingOnStartup() {
  Future.microtask(() async {
    try {
      if (await PendingAcceptQueue.instance.hasPending) {
        final dio = await _createAuthenticatedDio();
        if (dio == null) return;
        await PendingAcceptQueue.instance.syncPendingActions(dio);
      }
    } catch (e) {
      debugPrint('Startup sync failed (will retry on connectivity): $e');
    }
  });
}
