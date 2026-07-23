import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import '../roles/etat_roles.dart';
import '../roles/interface_pro.dart';
import 'course/ecran_course_active.dart';

/// Espace coursier de Mefali Pro (tranche « scanner & collecter » de K3).
///
/// Remplace le placeholder du cycle CRS pour la partie QRC : l'écran de course
/// active. La bascule de rôle (FR-046) reste en tête si le compte porte deux
/// rôles validés — porte et routeur inchangés.
class InterfaceCoursier extends StatelessWidget {
  /// Crée l'espace coursier.
  const InterfaceCoursier({super.key, required this.etat});

  /// Rôles du compte connecté.
  final EtatRolesData etat;

  @override
  Widget build(BuildContext context) {
    final valides = etat.rolesValides;
    if (valides.length <= 1) {
      return const EcranCourseActive();
    }
    // Deux rôles validés : bascule en tête, écran de course en dessous.
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MefaliTokens.screenMargin,
                MefaliTokens.space3,
                MefaliTokens.screenMargin,
                0,
              ),
              child: BasculeRoles(valides: valides, actif: RolePro.coursier),
            ),
            const Expanded(child: EcranCourseActive()),
          ],
        ),
      ),
    );
  }
}
