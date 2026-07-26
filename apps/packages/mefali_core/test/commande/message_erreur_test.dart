/// T064 — la boucle i18n des refus de l'API commandes est FERMÉE.
///
/// L'API rend `{ code, message_cle }` ; ce test vérifie que chaque code du
/// mapping serveur (`api/src/erreurs_commandes.rs`) trouve son texte, et
/// qu'aucun chemin ne laisse fuir une clé technique jusqu'à l'écran.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/mefali_core.dart';

/// Les 19 codes de refus que l'API peut rendre sur ses trois surfaces.
const _codes = [
  'compte_bloque',
  'categorie_non_mixable',
  'repere_manquant',
  'telephone_non_verifie',
  'vendeur_indisponible',
  'article_indisponible',
  'cash_indisponible',
  // Refus 409 de TRF relayé par CMD : la grille de la zone ne couvre pas ce
  // trajet. C'était un 500 muet avant la passe émulateur du 2026-07-26.
  'tarif_indisponible',
  'transition_refusee',
  'non_proprietaire',
  'commande_inconnue',
  'panier_invalide',
  'motif_requis',
  'code_epuise',
  'remise_incorrecte',
  'preuves_incompletes',
  'substitution_autre_vendeur',
  'substitution_ecart_prix',
  'substitution_expiree',
];

void main() {
  late MefaliCoreLocalizations l10n;

  setUpAll(() async {
    l10n = await MefaliCoreLocalizations.delegate.load(const Locale('fr'));
  });

  test('chaque code de refus a SON texte, distinct du générique', () {
    final generique = messageErreurCommande(l10n, 'erreur_interne');
    for (final code in _codes) {
      final message = messageErreurCommande(l10n, code);
      expect(
        message,
        isNot(generique),
        reason: '« $code » doit avoir son message propre, pas le générique',
      );
      expect(message, isNot(contains('commande.erreur')));
      expect(message.trim(), isNotEmpty);
    }
  });

  test('la clé COMPLÈTE et le code court donnent le même texte', () {
    for (final code in _codes) {
      expect(
        messageErreurCommande(l10n, 'commande.erreur.$code'),
        messageErreurCommande(l10n, code),
        reason: "les deux formes circulent dans le corps d'erreur ; exiger "
            "l'une ou l'autre serait un piège",
      );
    }
  });

  test('un code INCONNU rend le générique, jamais la clé brute', () {
    // Un serveur plus récent que l'app est un cas NORMAL : Shorebird patche le
    // Dart, pas le backend.
    final generique = messageErreurCommande(l10n, 'erreur_interne');
    for (final inconnu in ['', 'code_du_futur', 'commande.erreur.inedit']) {
      expect(messageErreurCommande(l10n, inconnu), generique);
    }
    expect(messageErreurCommande(l10n, null), generique);
  });
}
