import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/rating_endpoint.dart';

/// Provider pour verifier si une commande a deja ete notee.
/// Retourne null si pas encore notee.
final orderRatingProvider =
    FutureProvider.autoDispose.family<RatingPair?, String>(
        (ref, orderId) async {
  final endpoint = RatingEndpoint(ref.watch(dioProvider));
  return endpoint.getOrderRating(orderId);
});
