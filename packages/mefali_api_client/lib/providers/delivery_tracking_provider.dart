import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/delivery_endpoint.dart';
import '../websocket/delivery_tracking_ws.dart';

/// Provider de tracking temps reel via WebSocket avec fallback HTTP polling.
///
/// 1. Fetch REST initial pour obtenir la position courante + infos livreur
/// 2. WebSocket pour les mises a jour en temps reel (enrichies avec driver info)
/// 3. Fallback HTTP polling 15s si WebSocket echoue apres 3 tentatives
final deliveryTrackingProvider = StreamProvider.autoDispose
    .family<DeliveryLocationUpdate, String>((ref, orderId) async* {
  final dio = ref.read(dioProvider);
  final baseUrl = dio.options.baseUrl;
  final endpoint = DeliveryEndpoint(dio);

  var disposed = false;
  ref.onDispose(() {
    disposed = true;
  });

  // Phase 1: Fetch REST initial pour position courante + driver info
  String? driverName;
  String? driverPhone;
  try {
    final initial = await endpoint.getDeliveryTracking(orderId);
    if (initial != null) {
      driverName = initial.driverName;
      driverPhone = initial.driverPhone;
      yield initial;
    }
  } catch (_) {}

  if (disposed) return;

  // Phase 2: WebSocket pour les updates temps reel
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token') ?? '';

  final ws = DeliveryTrackingWs(
    baseUrl: baseUrl,
    orderId: orderId,
    token: token,
  );

  ws.connect();
  ref.onDispose(() => ws.dispose());

  try {
    await for (final update in ws.stream) {
      // Enrichir avec driver info du fetch initial (WebSocket n'envoie pas ces champs)
      yield DeliveryLocationUpdate(
        lat: update.lat,
        lng: update.lng,
        etaSeconds: update.etaSeconds,
        updatedAt: update.updatedAt,
        driverName: update.driverName ?? driverName,
        driverPhone: update.driverPhone ?? driverPhone,
        status: update.status,
      );
    }
  } catch (_) {
    // WebSocket a echoue apres 3 retries
  }

  if (disposed) return;

  // Phase 3: Fallback HTTP polling 15s (isFallback = true)
  while (!disposed) {
    try {
      final tracking = await endpoint.getDeliveryTracking(orderId);
      if (tracking != null) {
        driverName = tracking.driverName ?? driverName;
        driverPhone = tracking.driverPhone ?? driverPhone;
        yield DeliveryLocationUpdate(
          lat: tracking.lat,
          lng: tracking.lng,
          etaSeconds: tracking.etaSeconds,
          updatedAt: tracking.updatedAt,
          driverName: tracking.driverName,
          driverPhone: tracking.driverPhone,
          status: tracking.status,
          isFallback: true,
        );
      }
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 15));
  }
});
