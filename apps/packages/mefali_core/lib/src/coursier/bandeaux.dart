/// Bandeaux d'état partagés de la surface coursier (cycle QRC 006).
///
/// Widgets Material 3 thémés depuis `docs/design/tokens.md` — jamais de
/// transposition DOM/CSS (constitution XI). Réf. `docs/design/png/K3-course-active.png`.
/// Les textes sont fournis par l'appelant (clés i18n résolues côté écran).
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/tokens.dart';

/// Bandeau « hors-ligne » — jeton `--warning`. Affiché tant que le réseau est
/// coupé : le scan et les coches restent actifs (empreintes pré-provisionnées).
class BandeauHorsLigne extends StatelessWidget {
  /// Message i18n résolu (ex. « Hors-ligne — vos scans seront synchronisés »).
  const BandeauHorsLigne({required this.message, super.key});

  /// Texte affiché.
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Bandeau(
      icone: Symbols.cloud_off_rounded,
      fond: MefaliTokens.warningTint,
      accent: MefaliTokens.warning,
      message: message,
    );
  }
}

/// Bandeau « succès » — jeton `--success`. Confirme une collecte ou la bascule
/// EN_LIVRAISON (« tout est collecté → en route »).
class BandeauSucces extends StatelessWidget {
  /// Message i18n résolu.
  const BandeauSucces({required this.message, super.key});

  /// Texte affiché.
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Bandeau(
      icone: Symbols.check_circle_rounded,
      fond: MefaliTokens.successTint,
      accent: MefaliTokens.success,
      message: message,
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({
    required this.icone,
    required this.fond,
    required this.accent,
    required this.message,
  });

  final IconData icone;
  final Color fond;
  final Color accent;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: MefaliTokens.space3,
        vertical: MefaliTokens.space2,
      ),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
      ),
      child: Row(
        children: [
          Icon(icone, color: accent, size: 20),
          const SizedBox(width: MefaliTokens.space2),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
