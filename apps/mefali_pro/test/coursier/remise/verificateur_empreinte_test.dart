/// Tests unitaires du vérificateur d'empreintes **local** (T038, FR-040).
///
/// Ce que ces tests protègent : la capacité de Yao à valider une remise
/// **sans réseau**. Toute divergence d'encodage avec `socle::empreintes` côté
/// Rust ferait échouer hors ligne une remise que le serveur accepterait — et
/// personne ne s'en apercevrait avant le terrain.
///
/// Les vecteurs sont donc calculés ici avec la MÊME recette que le serveur
/// (`sha256(uuid_octets ‖ code)` pour le code, `sha256(jeton)` pour le jeton),
/// et non recopiés d'une exécution : un vecteur figé prouverait seulement que
/// le code n'a pas changé, pas qu'il est juste.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_pro/coursier/remise/verificateur_empreinte.dart';
import 'package:uuid/uuid.dart';

const _commande = '019fa000-0000-7000-8000-00000000000b';
const _autreCommande = '019fa000-0000-7000-8000-00000000000c';

String _hex(List<int> octets) =>
    octets.map((o) => o.toRadixString(16).padLeft(2, '0')).join();

/// Miroir Dart de `socle::empreinte_code(sel, code)`.
String _empreinteCode(String commandeId, String code) {
  final sel = UuidValue.fromString(commandeId).toBytes();
  return _hex(sha256.convert([...sel, ...utf8.encode(code)]).bytes);
}

/// Miroir Dart de `socle::empreinte_jeton(jeton)` — aucun sel : le jeton est
/// déjà un aléa long.
String _empreinteJeton(String jeton) =>
    _hex(sha256.convert(utf8.encode(jeton)).bytes);

VerificateurEmpreinte _verificateur({
  String commande = _commande,
  String code = '7341',
  String jeton = 'jeton-tres-long-et-aleatoire',
}) =>
    VerificateurEmpreinte(
      commandeId: commande,
      empreinteCode: _empreinteCode(commande, code),
      empreinteJeton: _empreinteJeton(jeton),
    );

void main() {
  test('le bon code passe, un code faux ne passe pas', () {
    final v = _verificateur();
    expect(v.codeCorrect('7341'), isTrue);
    expect(v.codeCorrect('7342'), isFalse);
    expect(v.codeCorrect(''), isFalse);
    expect(v.codeCorrect('73410'), isFalse);
  });

  test('le bon jeton passe, un jeton inventé ne passe pas', () {
    final v = _verificateur();
    expect(v.jetonCorrect('jeton-tres-long-et-aleatoire'), isTrue);
    expect(v.jetonCorrect('jeton-invente'), isFalse);
  });

  test(
    "le jeton d'une AUTRE commande est refusé — c'est le QR du client précédent",
    () {
      final v = _verificateur(jeton: 'jeton-de-la-commande-A');
      expect(v.jetonCorrect('jeton-de-la-commande-B'), isFalse);
    },
  );

  test(
    'le MÊME code sur deux commandes ne donne pas la même empreinte — le sel '
    'est la commande, sinon 10 000 empreintes suffiraient à tout ouvrir',
    () {
      expect(
        _empreinteCode(_commande, '7341'),
        isNot(_empreinteCode(_autreCommande, '7341')),
      );
      // Et un vérificateur monté sur le mauvais sel refuse systématiquement :
      // il ne produit JAMAIS de faux positif.
      final mauvaisSel = VerificateurEmpreinte(
        commandeId: _autreCommande,
        empreinteCode: _empreinteCode(_commande, '7341'),
        empreinteJeton: '',
      );
      expect(mauvaisSel.codeCorrect('7341'), isFalse);
    },
  );

  test(
    "une empreinte absente ne valide rien — un pré-provisionnement incomplet "
    "ne doit pas ouvrir la porte",
    () {
      const v = VerificateurEmpreinte(
        commandeId: _commande,
        empreinteCode: '',
        empreinteJeton: '',
      );
      expect(v.codeCorrect('7341'), isFalse);
      expect(v.jetonCorrect('quoi que ce soit'), isFalse);
    },
  );
}
