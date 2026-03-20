import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import 'push_notification_handler.dart';

/// Provider that registers the FCM token with the backend.
/// Should be watched after login to ensure token is always up-to-date.
final fcmTokenProvider = FutureProvider.autoDispose<void>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return;

  final handler = PushNotificationHandler.instance;

  try {
    final token = await handler.getToken();
    if (token == null) return;

    final dio = ref.watch(dioProvider);
    await dio.put<void>(
      '/users/me/fcm-token',
      data: {'token': token},
    );

    // Listen for token refresh — cancel subscription on provider dispose
    final subscription = handler.onTokenRefresh.listen((newToken) async {
      try {
        await dio.put<void>(
          '/users/me/fcm-token',
          data: {'token': newToken},
        );
      } catch (_) {
        // Silent failure — will retry on next app start
      }
    });
    ref.onDispose(subscription.cancel);
  } catch (_) {
    // Firebase not initialized or permission denied — skip silently
  }
});
