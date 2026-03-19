import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

/// Panier local B2C — lie a un restaurant (autoDispose).
final cartProvider =
    NotifierProvider.autoDispose<CartNotifier, Map<String, CartItem>>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<Map<String, CartItem>> {
  @override
  Map<String, CartItem> build() => {};

  void addProduct(ProductItem product) {
    final existing = state[product.id];
    state = {
      ...state,
      product.id: existing != null
          ? existing.copyWith(quantity: existing.quantity + 1)
          : CartItem(product: product),
    };
  }

  void incrementProduct(String productId) {
    final existing = state[productId];
    if (existing == null) return;
    state = {
      ...state,
      productId: existing.copyWith(quantity: existing.quantity + 1),
    };
  }

  void decrementProduct(String productId) {
    final existing = state[productId];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      removeProduct(productId);
    } else {
      state = {
        ...state,
        productId: existing.copyWith(quantity: existing.quantity - 1),
      };
    }
  }

  void removeProduct(String productId) {
    state = Map.of(state)..remove(productId);
  }

  int get totalItems =>
      state.values.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice =>
      state.values.fold(0, (sum, item) => sum + item.totalPrice);

  void clear() => state = {};
}
