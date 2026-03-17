/// Categories de marchands disponibles pour l'onboarding.
enum MerchantCategory {
  restaurant,
  maquis,
  boulangerie,
  epicerie,
  jusBoissons,
  autre;

  String get label {
    switch (this) {
      case MerchantCategory.restaurant:
        return 'Restaurant';
      case MerchantCategory.maquis:
        return 'Maquis';
      case MerchantCategory.boulangerie:
        return 'Boulangerie';
      case MerchantCategory.epicerie:
        return 'Epicerie';
      case MerchantCategory.jusBoissons:
        return 'Jus / Boissons';
      case MerchantCategory.autre:
        return 'Autre';
    }
  }

  /// Valeur envoyee a l'API (snake_case).
  String get apiValue => name;

  /// Parse depuis la valeur API.
  static MerchantCategory? fromApi(String? value) {
    if (value == null) return null;
    return MerchantCategory.values.cast<MerchantCategory?>().firstWhere(
      (e) => e?.name == value,
      orElse: () => null,
    );
  }
}
