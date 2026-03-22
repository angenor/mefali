import 'package:json_annotation/json_annotation.dart';

part 'sponsorship.g.dart';

/// Statut du parrainage.
enum SponsorshipStatus {
  @JsonValue('active')
  active,
  @JsonValue('suspended')
  suspended,
  @JsonValue('terminated')
  terminated;

  String get label {
    switch (this) {
      case SponsorshipStatus.active:
        return 'Actif';
      case SponsorshipStatus.suspended:
        return 'Suspendu';
      case SponsorshipStatus.terminated:
        return 'Termine';
    }
  }
}

/// Filleul (sponsored driver) dans la liste des parrainages.
@JsonSerializable(fieldRename: FieldRename.snake)
class SponsoredDriver {
  const SponsoredDriver({
    required this.id,
    this.name,
    required this.phone,
    required this.status,
    required this.createdAt,
  });

  factory SponsoredDriver.fromJson(Map<String, dynamic> json) =>
      _$SponsoredDriverFromJson(json);

  final String id;
  final String? name;
  final String phone;
  final SponsorshipStatus status;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$SponsoredDriverToJson(this);
}

/// Reponse de GET /api/v1/sponsorships/me.
@JsonSerializable(fieldRename: FieldRename.snake)
class MySponsorshipsResponse {
  const MySponsorshipsResponse({
    required this.maxSponsorships,
    required this.activeCount,
    required this.remainingSlots,
    required this.canSponsor,
    required this.sponsoredDrivers,
  });

  factory MySponsorshipsResponse.fromJson(Map<String, dynamic> json) =>
      _$MySponsorshipsResponseFromJson(json);

  final int maxSponsorships;
  final int activeCount;
  final int remainingSlots;
  final bool canSponsor;
  final List<SponsoredDriver> sponsoredDrivers;

  Map<String, dynamic> toJson() => _$MySponsorshipsResponseToJson(this);
}

/// Info sur le parrain du driver connecte.
@JsonSerializable(fieldRename: FieldRename.snake)
class SponsorInfo {
  const SponsorInfo({
    required this.id,
    this.name,
    required this.phone,
    required this.sponsorshipStatus,
    required this.sponsoredAt,
  });

  factory SponsorInfo.fromJson(Map<String, dynamic> json) =>
      _$SponsorInfoFromJson(json);

  final String id;
  final String? name;
  final String phone;
  final SponsorshipStatus sponsorshipStatus;
  final DateTime sponsoredAt;

  Map<String, dynamic> toJson() => _$SponsorInfoToJson(this);
}
