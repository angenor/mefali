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
  ProductCatalogueNotifier(this._endpoint, this._ref)
      : super(const AsyncValue.data(null));

  final ProductEndpoint _endpoint;
  final Ref _ref;

  void _invalidateLists() {
    _ref.invalidate(merchantProductsProvider);
    _ref.invalidate(stockAlertsProvider);
  }

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
    if (state is AsyncData) _invalidateLists();
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
    if (state is AsyncData) _invalidateLists();
  }

  Future<void> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _endpoint.deleteProduct(productId);
    });
    if (state is AsyncData) _invalidateLists();
  }

  // --- Stock management (story 3.4) ---

  Future<void> updateStock({
    required String productId,
    required int stock,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _endpoint.updateProductStock(productId, stock);
    });
    if (state is AsyncData) _invalidateLists();
  }

  Future<void> acknowledgeAlert(String alertId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _endpoint.acknowledgeAlert(alertId);
    });
    if (state is AsyncData) _invalidateLists();
  }
}

/// Provider pour le notifier catalogue.
final productCatalogueProvider =
    StateNotifierProvider.autoDispose<ProductCatalogueNotifier, AsyncValue<void>>(
  (ref) => ProductCatalogueNotifier(ProductEndpoint(ref.watch(dioProvider)), ref),
);

/// Provider pour les alertes stock non-acquittees du marchand.
final stockAlertsProvider =
    FutureProvider.autoDispose<List<StockAlert>>((ref) async {
  final endpoint = ProductEndpoint(ref.watch(dioProvider));
  return endpoint.getStockAlerts();
});
