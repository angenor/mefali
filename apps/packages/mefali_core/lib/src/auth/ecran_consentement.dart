import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../theme/tokens.dart';
import 'cadre_auth.dart';

/// Consentement ARTCI — dernière étape avant la création du compte (FR-006).
///
/// Deux invariants non négociables, tous deux testés :
/// 1. la case n'est JAMAIS pré-cochée — un consentement pré-coché n'est pas un
///    consentement ; 2. l'action est INERTE tant qu'elle n'est pas cochée, et
///    le serveur refuse de toute façon une inscription sans version acceptée
///    (le client n'est pas la garde, il est la courtoisie).
class EcranConsentement extends StatefulWidget {
  /// Crée l'écran de consentement.
  const EcranConsentement({
    super.key,
    required this.onAccepter,
    this.erreur,
    this.enCours = false,
  });

  /// Appelé quand l'utilisateur a coché ET validé.
  final VoidCallback onAccepter;

  /// Message d'erreur (déjà traduit).
  final String? erreur;

  /// Requête en cours.
  final bool enCours;

  @override
  State<EcranConsentement> createState() => _EcranConsentementState();
}

class _EcranConsentementState extends State<EcranConsentement> {
  /// JAMAIS `true` à l'initialisation (FR-006).
  bool _accepte = false;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return CadreAuth(
      titre: l10n.authConsentementTitre,
      picto: Symbols.shield_person,
      erreur: widget.erreur,
      action: BoutonPrincipal(
        libelle: l10n.authConsentementAction,
        picto: Symbols.person_add,
        enCours: widget.enCours,
        actif: _accepte,
        onPresse: widget.onAccepter,
      ),
      corps: [
        Container(
          padding: const EdgeInsets.all(MefaliTokens.space3),
          decoration: BoxDecoration(
            color: MefaliTokens.surface,
            borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
            border: Border.all(color: MefaliTokens.border),
          ),
          child: Text(l10n.authConsentementTexte, style: textTheme.bodyLarge),
        ),
        const SizedBox(height: MefaliTokens.space3),
        // Toute la ligne est cliquable : la case seule ferait une cible de
        // 24 dp, sous le plancher de 48 dp des tokens.
        InkWell(
          onTap: () => setState(() => _accepte = !_accepte),
          borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: MefaliTokens.space1),
            child: Row(
              children: [
                Checkbox.adaptive(
                  value: _accepte,
                  onChanged: (v) => setState(() => _accepte = v ?? false),
                ),
                Expanded(
                  child: Text(
                    l10n.authConsentementCase,
                    style: textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
