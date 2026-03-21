import 'package:json_annotation/json_annotation.dart';

import '../enums/user_role.dart';
import '../enums/user_status.dart';

part 'admin_user.g.dart';

/// Element de la liste des utilisateurs cote admin.
@JsonSerializable(fieldRename: FieldRename.snake)
class AdminUserListItem {
  const AdminUserListItem({
    required this.id,
    required this.phone,
    this.name,
    required this.role,
    required this.status,
    this.cityName,
    required this.createdAt,
  });

  factory AdminUserListItem.fromJson(Map<String, dynamic> json) =>
      _$AdminUserListItemFromJson(json);

  final String id;
  final String phone;
  final String? name;
  final UserRole role;
  final UserStatus status;
  final String? cityName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$AdminUserListItemToJson(this);
}

/// Detail complet d'un utilisateur pour l'admin.
@JsonSerializable(fieldRename: FieldRename.snake)
class AdminUserDetail {
  const AdminUserDetail({
    required this.id,
    required this.phone,
    this.name,
    required this.role,
    required this.status,
    this.cityName,
    required this.referralCode,
    required this.createdAt,
    required this.updatedAt,
    required this.totalOrders,
    required this.completionRate,
    required this.disputesFiled,
    required this.avgRating,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) =>
      _$AdminUserDetailFromJson(json);

  final String id;
  final String phone;
  final String? name;
  final UserRole role;
  final UserStatus status;
  final String? cityName;
  final String referralCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalOrders;
  final double completionRate;
  final int disputesFiled;
  final double avgRating;

  Map<String, dynamic> toJson() => _$AdminUserDetailToJson(this);
}
