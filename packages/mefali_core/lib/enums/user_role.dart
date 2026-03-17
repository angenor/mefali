import 'package:json_annotation/json_annotation.dart';

/// Roles disponibles pour les utilisateurs mefali.
@JsonEnum(fieldRename: FieldRename.snake)
enum UserRole { client, merchant, driver, agent, admin }
