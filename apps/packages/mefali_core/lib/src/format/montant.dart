/// Formatage des montants (docs/design/tokens.md — « Montant : FCFA en
/// entier, espace fine comme séparateur de milliers → `5 800 FCFA` »).
///
/// Un montant est TOUJOURS un entier d'unités mineures accompagné de son code
/// ISO 4217 (constitution III) — jamais un `double`. Créé au cycle 005 pour
/// les écrans vendeur V1/V2 ; la fiche vendeur du client (cycle CMD)
/// consommera le même helper.
library;

/// Espace fine insécable — le séparateur de milliers des maquettes.
const String espaceFine = ' ';

/// Libellé d'affichage d'une devise ISO 4217 : XOF s'écrit « FCFA » partout
/// dans le produit ; toute autre devise s'affiche par son code.
String libelleDevise(String devise) => devise == 'XOF' ? 'FCFA' : devise;

/// « 5 800 FCFA » — entier groupé par milliers, suffixe de devise.
String formaterMontant(int unites, String devise) =>
    '${grouperMilliers(unites)}$espaceFine${libelleDevise(devise)}';

/// Groupe un entier par milliers avec l'espace fine (« 1 500 », « 12 000 »).
String grouperMilliers(int valeur) {
  final negatif = valeur < 0;
  final chiffres = valeur.abs().toString();
  final tampon = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) {
      tampon.write(espaceFine);
    }
    tampon.write(chiffres[i]);
  }
  return '${negatif ? '-' : ''}$tampon';
}
