import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../theme/tokens.dart';
import 'cadre_auth.dart';

/// Saisie du numéro de mobile — première étape du flux UNIQUE
/// inscription/connexion (CPT-01).
///
/// Rien ici ne laisse deviner si le numéro possède un compte : l'écran est le
/// même pour Awa qui s'inscrit et pour Awa qui se reconnecte (FR-004).
///
/// Cible design : aucune capture dédiée n'existe pour l'auth (exploration §10)
/// — `docs/design/tokens.md` fait foi. Action principale EN BAS (usage à une
/// main), bouton 56 px pleine largeur, texte ≥ 16 px, pas de mode sombre.
class EcranTelephone extends StatefulWidget {
  /// Crée l'écran de saisie du numéro.
  const EcranTelephone({
    super.key,
    required this.onValider,
    this.erreur,
    this.enCours = false,
  });

  /// Appelé avec la saisie BRUTE : la normalisation E.164 est faite par le
  /// serveur, avec l'indicatif de la zone (FR-024) — jamais par l'app.
  final ValueChanged<String> onValider;

  /// Message d'erreur à afficher (déjà traduit).
  final String? erreur;

  /// Requête en cours — l'action est verrouillée.
  final bool enCours;

  @override
  State<EcranTelephone> createState() => _EcranTelephoneState();
}

class _EcranTelephoneState extends State<EcranTelephone> {
  final TextEditingController _controleur = TextEditingController();
  String? _erreurLocale;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _valider(MefaliCoreLocalizations l10n) {
    final saisie = _controleur.text.trim();
    if (saisie.isEmpty) {
      setState(() => _erreurLocale = l10n.authTelephoneVide);
      return;
    }
    setState(() => _erreurLocale = null);
    widget.onValider(saisie);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    return CadreAuth(
      titre: l10n.authTelephoneTitre,
      aide: l10n.authTelephoneAide,
      picto: Symbols.smartphone,
      erreur: widget.erreur ?? _erreurLocale,
      action: BoutonPrincipal(
        libelle: l10n.authTelephoneAction,
        picto: Symbols.sms,
        enCours: widget.enCours,
        onPresse: () => _valider(l10n),
      ),
      corps: [
        TextField(
          controller: _controleur,
          autofocus: true,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          // La saisie locale (« 0701020304ceau ») comme l'internationale
          // (« +225… ») sont acceptées : c'est le serveur qui normalise.
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            LengthLimitingTextInputFormatter(20),
          ],
          style: const TextStyle(
            fontSize: MefaliTokens.bodySize,
            height: MefaliTokens.bodyHeight,
          ),
          decoration: InputDecoration(
            labelText: l10n.authTelephoneChamp,
            hintText: l10n.authTelephoneExemple,
            prefixIcon: const Icon(Symbols.call),
          ),
          onSubmitted: (_) => _valider(l10n),
        ),
      ],
    );
  }
}
