import 'package:json_annotation/json_annotation.dart';

import 'dispute.dart';

part 'dispute_detail.g.dart';

/// Evenement de la timeline d'une commande.
@JsonSerializable(fieldRename: FieldRename.snake)
class OrderTimelineEvent {
  const OrderTimelineEvent({
    required this.label,
    this.timestamp,
  });

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$OrderTimelineEventFromJson(json);

  final String label;
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => _$OrderTimelineEventToJson(this);
}

/// Statistiques d'un acteur (marchand ou livreur).
@JsonSerializable(fieldRename: FieldRename.snake)
class ActorStats {
  const ActorStats({
    this.name,
    required this.totalOrders,
    required this.totalDisputes,
  });

  factory ActorStats.fromJson(Map<String, dynamic> json) =>
      _$ActorStatsFromJson(json);

  final String? name;
  final int totalOrders;
  final int totalDisputes;

  Map<String, dynamic> toJson() => _$ActorStatsToJson(this);
}

/// Detail complet d'un litige pour l'admin.
@JsonSerializable(fieldRename: FieldRename.snake)
class DisputeDetail {
  const DisputeDetail({
    required this.dispute,
    required this.timeline,
    required this.merchantStats,
    this.driverStats,
  });

  factory DisputeDetail.fromJson(Map<String, dynamic> json) =>
      _$DisputeDetailFromJson(json);

  final Dispute dispute;
  final List<OrderTimelineEvent> timeline;
  final ActorStats merchantStats;
  final ActorStats? driverStats;

  Map<String, dynamic> toJson() => _$DisputeDetailToJson(this);
}

/// Element de la liste des litiges cote admin.
@JsonSerializable(fieldRename: FieldRename.snake)
class AdminDisputeListItem {
  const AdminDisputeListItem({
    required this.id,
    required this.orderId,
    required this.reporterId,
    required this.disputeType,
    required this.status,
    this.description,
    required this.createdAt,
    this.reporterName,
    required this.reporterPhone,
    this.merchantName,
    required this.orderTotal,
  });

  factory AdminDisputeListItem.fromJson(Map<String, dynamic> json) =>
      _$AdminDisputeListItemFromJson(json);

  final String id;
  final String orderId;
  final String reporterId;
  final DisputeType disputeType;
  final DisputeStatus status;
  final String? description;
  final DateTime createdAt;
  final String? reporterName;
  final String reporterPhone;
  final String? merchantName;
  final int orderTotal;

  Map<String, dynamic> toJson() => _$AdminDisputeListItemToJson(this);
}

/// Action de resolution d'un litige.
enum ResolveAction {
  @JsonValue('credit')
  credit,
  @JsonValue('warn')
  warn,
  @JsonValue('dismiss')
  dismiss;

  String get label {
    switch (this) {
      case ResolveAction.credit:
        return 'Crediter le client';
      case ResolveAction.warn:
        return 'Avertir';
      case ResolveAction.dismiss:
        return 'Classer sans suite';
    }
  }
}

/// Request body pour resoudre un litige.
@JsonSerializable(fieldRename: FieldRename.snake)
class ResolveDisputeRequest {
  const ResolveDisputeRequest({
    required this.action,
    required this.resolution,
    this.creditAmount,
  });

  factory ResolveDisputeRequest.fromJson(Map<String, dynamic> json) =>
      _$ResolveDisputeRequestFromJson(json);

  final ResolveAction action;
  final String resolution;
  final int? creditAmount;

  Map<String, dynamic> toJson() => _$ResolveDisputeRequestToJson(this);
}
