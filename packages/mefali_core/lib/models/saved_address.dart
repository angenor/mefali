/// Adresse de livraison sauvegardee localement.
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.address,
    required this.lat,
    required this.lng,
    required this.lastUsedAt,
    this.label,
  });

  final String id;
  final String address;
  final double lat;
  final double lng;
  final DateTime lastUsedAt;
  final String? label;
}
