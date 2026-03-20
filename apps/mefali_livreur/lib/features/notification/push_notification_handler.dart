import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level handler for background/terminated messages (required by Firebase).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

/// Singleton handler for push notification setup and routing.
class PushNotificationHandler {
  PushNotificationHandler._();
  static final instance = PushNotificationHandler._();

  final _messaging = FirebaseMessaging.instance;

  /// Most recent delivery mission payload from a push notification.
  Map<String, dynamic>? lastMissionPayload;

  void initialize() {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS)
    _requestPermission();

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap handler (app was in background, user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    _checkInitialMessage();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  /// Get the current FCM token for registration with backend.
  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  /// Listen for token refresh events.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.messageId}');
    final data = message.data;
    if (data['type'] == 'delivery_mission') {
      lastMissionPayload = data;
      _onMissionReceived?.call(data);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    final data = message.data;
    if (data['type'] == 'delivery_mission') {
      lastMissionPayload = data;
      _onMissionReceived?.call(data);
    }
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final data = initialMessage.data;
      if (data['type'] == 'delivery_mission') {
        lastMissionPayload = data;
        // Will be consumed when the listener is registered
      }
    }
  }

  /// Callback for when a delivery mission notification is received.
  void Function(Map<String, dynamic>)? _onMissionReceived;

  /// Register a listener for incoming delivery missions.
  void onMissionReceived(void Function(Map<String, dynamic>) callback) {
    _onMissionReceived = callback;
    // If there's a pending payload from initial message, fire it now
    if (lastMissionPayload != null) {
      callback(lastMissionPayload!);
      lastMissionPayload = null;
    }
  }

  /// Unregister the listener.
  void removeMissionListener() {
    _onMissionReceived = null;
  }
}
