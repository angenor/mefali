import 'package:json_annotation/json_annotation.dart';

import '../enums/vendor_status.dart';

part 'restaurant_summary.g.dart';

/// Résumé d'un restaurant pour l'écran de découverte B2C.
/// Seuls les marchands avec onboarding_step = 5 sont retournés par l'API.
@JsonSerializable(fieldRename: FieldRename.snake)
class RestaurantSummary {
  const RestaurantSummary({
    required this.id,
    required this.name,
    this.address,
    required this.status,
    this.category,
    this.photoUrl,
    this.cityId,
    required this.avgRating,
    required this.totalRatings,
    required this.deliveryFee,
  });

  factory RestaurantSummary.fromJson(Map<String, dynamic> json) =>
      _$RestaurantSummaryFromJson(json);

  final String id;
  final String name;
  final String? address;
  final VendorStatus status;
  final String? category;
  final String? photoUrl;
  final String? cityId;

  /// Note moyenne sur 5 (0.0 si aucune note).
  final double avgRating;

  /// Nombre total d'avis.
  final int totalRatings;

  /// Frais de livraison en centimes (50000 = 500 FCFA).
  final int deliveryFee;
}
