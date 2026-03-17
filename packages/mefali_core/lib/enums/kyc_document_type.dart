import 'package:json_annotation/json_annotation.dart';

/// Types de documents KYC acceptes.
enum KycDocumentType {
  @JsonValue('cni')
  cni,
  @JsonValue('permis')
  permis;

  String get label {
    switch (this) {
      case KycDocumentType.cni:
        return 'CNI';
      case KycDocumentType.permis:
        return 'Permis';
    }
  }
}
