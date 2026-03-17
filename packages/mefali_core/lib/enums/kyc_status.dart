import 'package:json_annotation/json_annotation.dart';

/// Statuts de verification KYC.
enum KycStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('verified')
  verified,
  @JsonValue('rejected')
  rejected;

  String get label {
    switch (this) {
      case KycStatus.pending:
        return 'En attente';
      case KycStatus.verified:
        return 'Verifie';
      case KycStatus.rejected:
        return 'Rejete';
    }
  }
}
