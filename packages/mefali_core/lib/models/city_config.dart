import 'package:json_annotation/json_annotation.dart';

part 'city_config.g.dart';

/// Configuration d'une ville avec multiplicateur de livraison et zones.
@JsonSerializable(fieldRename: FieldRename.snake)
class CityConfig {
  final String id;
  final String cityName;
  final double deliveryMultiplier;
  final Map<String, dynamic>? zonesGeojson;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CityConfig({
    required this.id,
    required this.cityName,
    required this.deliveryMultiplier,
    this.zonesGeojson,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CityConfig.fromJson(Map<String, dynamic> json) =>
      _$CityConfigFromJson(json);
  Map<String, dynamic> toJson() => _$CityConfigToJson(this);
}
