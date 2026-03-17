import 'package:json_annotation/json_annotation.dart';

/// Statuts possibles d'un compte utilisateur.
@JsonEnum(fieldRename: FieldRename.snake)
enum UserStatus {
  active,
  @JsonValue('pending_kyc')
  pendingKyc,
  suspended,
  deactivated,
}
