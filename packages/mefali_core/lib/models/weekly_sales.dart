import 'package:json_annotation/json_annotation.dart';

part 'weekly_sales.g.dart';

/// Periode de la semaine.
@JsonSerializable(fieldRename: FieldRename.snake)
class WeekPeriod {
  final String start;
  final String end;

  const WeekPeriod({required this.start, required this.end});

  factory WeekPeriod.fromJson(Map<String, dynamic> json) =>
      _$WeekPeriodFromJson(json);
  Map<String, dynamic> toJson() => _$WeekPeriodToJson(this);
}

/// Resume des ventes d'une semaine. Montants en centimes.
@JsonSerializable(fieldRename: FieldRename.snake)
class WeekSummary {
  final int totalSales;
  final int orderCount;
  final int averageOrder;

  const WeekSummary({
    required this.totalSales,
    required this.orderCount,
    required this.averageOrder,
  });

  factory WeekSummary.fromJson(Map<String, dynamic> json) =>
      _$WeekSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$WeekSummaryToJson(this);
}

/// Repartition des ventes par produit.
@JsonSerializable(fieldRename: FieldRename.snake)
class ProductSales {
  final String productId;
  final String productName;
  final int quantitySold;
  final int revenue;
  final double percentage;

  const ProductSales({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.percentage,
  });

  factory ProductSales.fromJson(Map<String, dynamic> json) =>
      _$ProductSalesFromJson(json);
  Map<String, dynamic> toJson() => _$ProductSalesToJson(this);
}

/// Stats hebdomadaires completes d'un marchand.
@JsonSerializable(fieldRename: FieldRename.snake)
class WeeklySales {
  final WeekPeriod period;
  final WeekSummary currentWeek;
  final WeekSummary previousWeek;
  final List<ProductSales> productBreakdown;

  const WeeklySales({
    required this.period,
    required this.currentWeek,
    required this.previousWeek,
    required this.productBreakdown,
  });

  factory WeeklySales.fromJson(Map<String, dynamic> json) =>
      _$WeeklySalesFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklySalesToJson(this);
}
