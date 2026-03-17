import 'package:json_annotation/json_annotation.dart';

import 'user.dart';

part 'auth_response.g.dart';

/// Reponse du endpoint verify-otp contenant les tokens et l'utilisateur.
@JsonSerializable(fieldRename: FieldRename.snake)
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  final String accessToken;
  final String refreshToken;
  final User user;

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
