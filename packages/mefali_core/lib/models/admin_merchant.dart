import 'package:json_annotation/json_annotation.dart';

import '../enums/vendor_status.dart';

part 'admin_merchant.g.dart';

/// Element de la liste des marchands cote admin.
@JsonSerializable(fieldRename: FieldRename.snake)
class AdminMerchantListItem {
  const AdminMerchantListItem({
    required this.id,
    required this.name,
    required this.status,
    this.cityName,
    this.category,
    required this.ordersCount,
    required this.avgRating,
    required this.disputesCount,
    required this.createdAt,
  });

  factory AdminMerchantListItem.fromJson(Map<String, dynamic> json) =>
      _$AdminMerchantListItemFromJson(json);

  final String id;
  final String name;
  final VendorStatus status;
  final String? cityName;
  final String? category;
  final int ordersCount;
  final double avgRating;
  final int disputesCount;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$AdminMerchantListItemToJson(this);
}

/// Profil marchand pour la vue historique.
@JsonSerializable(fieldRename: FieldRename.snake)
class MerchantProfileInfo {
  const MerchantProfileInfo({
    required this.id,
    required this.name,
    this.address,
    required this.status,
    this.category,
    this.kycStatus,
    required this.createdAt,
  });

  factory MerchantProfileInfo.fromJson(Map<String, dynamic> json) =>
      _$MerchantProfileInfoFromJson(json);

  final String id;
  final String name;
  final String? address;
  final VendorStatus status;
  final String? category;
  final String? kycStatus;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$MerchantProfileInfoToJson(this);
}

/// Stats agregees du marchand.
@JsonSerializable(fieldRename: FieldRename.snake)
class MerchantHistoryStats {
  const MerchantHistoryStats({
    required this.totalOrders,
    required this.completedOrders,
    required this.completionRate,
    required this.avgRating,
    required this.totalDisputes,
    required this.resolvedDisputes,
  });

  factory MerchantHistoryStats.fromJson(Map<String, dynamic> json) =>
      _$MerchantHistoryStatsFromJson(json);

  final int totalOrders;
  final int completedOrders;
  final double completionRate;
  final double avgRating;
  final int totalDisputes;
  final int resolvedDisputes;

  Map<String, dynamic> toJson() => _$MerchantHistoryStatsToJson(this);
}

/// Commande recente du marchand.
@JsonSerializable(fieldRename: FieldRename.snake)
class MerchantRecentOrder {
  const MerchantRecentOrder({
    required this.id,
    required this.status,
    required this.total,
    this.customerName,
    required this.createdAt,
  });

  factory MerchantRecentOrder.fromJson(Map<String, dynamic> json) =>
      _$MerchantRecentOrderFromJson(json);

  final String id;
  final String status;
  final int total;
  final String? customerName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$MerchantRecentOrderToJson(this);
}

/// Reponse complete historique marchand.
@JsonSerializable(fieldRename: FieldRename.snake)
class MerchantHistory {
  const MerchantHistory({
    required this.merchant,
    required this.stats,
    required this.recentOrders,
  });

  factory MerchantHistory.fromJson(Map<String, dynamic> json) =>
      _$MerchantHistoryFromJson(json);

  final MerchantProfileInfo merchant;
  final MerchantHistoryStats stats;
  final PaginatedRecentOrders recentOrders;

  Map<String, dynamic> toJson() => _$MerchantHistoryToJson(this);
}

/// Commandes recentes paginées.
@JsonSerializable(fieldRename: FieldRename.snake)
class PaginatedRecentOrders {
  const PaginatedRecentOrders({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
  });

  factory PaginatedRecentOrders.fromJson(Map<String, dynamic> json) =>
      _$PaginatedRecentOrdersFromJson(json);

  final List<MerchantRecentOrder> items;
  final int page;
  final int perPage;
  final int total;

  Map<String, dynamic> toJson() => _$PaginatedRecentOrdersToJson(this);
}
