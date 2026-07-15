import 'package:flutter/foundation.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Rôle PROFESSIONNEL : les deux seuls que Mefali Pro sert (FR-013).
///
/// `client` et `admin` existent aussi côté backend mais n'ont rien à faire ici —
/// le premier vit dans l'app client, le second dans la console d'administration
/// (cycle ADM). Un compte qui ne porte QUE ces rôles-là n'a aucun rôle pro.
enum RolePro {
  /// Demandé in-app avec un dossier, validé par un admin (CPT-04).
  coursier('coursier'),

  /// Attribué par un admin à l'agrément — jamais demandé in-app (§5.1).
  vendeur('vendeur');

  const RolePro(this.valeur);

  /// Valeur de l'énum `comptes.role` du backend : c'est du PROTOCOLE, jamais
  /// affiché. Les libellés sont des clés i18n (FR-024).
  final String valeur;

  /// Rôle correspondant à une valeur du contrat, ou `null` si elle ne concerne
  /// pas Mefali Pro (`client`, `admin`, ou un rôle plus récent que cette app).
  static RolePro? depuis(String valeur) {
    for (final role in values) {
      if (role.valeur == valeur) return role;
    }
    return null;
  }
}

/// Statut d'une attribution (énum `comptes.statut_role`), plus son absence.
enum StatutRolePro {
  /// Aucune attribution : le rôle n'a jamais été demandé ni attribué. N'existe
  /// pas côté backend — c'est l'absence de ligne, que FR-013 doit présenter au
  /// même titre que les autres états.
  aucun(''),

  /// Dossier déposé, décision admin attendue.
  enAttente('en_attente'),

  /// Rôle ouvert : la seule porte d'entrée de Mefali Pro.
  valide('valide'),

  /// Demande refusée — le motif accompagne la décision (FR-017).
  refuse('refuse'),

  /// Rôle retiré temporairement, motif à l'appui.
  suspendu('suspendu');

  const StatutRolePro(this.valeur);

  /// Valeur du contrat — protocole, jamais affichée.
  final String valeur;

  /// Statut correspondant à une valeur du contrat.
  ///
  /// Une valeur INCONNUE retombe sur `aucun`, jamais sur `valide` : si un
  /// backend plus récent invente un statut, cette app doit fermer la porte, pas
  /// l'ouvrir (SC-005).
  static StatutRolePro depuis(String valeur) {
    for (final statut in values) {
      if (statut != aucun && statut.valeur == valeur) return statut;
    }
    return aucun;
  }
}

/// État d'un rôle pro tel que le backend le décrit.
@immutable
class AttributionPro {
  /// Crée un état de rôle.
  const AttributionPro({required this.role, required this.statut, this.motif});

  /// Rôle concerné.
  final RolePro role;

  /// Statut courant de l'attribution.
  final StatutRolePro statut;

  /// Motif de la dernière décision admin (refus, suspension).
  ///
  /// CONTENU saisi par l'admin, pas une clé i18n : il s'affiche tel quel.
  final String? motif;
}

/// Rôles du compte connecté, et rôle dont Mefali Pro affiche l'interface.
///
/// ## Pourquoi la bascule ne parle pas au réseau
///
/// FR-013 exige de passer d'une interface à l'autre « sans reconnexion », en
/// moins de 5 secondes (SC-006). Les rôles validés sont déjà en mémoire depuis
/// le chargement : [basculer] ne fait que changer le rôle affiché et notifier —
/// aucune requête, aucun jeton touché. C'est ce qui rend le critère tenable sur
/// un réseau intermittent, et non une optimisation.
///
/// Convention de l'app : `ChangeNotifier` nu (ni Provider ni Riverpod), passé
/// par constructeur et consommé via `ListenableBuilder`, comme [SessionAuth].
class EtatRoles extends ChangeNotifier {
  /// Crée l'état, adossé à la session qui porte le client authentifié.
  EtatRoles({required this.session});

  /// Session du compte connecté.
  final SessionAuth session;

  List<AttributionPro> _attributions = const [];
  bool _charge = false;
  bool _enErreur = false;
  RolePro? _actif;

  /// Le compte a-t-il été relu au moins une fois (succès ou échec) ?
  bool get charge => _charge;

  /// Le dernier chargement a-t-il échoué (réseau, serveur) ?
  bool get enErreur => _enErreur;

  /// Tous les rôles pro du compte, quel que soit leur statut.
  List<AttributionPro> get attributions => List.unmodifiable(_attributions);

  /// Rôles pro VALIDÉS — la seule porte d'entrée de Mefali Pro (FR-011).
  ///
  /// L'ordre suit celui du backend (ordre de l'énum : coursier avant vendeur),
  /// donc il est stable d'un chargement à l'autre.
  List<RolePro> get rolesValides => _attributions
      .where((a) => a.statut == StatutRolePro.valide)
      .map((a) => a.role)
      .toList(growable: false);

  /// Rôle dont l'interface est affichée, ou `null` si aucun rôle pro validé.
  RolePro? get actif => _actif;

  /// Statut d'un rôle pro — `aucun` s'il n'a jamais été demandé ni attribué.
  StatutRolePro statut(RolePro role) {
    for (final attribution in _attributions) {
      if (attribution.role == role) return attribution.statut;
    }
    return StatutRolePro.aucun;
  }

  /// Motif de la dernière décision admin sur un rôle, s'il y en a une.
  String? motif(RolePro role) {
    for (final attribution in _attributions) {
      if (attribution.role == role) return attribution.motif;
    }
    return null;
  }

  /// Relit `GET /moi` et recalcule les rôles.
  ///
  /// Le contrôle qui FAIT foi est celui du serveur, à chaque requête (FR-009) :
  /// ce que l'on tient ici n'est qu'un reflet, rafraîchi à l'ouverture et à la
  /// demande. Une suspension prise pendant que l'app est ouverte sera refusée
  /// côté serveur même si cet écran l'ignore encore.
  Future<void> charger() async {
    _charge = false;
    _enErreur = false;
    notifyListeners();

    try {
      final reponse = await session.client.getMoiApi().moi();
      final compte = reponse.data;
      final attributions = <AttributionPro>[];
      for (final etat in compte?.roles ?? const <EtatRoleDto>[]) {
        final role = RolePro.depuis(etat.role);
        if (role == null) continue; // client / admin : hors Mefali Pro.
        attributions.add(
          AttributionPro(
            role: role,
            statut: StatutRolePro.depuis(etat.statut),
            motif: etat.motif,
          ),
        );
      }
      _attributions = attributions;

      // On CONSERVE le rôle affiché s'il est toujours validé : un
      // rafraîchissement ne doit pas ramener l'utilisateur à l'autre interface
      // sous ses doigts. Sinon (premier chargement, ou rôle affiché suspendu
      // entre-temps), on retombe sur le premier rôle validé.
      final valides = rolesValides;
      if (_actif == null || !valides.contains(_actif)) {
        _actif = valides.isEmpty ? null : valides.first;
      }
    } catch (_) {
      // Réseau coupé ou serveur en vrac : on le DIT (règle d'or 5), on ne
      // laisse pas un écran blanc ni une liste de rôles vide qui se lirait
      // comme « votre demande n'existe pas ».
      _enErreur = true;
    }

    _charge = true;
    notifyListeners();
  }

  /// Affiche l'interface d'un autre rôle validé (FR-013).
  ///
  /// Un rôle non validé est ignoré : la bascule n'est pas un chemin de
  /// contournement de la validation admin (SC-005).
  void basculer(RolePro role) {
    if (_actif == role || !rolesValides.contains(role)) return;
    _actif = role;
    notifyListeners();
  }
}
