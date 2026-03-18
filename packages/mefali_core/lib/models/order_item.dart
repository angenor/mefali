import 'package:json_annotation/json_annotation.dart';

part 'order_item.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
    this.productName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final int unitPrice;
  final DateTime createdAt;
  final String? productName;

  Map<String, dynamic> toJson() => _$OrderItemToJson(this);

  /// Sous-total de la ligne (centimes).
  int get lineTotal => unitPrice * quantity;

  /// Formatte le prix unitaire en FCFA.
  String get unitPriceFormatted =>
      '${(unitPrice / 100).toStringAsFixed(0)} FCFA';
}
