import 'package:json_annotation/json_annotation.dart';

part 'stock_alert.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StockAlert {
  const StockAlert({
    required this.id,
    required this.merchantId,
    required this.productId,
    required this.alertType,
    required this.currentStock,
    required this.initialStock,
    required this.triggeredAt,
    this.acknowledgedAt,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) =>
      _$StockAlertFromJson(json);

  final String id;
  final String merchantId;
  final String productId;
  final String alertType;
  final int currentStock;
  final int initialStock;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;

  Map<String, dynamic> toJson() => _$StockAlertToJson(this);
}
