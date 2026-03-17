import 'package:json_annotation/json_annotation.dart';

import '../enums/kyc_document_type.dart';
import '../enums/kyc_status.dart';

part 'kyc_document.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class KycDocument {
  const KycDocument({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.encryptedPath,
    this.verifiedBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) =>
      _$KycDocumentFromJson(json);

  final String id;
  final String userId;
  final KycDocumentType documentType;
  final String encryptedPath;
  final String? verifiedBy;
  final KycStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$KycDocumentToJson(this);
}
