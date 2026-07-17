import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'tokens.dart';

/// Les états obligatoires de TOUT écran, en composants partagés.
///
/// `docs/design/tokens.md` règle d'or 5 : « Chaque écran gère : normal ·
/// chargement (squelettes) · vide · erreur réseau · hors-ligne ». Ces briques
/// existent pour que la règle soit tenue par construction plutôt que réinventée
/// — et mal — à chaque écran.

/// Bloc gris d'attente — la forme du contenu à venir.
///
/// « Chargement : toujours des squelettes, jamais de spinner plein écran ». Un
/// squelette annonce ce qui arrive et ne fait pas clignoter l'écran sur les
/// réseaux lents qui sont notre cible.
class Squelette extends StatelessWidget {
  /// Crée un bloc d'attente.
  const Squelette({super.key, required this.hauteur, this.largeur});

  /// Hauteur du bloc.
  final double hauteur;

  /// Largeur du bloc — pleine largeur si absente.
  final double? largeur;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: hauteur,
      width: largeur,
      decoration: BoxDecoration(
        color: MefaliTokens.border,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
      ),
    );
  }
}

/// Attente d'un écran qui affichera une liste de cartes.
class SqueletteListe extends StatelessWidget {
  /// Crée une liste d'attente.
  const SqueletteListe({super.key, this.lignes = 3, this.hauteurLigne = 96});

  /// Nombre de blocs.
  final int lignes;

  /// Hauteur de chaque bloc.
  final double hauteurLigne;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(MefaliTokens.screenMargin),
      itemCount: lignes,
      separatorBuilder: (_, _) => const SizedBox(height: MefaliTokens.space3),
      itemBuilder: (_, _) => Squelette(hauteur: hauteurLigne),
    );
  }
}

/// État vide ou en erreur : un picto, un message, et une SORTIE.
///
/// L'action n'est pas décorative : un état d'erreur réseau sans « réessayer »
/// est un cul-de-sac dont l'utilisateur ne sort qu'en tuant l'app.
class MessageEtat extends StatelessWidget {
  /// Crée un état vide ou en erreur.
  const MessageEtat({
    super.key,
    required this.texte,
    required this.picto,
    this.action,
    this.libelleAction,
  });

  /// Message affiché (clé i18n résolue).
  final String texte;

  /// Pictogramme — un picto à côté de chaque libellé important (règle d'or 2).
  final IconData picto;

  /// Sortie proposée. Sans elle, l'écran est un cul-de-sac.
  final VoidCallback? action;

  /// Libellé de l'action (clé i18n résolue).
  final String? libelleAction;

  @override
  Widget build(BuildContext context) {
    final onPresse = action;
    final libelle = libelleAction;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(picto, size: 48, color: MefaliTokens.textMuted),
            const SizedBox(height: MefaliTokens.space3),
            Text(
              texte,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onPresse != null && libelle != null) ...[
              const SizedBox(height: MefaliTokens.space3),
              SizedBox(
                height: MefaliTokens.tapMin,
                child: OutlinedButton.icon(
                  onPressed: onPresse,
                  icon: const Icon(Symbols.refresh),
                  label: Text(libelle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
