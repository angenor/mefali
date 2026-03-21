import 'package:json_annotation/json_annotation.dart';

part 'dispute.g.dart';

/// Type de litige.
enum DisputeType {
  @JsonValue('incomplete')
  incomplete,
  @JsonValue('quality')
  quality,
  @JsonValue('wrong_order')
  wrongOrder,
  @JsonValue('other')
  other;

  String get label {
    switch (this) {
      case DisputeType.incomplete:
        return 'Commande incomplete';
      case DisputeType.quality:
        return 'Probleme de qualite';
      case DisputeType.wrongOrder:
        return 'Mauvaise commande';
      case DisputeType.other:
        return 'Autre';
    }
  }
}

/// Statut du litige.
enum DisputeStatus {
  @JsonValue('open')
  open,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('resolved')
  resolved,
  @JsonValue('closed')
  closed;

  String get label {
    switch (this) {
      case DisputeStatus.open:
        return 'Litige en cours';
      case DisputeStatus.inProgress:
        return 'En traitement';
      case DisputeStatus.resolved:
        return 'Resolu';
      case DisputeStatus.closed:
        return 'Ferme';
    }
  }
}

/// Dispute record returned by the API.
@JsonSerializable(fieldRename: FieldRename.snake)
class Dispute {
  const Dispute({
    required this.id,
    required this.orderId,
    required this.reporterId,
    required this.disputeType,
    required this.status,
    this.description,
    this.resolution,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) =>
      _$DisputeFromJson(json);

  final String id;
  final String orderId;
  final String reporterId;
  final DisputeType disputeType;
  final DisputeStatus status;
  final String? description;
  final String? resolution;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$DisputeToJson(this);
}

/// Request body for creating a dispute.
@JsonSerializable(fieldRename: FieldRename.snake)
class CreateDisputeRequest {
  const CreateDisputeRequest({
    required this.disputeType,
    this.description,
  });

  factory CreateDisputeRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDisputeRequestFromJson(json);

  final DisputeType disputeType;
  final String? description;

  Map<String, dynamic> toJson() => _$CreateDisputeRequestToJson(this);
}
