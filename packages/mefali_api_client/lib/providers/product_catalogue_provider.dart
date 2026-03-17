import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/product_endpoint.dart';

/// Provider pour la liste des produits du marchand connecte.
final merchantProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final endpoint = ProductEndpoint(ref.watch(dioProvider));
  return endpoint.getMyProducts();
});

/// Notifier pour les mutations catalogue (create, update, delete).
class ProductCatalogueNotifier extends StateNotifier<AsyncValue<void>> {
  ProductCatalogueNotifier(this._endpoint) : super(const AsyncValue.data(null));

  final ProductEndpoint _endpoint;

  Future<void> createProduct({
    required String name,
    required int price,
    String? description,
    int? stock,
    String? imagePath,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _endpoint.createProduct(
        name: name,
        price: price,
        description: description,
        stock: stock,
        imagePath: imagePath,
      );
    });
  }

  Future<void> updateProduct({
    required String productId,
    String? name,
    int? price,
    String? description,
    int? stock,
    String? imagePath,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _endpoint.updateProduct(
        productId: productId,
        name: name,
        price: price,
        description: description,
        stock: stock,
        imagePath: imagePath,
      );
    });
  }

  Future<void> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _endpoint.deleteProduct(productId);
    });
  }
}

/// Provider pour le notifier catalogue.
final productCatalogueProvider =
    StateNotifierProvider.autoDispose<ProductCatalogueNotifier, AsyncValue<void>>(
  (ref) => ProductCatalogueNotifier(ProductEndpoint(ref.watch(dioProvider))),
);
