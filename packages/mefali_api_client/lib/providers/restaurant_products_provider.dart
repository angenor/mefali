import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/restaurant_endpoint.dart';

/// Charge les produits d'un marchand pour le catalogue B2C.
final restaurantProductsProvider = FutureProvider.autoDispose
    .family<List<ProductItem>, String>((ref, merchantId) async {
  final endpoint = RestaurantEndpoint(ref.watch(dioProvider));
  return endpoint.listProducts(merchantId: merchantId);
});
