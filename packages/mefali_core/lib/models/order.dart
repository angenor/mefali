import 'package:json_annotation/json_annotation.dart';

import '../enums/order_status.dart';
import 'order_item.dart';

part 'order.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.merchantId,
    this.driverId,
    required this.status,
    required this.paymentType,
    required this.paymentStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.cityId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  final String id;
  final String customerId;
  final String merchantId;
  final String? driverId;
  final OrderStatus status;
  final String paymentType;
  final String paymentStatus;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? cityId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  Map<String, dynamic> toJson() => _$OrderToJson(this);

  /// Formatte le total en FCFA (centimes → FCFA).
  String get totalFormatted => '${(total / 100).toStringAsFixed(0)} FCFA';
}
