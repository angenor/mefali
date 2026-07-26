/// Traduction des refus de l'API commandes (cycle CMD 008).
///
/// L'API rend `{ code, message_cle }` — jamais une phrase (constitution VII).
/// C'est ici, et **uniquement ici**, que la clé devient du texte : un écran qui
/// composerait son propre message dériverait du serveur au premier changement
/// de règle, et deux écrans en composeraient deux différents pour le même refus.
///
/// Une clé INCONNUE rend le message générique plutôt que la clé elle-même : un
/// serveur plus récent que l'app est un cas normal (Shorebird patche le Dart,
/// pas le backend), et le client ne doit jamais lire `commande.erreur.xxx`.
library;

import '../../l10n/mefali_core_localizations.dart';

/// Rend le message affichable d'un refus de l'API commandes.
///
/// Accepte indifféremment le `code` court (`compte_bloque`) ou la
/// `message_cle` complète (`commande.erreur.compte_bloque`) — les deux
/// circulent dans le corps d'erreur, et exiger l'un ou l'autre serait un piège.
String messageErreurCommande(MefaliCoreLocalizations l10n, String? cleOuCode) {
  final code = (cleOuCode ?? '').split('.').last;
  return switch (code) {
    'compte_bloque' => l10n.commandeErreurCompteBloque,
    'categorie_non_mixable' => l10n.commandeErreurCategorieNonMixable,
    'repere_manquant' => l10n.commandeErreurRepereManquant,
    'telephone_non_verifie' => l10n.commandeErreurTelephoneNonVerifie,
    'vendeur_indisponible' => l10n.commandeErreurVendeurIndisponible,
    'article_indisponible' => l10n.commandeErreurArticleIndisponible,
    'cash_indisponible' => l10n.commandeErreurCashIndisponible,
    'transition_refusee' => l10n.commandeErreurTransitionRefusee,
    'non_proprietaire' => l10n.commandeErreurNonProprietaire,
    'commande_inconnue' => l10n.commandeErreurCommandeInconnue,
    'panier_invalide' => l10n.commandeErreurPanierInvalide,
    'motif_requis' => l10n.commandeErreurMotifRequis,
    'code_epuise' => l10n.commandeErreurCodeEpuise,
    'remise_incorrecte' => l10n.commandeErreurRemiseIncorrecte,
    'preuves_incompletes' => l10n.commandeErreurPreuvesIncompletes,
    'substitution_autre_vendeur' => l10n.substitutionErreurAutreVendeur,
    'substitution_ecart_prix' => l10n.substitutionErreurEcartPrix,
    'substitution_expiree' => l10n.substitutionErreurExpiree,
    // Inclut `erreur_interne` et tout code qu'une version plus récente du
    // serveur pourrait introduire.
    _ => l10n.commandeErreurInterne,
  };
}
