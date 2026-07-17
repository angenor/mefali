import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Ossature commune aux écrans d'authentification, transcrite depuis
/// `docs/design/tokens.md` (aucune capture dédiée n'existe — exploration §10).
///
/// Fixe en un seul endroit les règles d'or applicables ici : marge d'écran de
/// 16 px, un pictogramme à côté de chaque libellé important, et surtout
/// l'ACTION PRINCIPALE EN BAS — le produit s'utilise à une main, souvent sur
/// une moto (règle 3). Un écran d'auth qui poserait son bouton en haut
/// romprait la seule promesse qui rend l'app tenable sur le terrain.
class CadreAuth extends StatelessWidget {
  /// Crée le cadre.
  const CadreAuth({
    super.key,
    required this.titre,
    required this.corps,
    required this.action,
    this.aide,
    this.picto,
    this.erreur,
    this.enTete,
  });

  /// Titre d'écran (22/600).
  final String titre;

  /// Explication sous le titre.
  final String? aide;

  /// Pictogramme du titre (Material Symbols Rounded, un seul style).
  final IconData? picto;

  /// Contenu propre à l'étape.
  final List<Widget> corps;

  /// Action principale — rendue EN BAS, hors du défilement.
  final Widget action;

  /// Message d'erreur (déjà traduit) — jamais une chaîne en dur.
  final String? erreur;

  /// Zone d'en-tête facultative (bouton retour…).
  final Widget? enTete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?enTete,
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: MefaliTokens.space4),
                      if (picto != null)
                        Icon(
                          picto,
                          size: 48,
                          fill: 1,
                          color: MefaliTokens.primary,
                          semanticLabel: '',
                        ),
                      if (picto != null)
                        const SizedBox(height: MefaliTokens.space3),
                      Text(titre, style: textTheme.titleLarge),
                      if (aide != null) ...[
                        const SizedBox(height: MefaliTokens.space2),
                        Text(
                          aide!,
                          style: textTheme.bodyLarge?.copyWith(
                            color: MefaliTokens.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: MefaliTokens.space4),
                      ...corps,
                      if (erreur != null) ...[
                        const SizedBox(height: MefaliTokens.space3),
                        _Bandeau(message: erreur!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MefaliTokens.space3),
              action,
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau d'erreur — teinte claire, texte foncé (contraste AAA au soleil).
class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.dangerTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: MefaliTokens.bodySize,
          height: MefaliTokens.bodyHeight,
          color: MefaliTokens.text,
        ),
      ),
    );
  }
}

/// Bouton d'action principale : pleine largeur, 56 px, pictogramme à gauche
/// (`--button-height`, `.mf-btn-primary`).
class BoutonPrincipal extends StatelessWidget {
  /// Crée le bouton principal.
  const BoutonPrincipal({
    super.key,
    required this.libelle,
    required this.onPresse,
    this.picto,
    this.enCours = false,
    this.actif = true,
  });

  /// Libellé (clé i18n déjà résolue).
  final String libelle;

  /// Action ; le bouton est inerte si `null`.
  final VoidCallback? onPresse;

  /// Pictogramme à gauche du libellé (règle d'or 2).
  final IconData? picto;

  /// Requête en cours — affiche une progression et verrouille.
  final bool enCours;

  /// Condition métier d'activation (ex. consentement coché).
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final utilisable = actif && !enCours && onPresse != null;
    return SizedBox(
      height: MefaliTokens.buttonHeight,
      child: FilledButton.icon(
        onPressed: utilisable ? onPresse : null,
        icon: enCours
            ? const SizedBox(
                width: 20,
                height: 20,
                // `.adaptive` : une seule identité Android/iOS (constitution XI).
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              )
            : Icon(picto ?? Icons.arrow_forward),
        label: Text(libelle),
      ),
    );
  }
}
