import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/delivery_endpoint.dart';

/// Provider pour la mission pending du livreur connecte.
final pendingMissionProvider =
    FutureProvider.autoDispose<DeliveryMission?>((ref) async {
  final endpoint = DeliveryEndpoint(ref.watch(dioProvider));
  return endpoint.getPendingMission();
});
