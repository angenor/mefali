import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Handles incoming deep links from SMS (mefali://delivery/mission?data=...).
/// Uses platform MethodChannel to receive deep links on both cold start and while running.
class DeepLinkHandler {
  DeepLinkHandler._();
  static final instance = DeepLinkHandler._();

  static const _channel = MethodChannel('ci.mefali.livreur/deeplink');

  bool _initialized = false;

  final _linkController = StreamController<Uri>.broadcast();

  /// Stream of incoming deep link URIs.
  Stream<Uri> get linkStream => _linkController.stream;

  Uri? _initialLink;

  /// The deep link that launched the app (cold start). Null if app was already running.
  Uri? get initialLink => _initialLink;

  /// Initialize deep link handling. Call once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Check for initial link (cold start) with timeout to avoid blocking startup
    try {
      final initialLinkStr = await _channel
          .invokeMethod<String>('getInitialLink')
          .timeout(const Duration(seconds: 3));
      if (initialLinkStr != null && initialLinkStr.isNotEmpty) {
        _initialLink = Uri.tryParse(initialLinkStr);
      }
    } catch (e) {
      debugPrint('Deep link initial check failed: $e');
    }

    // Listen for links while app is running
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewLink') {
        final link = call.arguments as String?;
        if (link != null && link.isNotEmpty) {
          final uri = Uri.tryParse(link);
          if (uri != null) {
            _linkController.add(uri);
          }
        }
      }
    });
  }

  /// Parse the Base64 data parameter from a mefali deep link URI.
  /// Returns null if the URI is not a valid mission deep link.
  static String? extractMissionData(Uri uri) {
    if (uri.scheme != 'mefali') return null;
    if (uri.host != 'delivery') return null;
    if (uri.path != '/mission') return null;
    return uri.queryParameters['data'];
  }

  void dispose() {
    _linkController.close();
  }
}
