import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mefali_core/mefali_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Client WebSocket pour le tracking temps reel des livraisons.
///
/// Se connecte au serveur via WebSocket et recoit les mises a jour
/// de position du livreur via Redis PubSub relay.
/// Reconnexion automatique avec expo backoff (max 30s, 3 tentatives).
class DeliveryTrackingWs {
  DeliveryTrackingWs({
    required this.baseUrl,
    required this.orderId,
    required this.token,
  });

  final String baseUrl;
  final String orderId;
  final String token;

  WebSocketChannel? _channel;
  final _controller = StreamController<DeliveryLocationUpdate>.broadcast();
  int _retryCount = 0;
  static const _maxRetries = 3;
  Timer? _reconnectTimer;
  bool _disposed = false;

  /// Stream de mises a jour de position du livreur.
  Stream<DeliveryLocationUpdate> get stream => _controller.stream;

  /// Etablit la connexion WebSocket.
  void connect() {
    if (_disposed) return;

    final wsScheme = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final host = baseUrl
        .replaceFirst(RegExp(r'https?://'), '')
        .replaceFirst(RegExp(r'/api/v1$'), '');
    final uri = Uri.parse(
      '$wsScheme://$host/api/v1/ws/deliveries/$orderId/track?token=$token',
    );

    try {
      _channel = WebSocketChannel.connect(uri);

      _retryCount = 0;

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            if (json['event'] == 'delivery.location_update') {
              final update = DeliveryLocationUpdate.fromJson(
                json['data'] as Map<String, dynamic>,
              );
              _controller.add(update);
            } else if (json['event'] == 'delivery.confirmed') {
              // Delivery completed — emit a synthetic update with status=delivered
              _controller.add(const DeliveryLocationUpdate(
                lat: 0,
                lng: 0,
                etaSeconds: 0,
                updatedAt: '',
                status: 'delivered',
              ));
            } else if (json['event'] == 'delivery.client_absent') {
              // Driver reports client absent — emit synthetic update
              _controller.add(const DeliveryLocationUpdate(
                lat: 0,
                lng: 0,
                etaSeconds: 0,
                updatedAt: '',
                status: 'client_absent',
              ));
            } else if (json['event'] == 'delivery.absent_resolved') {
              // Client absent resolved — emit synthetic update
              _controller.add(const DeliveryLocationUpdate(
                lat: 0,
                lng: 0,
                etaSeconds: 0,
                updatedAt: '',
                status: 'absent_resolved',
              ));
            }
          } catch (_) {}
        },
        onError: (_) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    _channel = null;

    if (_retryCount < _maxRetries) {
      _retryCount++;
      final delayMs = min(1000 * pow(2, _retryCount - 1).toInt(), 30000);
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(milliseconds: delayMs), connect);
    } else {
      // Signal connection lost after max retries
      _controller.addError('connection_lost');
    }
  }

  /// Ferme la connexion et libere les ressources.
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}
