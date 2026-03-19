import 'package:json_annotation/json_annotation.dart';

part 'agent_stats.g.dart';

/// Comptage sur 3 periodes : aujourd'hui, cette semaine, total.
@JsonSerializable(fieldRename: FieldRename.snake)
class PeriodCount {
  final int today;
  final int thisWeek;
  final int total;

  const PeriodCount({
    required this.today,
    required this.thisWeek,
    required this.total,
  });

  factory PeriodCount.fromJson(Map<String, dynamic> json) =>
      _$PeriodCountFromJson(json);
  Map<String, dynamic> toJson() => _$PeriodCountToJson(this);
}

/// Comptage marchands avec premiere commande (pas de "today").
@JsonSerializable(fieldRename: FieldRename.snake)
class FirstOrderCount {
  final int thisWeek;
  final int total;

  const FirstOrderCount({
    required this.thisWeek,
    required this.total,
  });

  factory FirstOrderCount.fromJson(Map<String, dynamic> json) =>
      _$FirstOrderCountFromJson(json);
  Map<String, dynamic> toJson() => _$FirstOrderCountToJson(this);
}

/// Marchand recemment onboarde sur le dashboard agent.
@JsonSerializable(fieldRename: FieldRename.snake)
class RecentMerchant {
  final String id;
  final String name;
  final String createdAt;
  final bool hasFirstOrder;

  const RecentMerchant({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.hasFirstOrder,
  });

  factory RecentMerchant.fromJson(Map<String, dynamic> json) =>
      _$RecentMerchantFromJson(json);
  Map<String, dynamic> toJson() => _$RecentMerchantToJson(this);
}

/// Stats de performance completes de l'agent terrain.
@JsonSerializable(fieldRename: FieldRename.snake)
class AgentPerformanceStats {
  final PeriodCount merchantsOnboarded;
  final PeriodCount kycValidated;
  final FirstOrderCount merchantsWithFirstOrder;
  final List<RecentMerchant> recentMerchants;

  const AgentPerformanceStats({
    required this.merchantsOnboarded,
    required this.kycValidated,
    required this.merchantsWithFirstOrder,
    required this.recentMerchants,
  });

  factory AgentPerformanceStats.fromJson(Map<String, dynamic> json) =>
      _$AgentPerformanceStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AgentPerformanceStatsToJson(this);
}
