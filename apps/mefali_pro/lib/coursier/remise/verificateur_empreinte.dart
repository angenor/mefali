import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Vérification **locale** des secrets de remise, sans le moindre appel réseau
/// (FR-040, CRS-04).
///
/// Le coursier ne reçoit jamais le code ni le jeton : il en reçoit les
/// **empreintes** au pré-provisionnement (R3), et compare ici ce que le client
/// lui présente. C'est ce qui lui permet de partir sans attendre le réseau.
///
/// ⚠ **Ce que cette classe ne fait PAS** : décider. Une correspondance locale
/// est une autorisation à continuer, jamais une clôture — le serveur revalide la
/// preuve au rejeu (FR-046, R7). Deux conséquences assumées :
///
/// 1. l'empreinte d'un code à **4 chiffres**, salée par un identifiant que
///    l'app connaît, se casse en 10 000 hachages. Le risque est **assumé** (R7)
///    et encadré : la remise porte son mode et son caractère hors ligne, et le
///    jeton QR — aléa long — reste inattaquable ;
/// 2. le compteur d'essais que cette classe alimente est **local** ; le serveur
///    retient `max(serveur, local)` au rejeu (R5).
///
/// Miroir exact de `socle::empreintes` côté Rust : toute divergence
/// d'encodage ferait échouer hors ligne une remise que le serveur accepterait.
class VerificateurEmpreinte {
  /// Crée un vérificateur pour une commande donnée.
  ///
  /// [commandeId] est le **sel** du code de remise — c'est l'identifiant de la
  /// commande côté serveur (`empreinte_code(demande.id, code)`). Un sel faux
  /// ne produit jamais de faux positif : il produit un refus systématique.
  const VerificateurEmpreinte({
    required this.commandeId,
    required this.empreinteCode,
    required this.empreinteJeton,
  });

  /// Commande porteuse — sel de l'empreinte du code.
  final String commandeId;

  /// base16(sha256(commande_id ‖ code)) — jamais le code.
  final String empreinteCode;

  /// base16(sha256(jeton)) — jamais le jeton.
  final String empreinteJeton;

  /// Le code à 4 chiffres dicté par le client correspond-il ?
  ///
  /// Un code vide n'est pas « faux » au sens du compteur : c'est une saisie
  /// incomplète. L'appelant décide de consommer un essai ou non ; ici on ne
  /// répond qu'à la question posée.
  bool codeCorrect(String code) {
    if (empreinteCode.isEmpty) return false;
    final sel = UuidValue.fromString(commandeId).toBytes();
    final calculee = _hex(sha256.convert([...sel, ...utf8.encode(code)]).bytes);
    return _egaliteConstante(calculee, empreinteCode);
  }

  /// Le jeton lu dans le QR du client correspond-il ?
  ///
  /// Le jeton d'une **autre** commande ne passe pas : son empreinte est celle
  /// d'un autre aléa. C'est le cas qu'un coursier pressé pourrait produire en
  /// scannant le QR du client précédent.
  bool jetonCorrect(String jeton) {
    if (empreinteJeton.isEmpty) return false;
    final calculee = _hex(sha256.convert(utf8.encode(jeton)).bytes);
    return _egaliteConstante(calculee, empreinteJeton);
  }

  /// Hexadécimal base16 minuscule — format des empreintes serveur.
  static String _hex(List<int> octets) =>
      octets.map((o) => o.toRadixString(16).padLeft(2, '0')).join();

  /// Comparaison à **temps constant**.
  ///
  /// Sur un secret à quatre chiffres, un `==` qui s'arrête au premier caractère
  /// différent donnerait, en principe, un oracle chiffre par chiffre. La menace
  /// est théorique sur un téléphone — mais l'écrire ainsi ne coûte rien, et
  /// l'écrire autrement demanderait de justifier pourquoi.
  static bool _egaliteConstante(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}
