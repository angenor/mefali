/// Le parcours de commande, écran par écran (cycle CMD 008, T067).
///
/// Les six écrans du cycle sont livrés et testés ; ce fichier leur donne leurs
/// callbacks et la navigation qui les enchaîne :
///
/// ```text
/// accueil → fiche vendeur → panier (C3-3a) → adresse et paiement (C3-3a′)
///         → confirmation (code + QR) → suivi (C4-4a) ⟂ substitution (C4-4c)
/// ```
///
/// Aucune règle métier ici : les pages appellent `ActionsCommande`, affichent
/// ce que les porteurs d'état contiennent, et traduisent les refus par
/// `messageErreurCommande`. Leur état de chargement est strictement LOCAL
/// (constitution XII) — ce n'est l'affaire d'aucun provider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../commande/ecran_suivi.dart';
import '../commande/etat_suivi.dart';
import '../commande/feuille_substitution.dart';
import '../l10n/app_localizations.dart';
import '../panier/ecran_adresse_paiement.dart';
import '../panier/ecran_panier.dart';
import '../panier/etat_confirmation.dart';
import '../panier/etat_panier.dart';
import 'actions_commande.dart';

/// Ouvre le panier (C3-3a).
void ouvrirPanier(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const PagePanier()),
  );
}

/// Ouvre le suivi d'une commande (C4-4a). `replace` depuis la confirmation :
/// revenir en arrière sur un écran de panier vidé n'aurait aucun sens.
void ouvrirSuivi(BuildContext context, String commandeId, {bool remplacer = false}) {
  final route = MaterialPageRoute<void>(
    builder: (_) => PageSuivi(commandeId: commandeId),
  );
  if (remplacer) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

/// Rend le message d'un refus.
///
/// Les codes SERVEUR passent tous par `messageErreurCommande` (constitution
/// VII). Les deux codes traités ici sont LOCAUX — l'app les a produits
/// elle-même, faute de pin GPS ou de configuration de zone — et n'ont donc
/// aucune clé côté serveur.
String messageErreurParcours(
  MefaliCoreLocalizations core,
  AppLocalizations app,
  String? code,
) =>
    switch (code) {
      'lieu_indisponible' => app.parcoursErreurLieu,
      'zone_indisponible' => app.parcoursErreurZone,
      _ => messageErreurCommande(core, code),
    };

/// Libellé d'un état de commande dans la LISTE d'accueil.
///
/// Variante sans compteur de `_libelleEtat` de l'écran de suivi : la liste ne
/// connaît pas la progression (`GET /moi/commandes` ne la sert pas), et
/// afficher « 0 sur 0 » serait un chiffre faux plutôt qu'une information
/// absente.
String libelleEtatSuivi(
  MefaliCoreLocalizations core,
  AppLocalizations app,
  String etatCle,
) =>
    switch (etatCle) {
      'suivi.etat.commande_recue' => core.suiviEtatRecue,
      'suivi.etat.recherche_coursier' => core.suiviEtatRechercheCoursier,
      'suivi.etat.collecte_en_cours' => app.accueilEtatCollecte,
      'suivi.etat.en_route_vers_vous' => core.suiviEtatEnRoute,
      'suivi.etat.livree' => core.suiviEtatLivree,
      'suivi.etat.annulee' => core.suiviEtatAnnulee,
      'suivi.etat.echouee' => core.suiviEtatEchouee,
      // Clé inconnue = serveur plus récent que l'app : on rend le premier pas
      // plutôt qu'une chaîne technique.
      _ => core.suiviEtatRecue,
    };

/// Le panier (C3-3a/3c/3d), avec son devis serveur recalculé à l'ouverture et
/// à chaque changement de contenu.
class PagePanier extends ConsumerStatefulWidget {
  /// Crée la page du panier.
  const PagePanier({super.key});

  @override
  ConsumerState<PagePanier> createState() => _PagePanierState();
}

class _PagePanierState extends ConsumerState<PagePanier> {
  /// Empreinte du contenu déjà chiffré. Sans elle, `poserDevis` modifierait le
  /// panier, qui relancerait un devis, qui modifierait le panier… : la boucle
  /// est évitée en comparant ce que le devis a COÛTÉ, pas en comptant les tours.
  String? _chiffre;

  @override
  void initState() {
    super.initState();
    // Après la première frame : `rafraichirDevis` écrit dans des providers, ce
    // qu'un `initState` ne peut pas faire pendant la construction de l'arbre.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalculer());
  }

  Future<void> _recalculer() async {
    final empreinte = _empreinte(ref.read(panierProvider));
    if (empreinte == _chiffre) return;
    _chiffre = empreinte;
    final code = await ref.read(actionsCommandeProvider).rafraichirDevis();
    if (!mounted || code == null) return;
    // Le devis a été refusé : le contenu n'est pas chiffré, il faudra réessayer
    // si la cliente le modifie.
    _chiffre = null;
    _signaler(context, ref, code);
  }

  String _empreinte(EtatPanier panier) => [
        for (final l in panier.lignes)
          '${l.prestataireId}:${l.articleId}:${l.quantite}:${l.preference}',
      ].join('|');

  @override
  Widget build(BuildContext context) {
    // Un changement de contenu (retrait, préférence) redemande un devis : les
    // frais dépendent des vendeurs visités, pas seulement des articles.
    ref.listen(panierProvider, (_, _) => _recalculer());

    return EcranPanier(
      onContinuer: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PageAdressePaiement()),
      ),
    );
  }
}

/// Adresse, paiement, puis confirmation (C3-3a′/3b).
class PageAdressePaiement extends ConsumerStatefulWidget {
  /// Crée la page d'adresse et de paiement.
  const PageAdressePaiement({super.key});

  @override
  ConsumerState<PageAdressePaiement> createState() =>
      _PageAdressePaiementState();
}

class _PageAdressePaiementState extends ConsumerState<PageAdressePaiement> {
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    // Le pin est demandé d'emblée : c'est le geste que la maquette met en
    // avant, et le devis en a besoin de toute façon.
    WidgetsBinding.instance.addPostFrameCallback((_) => _positionActuelle());
  }

  Future<void> _positionActuelle() async {
    final obtenue =
        await ref.read(actionsCommandeProvider).utiliserPositionActuelle();
    if (!mounted || obtenue) return;
    _signaler(context, ref, 'lieu_indisponible');
  }

  Future<void> _confirmer() async {
    if (_enCours) return;
    final app = AppLocalizations.of(context)!;
    setState(() => _enCours = true);
    final issue = await ref.read(actionsCommandeProvider).confirmer(
          libelleAdresse: app.parcoursAdresseLivraisonLibelle,
        );
    if (!mounted) return;
    setState(() => _enCours = false);
    if (issue.commandeId == null) _signaler(context, ref, issue.codeErreur);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final creee = ref.watch(confirmationProvider).commandeCreee;

    return EcranAdressePaiement(
      onPositionActuelle: _positionActuelle,
      onConfirmer: _enCours ? null : _confirmer,
      onSuivre: creee == null
          ? null
          : () => ouvrirSuivi(context, creee.id, remplacer: true),
      libelleSuivre: app.parcoursSuivreCommande,
    );
  }
}

/// Suivi d'une commande (C4-4a/4b/4d) et feuille de substitution (C4-4c).
class PageSuivi extends ConsumerStatefulWidget {
  /// Crée la page de suivi.
  const PageSuivi({required this.commandeId, super.key});

  /// Commande suivie.
  final String commandeId;

  @override
  ConsumerState<PageSuivi> createState() => _PageSuiviState();
}

class _PageSuiviState extends ConsumerState<PageSuivi> {
  /// Proposition déjà présentée. Sans ce garde, chaque rafraîchissement du
  /// suivi rouvrirait la feuille par-dessus elle-même.
  String? _substitutionPresentee;

  Future<void> _annuler() async {
    final app = AppLocalizations.of(context)!;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(app.parcoursAnnulerTitre),
        content: Text(app.parcoursAnnulerAide),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(app.parcoursGarderCommande),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(app.parcoursAnnulerConfirmer),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    final code = await ref.read(actionsCommandeProvider).annuler(widget.commandeId);
    if (!mounted) return;
    if (code != null) {
      _signaler(context, ref, code);
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(app.parcoursCommandeAnnulee)));
    Navigator.of(context).pop();
  }

  Future<void> _decider(SubstitutionVue substitution, bool accepte) async {
    final code = await ref.read(actionsCommandeProvider).deciderSubstitution(
          commandeId: widget.commandeId,
          substitutionId: substitution.id,
          accepte: accepte,
        );
    if (!mounted || code == null) return;
    _signaler(context, ref, code);
  }

  void _presenter(EtatSuivi suivi) {
    final substitution = suivi.substitution;
    if (substitution == null || substitution.id == _substitutionPresentee) {
      return;
    }
    _substitutionPresentee = substitution.id;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Non renvoyable d'un geste : la fenêtre de décision court, et une
      // feuille fermée par mégarde coûterait l'article (CMD-06).
      isDismissible: false,
      enableDrag: false,
      builder: (feuille) => FeuilleSubstitution(
        substitution: substitution,
        devise: suivi.devise,
        onAccepter: () {
          Navigator.of(feuille).pop();
          _decider(substitution, true);
        },
        onRefuser: () {
          Navigator.of(feuille).pop();
          _decider(substitution, false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // C4-4c — la proposition arrive PAR-DESSUS le suivi, sans le remplacer :
    // la cliente doit garder sous les yeux la commande dont on parle.
    ref.listen(suiviProvider(widget.commandeId), (_, next) {
      final suivi = next.value;
      if (suivi != null) _presenter(suivi);
    });

    return EcranSuivi(
      commandeId: widget.commandeId,
      onAppeler: () =>
          ref.read(actionsCommandeProvider).signalerAppel(widget.commandeId),
      onAnnuler: _annuler,
    );
  }
}

/// Affiche le message d'un refus, une fois, en bas de l'écran courant.
void _signaler(BuildContext context, WidgetRef ref, String? code) {
  final core = MefaliCoreLocalizations.of(context)!;
  final app = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(messageErreurParcours(core, app, code))),
  );
}
