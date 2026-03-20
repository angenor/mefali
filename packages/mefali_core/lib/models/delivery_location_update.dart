/// Mise a jour de position du livreur pour le tracking temps reel.
class DeliveryLocationUpdate {
  const DeliveryLocationUpdate({
    required this.lat,
    required this.lng,
    required this.etaSeconds,
    required this.updatedAt,
    this.driverName,
    this.driverPhone,
    this.status,
    this.isFallback = false,
  });

  final double lat;
  final double lng;
  final int etaSeconds;
  final String updatedAt;
  final String? driverName;
  final String? driverPhone;
  final String? status;

  /// True si cette update vient du polling HTTP (WebSocket deconnecte).
  final bool isFallback;

  factory DeliveryLocationUpdate.fromJson(Map<String, dynamic> json) {
    return DeliveryLocationUpdate(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      etaSeconds: (json['eta_seconds'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] as String? ?? '',
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'eta_seconds': etaSeconds,
        'updated_at': updatedAt,
        if (driverName != null) 'driver_name': driverName,
        if (driverPhone != null) 'driver_phone': driverPhone,
        if (status != null) 'status': status,
        'is_fallback': isFallback,
      };
}
