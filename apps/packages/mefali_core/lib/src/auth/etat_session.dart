import 'package:flutter/foundation.dart';

import 'stockage_jetons.dart';

/// État de session. Classe IMMUABLE, volontairement SANS `operator ==`.
///
/// Un `record` ou une classe à égalité structurelle ferait qu'un `ouvrir()` aux
/// MÊMES jetons émettrait 0 au lieu de 1 (`JetonsSession` implémente déjà `==`,
/// `stockage_jetons.dart`) — FR-003. Son `Notifier` (`Session`) et le
/// `updateShouldNotify => true` explicite naissent en US2 ; ici, seule la valeur.
@immutable
class EtatSession {
  /// État courant : chargé ou non, avec ou sans jetons.
  const EtatSession({required this.charge, this.jetons});

  /// État au lancement : stockage pas encore relu, aucun jeton.
  const EtatSession.initiale() : charge = false, jetons = null;

  /// `true` une fois le stockage relu. NE REDEVIENT JAMAIS `false` (FR-022).
  ///
  /// `charge` FAIT PARTIE DE LA VALEUR, comme `_charge` est un champ aujourd'hui
  /// (`session_auth.dart:28`). Si l'état était un `JetonsSession?` nu, `charger()`
  /// sur un stockage VIDE ferait `null → null` ⇒ AUCUNE émission ⇒ `RacineAuth`
  /// ne quitterait JAMAIS l'écran de démarrage.
  final bool charge;

  /// Jetons détenus, ou `null` si aucune session ouverte.
  final JetonsSession? jetons;

  /// `true` dès que des jetons sont détenus.
  bool get connecte => jetons != null;

  /// Jeton d'accès courant, ou `null`.
  String? get acces => jetons?.acces;

  /// Jeton de renouvellement courant, ou `null`.
  String? get rafraichissement => jetons?.rafraichissement;
}
