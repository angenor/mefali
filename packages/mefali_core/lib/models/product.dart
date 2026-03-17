import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Product {
  const Product({
    required this.id,
    required this.merchantId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.initialStock,
    this.photoUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  final String id;
  final String merchantId;
  final String name;
  final String? description;
  final int price;
  final int stock;
  final int initialStock;
  final String? photoUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
