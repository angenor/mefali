import 'package:json_annotation/json_annotation.dart';

import '../enums/vendor_status.dart';

part 'merchant.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Merchant {
  const Merchant({
    required this.id,
    required this.userId,
    required this.name,
    this.address,
    required this.status,
    this.effectiveStatus,
    this.cityId,
    required this.consecutiveNoResponse,
    this.photoUrl,
    this.category,
    required this.onboardingStep,
    this.createdByAgentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) =>
      _$MerchantFromJson(json);

  final String id;
  final String userId;
  final String name;
  final String? address;
  final VendorStatus status;
  final VendorStatus? effectiveStatus;
  final String? cityId;
  final int consecutiveNoResponse;
  final String? photoUrl;
  final String? category;
  final int onboardingStep;
  final String? createdByAgentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns the effective status if available, otherwise the actual status.
  VendorStatus get displayStatus => effectiveStatus ?? status;

  Map<String, dynamic> toJson() => _$MerchantToJson(this);
}
