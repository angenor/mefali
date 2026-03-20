import 'dart:convert';

/// Mission de livraison enrichie pour le DeliveryMissionCard.
class DeliveryMission {
  const DeliveryMission({
    required this.deliveryId,
    required this.orderId,
    required this.merchantName,
    this.merchantAddress,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.estimatedDistanceM,
    required this.deliveryFee,
    required this.itemsSummary,
    this.paymentType,
    this.orderTotal,
    this.customerPhone,
    required this.createdAt,
  });

  final String deliveryId;
  final String orderId;
  final String merchantName;
  final String? merchantAddress;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final int? estimatedDistanceM;
  final int deliveryFee;
  final String itemsSummary;
  final String? paymentType;
  final int? orderTotal;
  final String? customerPhone;
  final String createdAt;

  factory DeliveryMission.fromJson(Map<String, dynamic> json) {
    return DeliveryMission(
      deliveryId: json['delivery_id'] as String,
      orderId: json['order_id'] as String,
      merchantName: json['merchant_name'] as String,
      merchantAddress: json['merchant_address'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
      deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
      estimatedDistanceM: json['estimated_distance_m'] as int?,
      deliveryFee: json['delivery_fee'] as int,
      itemsSummary: json['items_summary'] as String,
      paymentType: json['payment_type'] as String?,
      orderTotal: json['order_total'] as int?,
      customerPhone: json['customer_phone'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  /// Decode a DeliveryMission from a Base64-encoded deep link data string.
  factory DeliveryMission.fromDeepLink(String base64Data) {
    final decoded = utf8.decode(base64Decode(base64Data));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    return DeliveryMission(
      deliveryId: json['delivery_id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      merchantName: json['merchant_name']?.toString() ?? 'Restaurant',
      merchantAddress: json['merchant_address']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      deliveryLat: _parseDouble(json['delivery_lat']),
      deliveryLng: _parseDouble(json['delivery_lng']),
      estimatedDistanceM: _parseInt(json['estimated_distance_m']),
      deliveryFee: _parseInt(json['delivery_fee']) ?? 0,
      itemsSummary: json['items_summary']?.toString() ?? '',
      paymentType: json['payment_type']?.toString(),
      orderTotal: _parseInt(json['order_total']),
      customerPhone: json['customer_phone']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'delivery_id': deliveryId,
        'order_id': orderId,
        'merchant_name': merchantName,
        'merchant_address': merchantAddress,
        'delivery_address': deliveryAddress,
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        'estimated_distance_m': estimatedDistanceM,
        'delivery_fee': deliveryFee,
        'items_summary': itemsSummary,
        'payment_type': paymentType,
        'order_total': orderTotal,
        'customer_phone': customerPhone,
        'created_at': createdAt,
      };

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
