/// Porteur de la **journée du coursier** (CRS-01, bandeau de K1-1a).
///
/// `AsyncNotifier` (moule des chargements, constitution XII) : une lecture de
/// `GET /moi/journee`, pas un processus qui dure. `@riverpod` nu — les gains
/// bougent à chaque course livrée, et un `keepAlive` afficherait le total d'il
/// y a deux heures à un coursier qui vient d'en finir une.
///
/// **Silencieux par construction.** Un réseau muet ne fait pas d'erreur : le
/// bandeau disparaît, et K1 reste utilisable — c'est l'écran depuis lequel Yao
/// se met en ligne, et le bloquer sur un chargement de gains lui coûterait des
/// courses. La caisse, elle, a son cache : ce sont deux exigences différentes
/// (FR-076 vaut pour K5, pas pour ce bandeau).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'etat_journee.g.dart';

/// Ce que K1 affiche de la journée (FR-091 → FR-095).
class EtatJourneeVue {
  /// Crée l'état.
  const EtatJourneeVue({
    this.coursesLivrees = 0,
    this.gainsUnites = 0,
    this.devise = '',
    this.plafondRetenuUnites = 0,
    this.resteDisponibleUnites = 0,
    this.avancesEnCoursUnites = 0,
    this.tauxAcceptationPourcent,
    this.connue = false,
  });

  /// Courses dont la remise est validée dans le jour civil **de la zone**.
  final int coursesLivrees;

  /// Somme des parts coursier de ces courses (devis FIGÉ du cycle 007).
  final int gainsUnites;

  /// Devise ISO 4217.
  final String devise;

  /// Plafond d'avance qui s'applique.
  final int plafondRetenuUnites;

  /// Ce qu'il reste engageable (FR-095) — jamais négatif.
  final int resteDisponibleUnites;

  /// Argent encore dehors.
  final int avancesEnCoursUnites;

  /// Taux d'acceptation tenu par le dispatch, ou `null` — un `0 %` par défaut
  /// ferait croire à Yao qu'il refuse tout, alors qu'on ne lui a rien proposé.
  final int? tauxAcceptationPourcent;

  /// La journée a été lue. Faux tant que le réseau n'a rien rendu : le bandeau
  /// s'efface plutôt que d'afficher des zéros qui passeraient pour un fait.
  final bool connue;
}

/// Chargement de la journée (CRS-01).
@riverpod
class EtatJournee extends _$EtatJournee {
  @override
  Future<EtatJourneeVue> build() async {
    // Session fermée ⇒ provider invalidé (patron `EtatCourseActive`).
    ref.watch(sessionProvider.select((e) => e.connecte));
    try {
      final reponse =
          await ref.read(clientSessionProvider).getCoursierApi().maJournee();
      final j = reponse.data;
      if (j == null) return const EtatJourneeVue();
      return EtatJourneeVue(
        coursesLivrees: j.coursesLivrees,
        gainsUnites: j.gainsUnites,
        devise: j.devise,
        plafondRetenuUnites: j.plafondRetenuUnites,
        resteDisponibleUnites: j.resteDisponibleUnites,
        avancesEnCoursUnites: j.avancesEnCoursUnites,
        tauxAcceptationPourcent: j.tauxAcceptationPourcent,
        connue: true,
      );
    } on DioException {
      // Réseau muet ou dossier coursier incomplet : K1 doit rester utilisable.
      // Le bandeau s'efface, la mise en ligne fonctionne toujours.
      return const EtatJourneeVue();
    }
  }
}
