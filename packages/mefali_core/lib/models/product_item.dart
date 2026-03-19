import 'package:json_annotation/json_annotation.dart';

part 'product_item.g.dart';

/// Produit leger pour le catalogue B2C (story 4.2).
/// Exclut les champs B2B (initial_stock, is_available, timestamps).
@JsonSerializable(fieldRename: FieldRename.snake)
class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.photoUrl,
    required this.merchantId,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) =>
      _$ProductItemFromJson(json);

  final String id;
  final String name;

  /// Prix en centimes FCFA (150000 = 1 500 FCFA).
  final int price;
  final int stock;
  final String? photoUrl;
  final String merchantId;

  bool get isOutOfStock => stock <= 0;

  Map<String, dynamic> toJson() => _$ProductItemToJson(this);
}
