import 'package:json_annotation/json_annotation.dart';

part 'dashboard_stats.g.dart';

/// KPIs operationnels du dashboard admin.
@JsonSerializable(fieldRename: FieldRename.snake)
class DashboardStats {
  final int ordersToday;
  final int activeMerchants;
  final int driversOnline;
  final int pendingDisputes;

  const DashboardStats({
    required this.ordersToday,
    required this.activeMerchants,
    required this.driversOnline,
    required this.pendingDisputes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}
