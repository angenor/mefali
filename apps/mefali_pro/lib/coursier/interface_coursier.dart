import 'package:flutter/material.dart';

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
    // Bascule de rôle en entête UNIQUEMENT si deux rôles validés — passée à
    // l'écran de course, qui la rend dans son propre Scaffold (aucune
    // imbrication de Scaffold).
    return EcranCourseActive(
      entete: valides.length > 1
          ? BasculeRoles(valides: valides, actif: RolePro.coursier)
          : null,
    );
  }
}
