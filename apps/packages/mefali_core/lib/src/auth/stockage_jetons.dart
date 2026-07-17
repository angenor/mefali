import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Paire de jetons d'une session d'appareil.
///
/// Type PROPRE au paquet, distinct du `JetonsDto` généré : le stockage local ne
/// doit pas se réécrire à chaque évolution du contrat OpenAPI.
class JetonsSession {
  /// Construit une paire de jetons.
  const JetonsSession({required this.acces, required this.rafraichissement});

  /// JWT d'accès (15 min).
  final String acces;

  /// Jeton de renouvellement opaque — tourne à chaque usage.
  final String rafraichissement;

  @override
  bool operator ==(Object other) =>
      other is JetonsSession &&
      other.acces == acces &&
      other.rafraichissement == rafraichissement;

  @override
  int get hashCode => Object.hash(acces, rafraichissement);
}

/// Conservation des jetons entre deux lancements de l'application.
abstract interface class StockageJetons {
  /// Jetons conservés, ou `null` si aucune session.
  Future<JetonsSession?> lire();

  /// Remplace les jetons conservés.
  Future<void> ecrire(JetonsSession jetons);

  /// Efface toute trace de session (déconnexion).
  Future<void> effacer();
}

/// Stockage CHIFFRÉ par le système (Keystore Android / Keychain iOS).
///
/// Jamais `shared_preferences` : le jeton de renouvellement n'a AUCUNE
/// expiration propre (clarification du 2026-07-14) — en clair sur le disque, il
/// vaudrait un accès permanent au compte pour qui lit le stockage de l'app.
class StockageJetonsSecurise implements StockageJetons {
  /// Construit le stockage sécurisé.
  const StockageJetonsSecurise([
    this._stockage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _stockage;

  static const String _cleAcces = 'mefali.session.acces';
  static const String _cleRafraichissement = 'mefali.session.rafraichissement';

  @override
  Future<JetonsSession?> lire() async {
    final acces = await _stockage.read(key: _cleAcces);
    final rafraichissement = await _stockage.read(key: _cleRafraichissement);
    if (acces == null || rafraichissement == null) return null;
    return JetonsSession(acces: acces, rafraichissement: rafraichissement);
  }

  @override
  Future<void> ecrire(JetonsSession jetons) async {
    await _stockage.write(key: _cleAcces, value: jetons.acces);
    await _stockage.write(
      key: _cleRafraichissement,
      value: jetons.rafraichissement,
    );
  }

  @override
  Future<void> effacer() async {
    await _stockage.delete(key: _cleAcces);
    await _stockage.delete(key: _cleRafraichissement);
  }
}

/// Stockage en MÉMOIRE — tests de widgets.
///
/// `flutter_secure_storage` passe par un canal de plateforme, indisponible dans
/// un test de widget : sans ce double, tout le parcours d'auth serait
/// intestable hors émulateur.
class StockageJetonsMemoire implements StockageJetons {
  /// Construit un stockage vide, ou déjà porteur d'une session.
  StockageJetonsMemoire([this._jetons]);

  JetonsSession? _jetons;

  @override
  Future<JetonsSession?> lire() async => _jetons;

  @override
  Future<void> ecrire(JetonsSession jetons) async => _jetons = jetons;

  @override
  Future<void> effacer() async => _jetons = null;
}
