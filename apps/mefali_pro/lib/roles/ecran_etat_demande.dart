import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../l10n/app_localizations.dart';
import 'composants.dart';
import 'etat_roles.dart';
import 'formulaire_dossier.dart';
import 'libelles_roles.dart';
import 'pied_pro.dart';

/// Ce que voit un compte SANS rôle professionnel validé (FR-013).
///
/// Mefali Pro ne lui ouvre aucune fonction : il lui doit en revanche une
/// réponse claire — où en est sa demande, et pourquoi. Un écran qui refuse sans
/// dire pourquoi envoie l'utilisateur au support ; celui-ci porte le statut et
/// le motif de la décision (FR-014, journal admin).
///
/// Le cycle CPT s'arrête à l'état : la constitution du dossier (T019) viendra
/// s'ajouter ici.
class EcranEtatDemande extends StatelessWidget {
  /// Crée l'écran d'état de la demande.
  const EcranEtatDemande({super.key, required this.etat, this.transportsActifs = const []});

  /// Rôles du compte connecté.
  final EtatRoles etat;

  /// Slugs des types de transport actifs dans la zone, pour le formulaire.
  final List<String> transportsActifs;

  /// Le dossier coursier peut-il être (re)déposé ?
  ///
  /// FR-015 : jamais depuis `en_attente` (c'est déjà fait) ni `valide`. Après
  /// un refus, si — c'est tout l'intérêt du motif affiché juste au-dessus.
  bool get _peutSoumettre => switch (etat.statut(RolePro.coursier)) {
        StatutRolePro.aucun || StatutRolePro.refuse => true,
        StatutRolePro.enAttente || StatutRolePro.valide || StatutRolePro.suspendu => false,
      };

  Future<void> _ouvrirFormulaire(BuildContext context) async {
    final soumis = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FormulaireDossierCoursier(
          session: etat.session,
          transportsActifs: transportsActifs,
        ),
      ),
    );
    // Le dossier est parti : l'état affiché n'est plus le bon.
    if (soumis ?? false) await etat.charger();
  }

  /// Situation à mettre en titre.
  ///
  /// Un compte peut cumuler deux rôles pro non validés (edge case « cumul
  /// coursier + vendeur » de la spec) : on titre alors sur le plus parlant —
  /// une demande en cours prime sur une suspension, qui prime sur un refus.
  /// Le détail rôle par rôle est dans les cartes en dessous.
  StatutRolePro _situation() {
    for (final statut in [
      StatutRolePro.enAttente,
      StatutRolePro.suspendu,
      StatutRolePro.refuse,
    ]) {
      if (etat.attributions.any((a) => a.statut == statut)) return statut;
    }
    return StatutRolePro.aucun;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final situation = _situation();

    final (titre, aide, picto) = switch (situation) {
      StatutRolePro.enAttente => (
          l10n.proEtatEnAttenteTitre,
          l10n.proEtatEnAttenteAide,
          Symbols.hourglass_top,
        ),
      StatutRolePro.refuse => (
          l10n.proEtatRefuseTitre,
          l10n.proEtatRefuseAide,
          Symbols.cancel,
        ),
      StatutRolePro.suspendu => (
          l10n.proEtatSuspenduTitre,
          l10n.proEtatSuspenduAide,
          Symbols.pause_circle,
        ),
      // `valide` est impossible ici — cet écran n'existe que sans rôle validé.
      StatutRolePro.aucun || StatutRolePro.valide => (
          l10n.proEtatAucunTitre,
          l10n.proEtatAucunAide,
          Symbols.badge,
        ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(picto, size: 48, color: MefaliTokens.textMuted),
                      const SizedBox(height: MefaliTokens.space3),
                      Text(
                        titre,
                        style: textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: MefaliTokens.space2),
                      Text(
                        aide,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: MefaliTokens.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: MefaliTokens.space4),
                      for (final attribution in etat.attributions) ...[
                        _CarteRole(attribution: attribution),
                        const SizedBox(height: MefaliTokens.space3),
                      ],
                      // §5.1 — le rôle vendeur ne se demande pas ici. Le dire
                      // évite d'attendre un bouton qui n'existera jamais.
                      if (etat.statut(RolePro.vendeur) == StatutRolePro.aucun)
                        Text(
                          l10n.proEtatVendeurAgrement,
                          style: textTheme.bodyLarge
                              ?.copyWith(color: MefaliTokens.textMuted),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MefaliTokens.space3),
              // Action principale en bas d'écran (règle d'or 3). Constituer le
              // dossier prime sur actualiser quand c'est possible : c'est la
              // seule action qui fasse AVANCER la situation.
              if (_peutSoumettre)
                BoutonPrincipal(
                  libelle: situation == StatutRolePro.refuse
                      ? l10n.proDossierRenvoyer
                      : l10n.proDossierConstituer,
                  picto: Symbols.assignment_ind,
                  onPresse: () => _ouvrirFormulaire(context),
                )
              else
                BoutonPrincipal(
                  libelle: l10n.proActualiser,
                  picto: Symbols.refresh,
                  onPresse: etat.charger,
                ),
              const SizedBox(height: MefaliTokens.space2),
              PiedPro(session: etat.session),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une carte par rôle attribué : le rôle, son statut, le motif s'il y en a un.
class _CarteRole extends StatelessWidget {
  const _CarteRole({required this.attribution});

  final AttributionPro attribution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final motif = attribution.motif;

    return CarteMefali(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                pictoRole(attribution.role),
                color: MefaliTokens.textMuted,
              ),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(
                child: Text(
                  l10n.role(attribution.role),
                  style: textTheme.titleMedium,
                ),
              ),
              PuceStatut(
                texte: l10n.statutRole(attribution.statut),
                ton: tonStatut(attribution.statut),
              ),
            ],
          ),
          if (motif != null && motif.isNotEmpty) ...[
            const SizedBox(height: MefaliTokens.space3),
            Text(
              l10n.proMotif,
              style: textTheme.labelSmall?.copyWith(
                color: MefaliTokens.textMuted,
              ),
            ),
            const SizedBox(height: MefaliTokens.space1),
            // Motif = texte SAISI par l'admin (FR-017), pas une clé i18n :
            // il s'affiche tel quel.
            Text(motif, style: textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }
}
