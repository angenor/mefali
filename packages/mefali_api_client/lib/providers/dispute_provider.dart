import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/dispute_endpoint.dart';

/// Provider pour recuperer le litige d'une commande (null si aucun).
final orderDisputeProvider =
    FutureProvider.autoDispose.family<Dispute?, String>(
        (ref, orderId) async {
  final endpoint = DisputeEndpoint(ref.watch(dioProvider));
  return endpoint.getOrderDispute(orderId);
});
