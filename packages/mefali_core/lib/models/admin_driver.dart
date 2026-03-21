import 'package:json_annotation/json_annotation.dart';

import '../enums/user_status.dart';

part 'admin_driver.g.dart';

/// Element de la liste des livreurs cote admin.
@JsonSerializable(fieldRename: FieldRename.snake)
class AdminDriverListItem {
  const AdminDriverListItem({
    required this.id,
    this.name,
    required this.status,
    this.cityName,
    required this.deliveriesCount,
    required this.avgRating,
    required this.disputesCount,
    required this.available,
    required this.createdAt,
  });

  factory AdminDriverListItem.fromJson(Map<String, dynamic> json) =>
      _$AdminDriverListItemFromJson(json);

  final String id;
  final String? name;
  final UserStatus status;
  final String? cityName;
  final int deliveriesCount;
  final double avgRating;
  final int disputesCount;
  final bool available;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$AdminDriverListItemToJson(this);
}

/// Profil livreur pour la vue historique.
@JsonSerializable(fieldRename: FieldRename.snake)
class DriverProfileInfo {
  const DriverProfileInfo({
    required this.id,
    this.name,
    required this.phone,
    required this.status,
    this.kycStatus,
    this.sponsorName,
    required this.available,
    required this.createdAt,
  });

  factory DriverProfileInfo.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileInfoFromJson(json);

  final String id;
  final String? name;
  final String phone;
  final UserStatus status;
  final String? kycStatus;
  final String? sponsorName;
  final bool available;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$DriverProfileInfoToJson(this);
}

/// Stats agregees du livreur.
@JsonSerializable(fieldRename: FieldRename.snake)
class DriverHistoryStats {
  const DriverHistoryStats({
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.completionRate,
    required this.avgRating,
    required this.totalDisputes,
    required this.resolvedDisputes,
  });

  factory DriverHistoryStats.fromJson(Map<String, dynamic> json) =>
      _$DriverHistoryStatsFromJson(json);

  final int totalDeliveries;
  final int completedDeliveries;
  final double completionRate;
  final double avgRating;
  final int totalDisputes;
  final int resolvedDisputes;

  Map<String, dynamic> toJson() => _$DriverHistoryStatsToJson(this);
}

/// Livraison recente du livreur.
@JsonSerializable(fieldRename: FieldRename.snake)
class DriverRecentDelivery {
  const DriverRecentDelivery({
    required this.id,
    required this.orderId,
    required this.status,
    this.merchantName,
    this.deliveredAt,
  });

  factory DriverRecentDelivery.fromJson(Map<String, dynamic> json) =>
      _$DriverRecentDeliveryFromJson(json);

  final String id;
  final String orderId;
  final String status;
  final String? merchantName;
  final DateTime? deliveredAt;

  Map<String, dynamic> toJson() => _$DriverRecentDeliveryToJson(this);
}

/// Reponse complete historique livreur.
@JsonSerializable(fieldRename: FieldRename.snake)
class DriverHistory {
  const DriverHistory({
    required this.driver,
    required this.stats,
    required this.recentDeliveries,
  });

  factory DriverHistory.fromJson(Map<String, dynamic> json) =>
      _$DriverHistoryFromJson(json);

  final DriverProfileInfo driver;
  final DriverHistoryStats stats;
  final PaginatedRecentDeliveries recentDeliveries;

  Map<String, dynamic> toJson() => _$DriverHistoryToJson(this);
}

/// Livraisons recentes paginées.
@JsonSerializable(fieldRename: FieldRename.snake)
class PaginatedRecentDeliveries {
  const PaginatedRecentDeliveries({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
  });

  factory PaginatedRecentDeliveries.fromJson(Map<String, dynamic> json) =>
      _$PaginatedRecentDeliveriesFromJson(json);

  final List<DriverRecentDelivery> items;
  final int page;
  final int perPage;
  final int total;

  Map<String, dynamic> toJson() => _$PaginatedRecentDeliveriesToJson(this);
}
