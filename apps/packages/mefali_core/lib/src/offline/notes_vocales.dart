/// Notes vocales de repère, gardées EN LOCAL pour être jouables sans réseau
/// (FR-024, SC-012).
///
/// Le serveur ne sert que des URL présignées, qui expirent en dix minutes —
/// c'est-à-dire précisément au moment où Yao en a besoin, devant un portail,
/// sans réseau. Le fichier est donc rapatrié dès que la course est connue, et
/// c'est le CHEMIN LOCAL qui alimente le lecteur.
///
/// Rien ici ne remonte : une note vocale est une donnée personnelle du client
/// (constitution VIII). Elle vit le temps de la course et [effacer] la retire
/// à la clôture, avec le reste du cache.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Rapatrie et efface les notes vocales de repère.
class NotesVocalesLocales {
  /// Crée le dépôt local.
  const NotesVocalesLocales();

  /// Sous-dossier dédié : il se vide d'un bloc si besoin, et ne se mélange
  /// jamais aux photos de preuve, dont la rétention est autre.
  static const _dossier = 'reperes_vocaux';

  /// Rapatrie la note d'une course et rend son chemin local.
  ///
  /// Rend `null` — jamais une exception — si l'URL manque ou si le
  /// téléchargement échoue : une note absente dégrade l'écran (le repère écrit
  /// reste), une exception ferait tomber le chargement de la course entière.
  ///
  /// Si le fichier est DÉJÀ là, il est rendu tel quel : la course se recharge à
  /// chaque retour de réseau, et retélécharger la même note à chaque fois
  /// coûterait de la donnée mobile pour rien.
  Future<String?> rapatrier({
    required String? url,
    required String cle,
    required Dio dio,
  }) async {
    if (url == null || url.isEmpty) return null;
    try {
      final dossier = Directory('${(await getApplicationSupportDirectory()).path}'
          '/$_dossier');
      await dossier.create(recursive: true);
      final fichier = File('${dossier.path}/$cle');
      if (await fichier.exists() && await fichier.length() > 0) {
        return fichier.path;
      }
      final reponse = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final octets = reponse.data;
      if (octets == null || octets.isEmpty) return null;
      await fichier.writeAsBytes(octets, flush: true);
      return fichier.path;
    } on Exception {
      return null;
    }
  }

  /// Efface la note d'une course terminée (R6 — rien du client ne reste).
  Future<void> effacer(String cle) async {
    try {
      final fichier = File('${(await getApplicationSupportDirectory()).path}'
          '/$_dossier/$cle');
      if (await fichier.exists()) await fichier.delete();
    } on Exception {
      // Un fichier qu'on n'arrive pas à supprimer ne doit pas empêcher la
      // clôture de la course : le dossier est purgé au prochain rapatriement.
    }
  }
}
