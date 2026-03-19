import 'product_item.dart';

/// Element du panier B2C (story 4.2).
class CartItem {
  const CartItem({required this.product, this.quantity = 1});

  final ProductItem product;
  final int quantity;

  int get totalPrice => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}
