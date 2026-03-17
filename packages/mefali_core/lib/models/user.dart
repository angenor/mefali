import 'package:json_annotation/json_annotation.dart';

import '../enums/user_role.dart';
import '../enums/user_status.dart';

part 'user.g.dart';

/// Modele utilisateur retourne par l'API.
@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  const User({
    required this.id,
    required this.phone,
    this.name,
    required this.role,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  final String id;
  final String phone;
  final String? name;
  final UserRole role;
  final UserStatus status;

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
