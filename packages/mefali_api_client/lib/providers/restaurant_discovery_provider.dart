import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/restaurant_endpoint.dart';

/// Charge la liste des restaurants disponibles filtrée par catégorie.
/// Paramètre : catégorie API (ex. 'restaurant', 'maquis') ou null pour tout.
final restaurantDiscoveryProvider =
    FutureProvider.autoDispose.family<List<RestaurantSummary>, String?>(
  (ref, category) async {
    final endpoint = RestaurantEndpoint(ref.watch(dioProvider));
    return endpoint.listRestaurants(category: category);
  },
);
