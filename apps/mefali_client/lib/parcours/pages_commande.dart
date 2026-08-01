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
import '../paiement/ecran_paiement.dart';
import '../paiement/etat_session_paiement.dart';
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

/// Ouvre le suivi d'une commande (C4-4a).
///
/// `remplacer` depuis la confirmation : la pile panier → adresse → confirmation
/// est VIDÉE jusqu'à l'accueil. Un simple `pushReplacement` laissait le retour
/// tomber sur un panier vide — constaté à la validation T067 sur émulateur, et
/// c'est un écran qui ne veut plus rien dire une fois la commande passée.
void ouvrirSuivi(BuildContext context, String commandeId, {bool remplacer = false}) {
  final route = MaterialPageRoute<void>(
    builder: (_) => PageSuivi(commandeId: commandeId),
  );
  if (remplacer) {
    Navigator.of(context).pushAndRemoveUntil(route, (r) => r.isFirst);
  } else {
    Navigator.of(context).push(route);
  }
}

/// Ouvre l'écran de règlement d'une commande (cycle PAY 011, US1).
///
/// `remplacer` depuis la confirmation, pour la même raison que `ouvrirSuivi` :
/// le retour ne doit pas retomber sur un panier déjà vidé.
void ouvrirPaiement(
  BuildContext context,
  String commandeId, {
  bool remplacer = false,
}) {
  final route = MaterialPageRoute<void>(
    builder: (_) => PagePaiement(commandeId: commandeId),
  );
  if (remplacer) {
    Navigator.of(context).pushAndRemoveUntil(route, (r) => r.isFirst);
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
      'scission_hors_ligne' => app.parcoursErreurScissionHorsLigne,
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

  /// Acceptation de scission en vol. État strictement LOCAL (constitution XII) :
  /// il empêche un double appui de lancer deux séries de devis de tronçon.
  bool _scissionEnCours = false;

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

  /// C3-3d — le client ACCEPTE de scinder. Rien n'est créé ici : on chiffre les
  /// N commandes à venir pour qu'il voie leurs N frais de déplacement avant
  /// d'engager quoi que ce soit.
  Future<void> _scinder() async {
    if (_scissionEnCours) return;
    setState(() => _scissionEnCours = true);
    final code = await ref.read(actionsCommandeProvider).accepterScission();
    if (!mounted) return;
    setState(() => _scissionEnCours = false);
    if (code != null) _signaler(context, ref, code);
  }

  @override
  Widget build(BuildContext context) {
    // Un changement de contenu (retrait, préférence) redemande un devis : les
    // frais dépendent des vendeurs visités, pas seulement des articles.
    ref.listen(panierProvider, (_, _) => _recalculer());

    return EcranPanier(
      onContinuer: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PageAdressePaiement()),
      ),
      onScinder: _scissionEnCours ? null : _scinder,
      onAnnulerScission: () =>
          ref.read(panierProvider.notifier).annulerScission(),
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
    // Un refus se dit même si une commande est passée : sur une scission,
    // « 1 créée sur 2 » est bien une réussite ET un échec. Le détail persistant
    // est rendu par l'écran ; le message du refus, lui, passe une fois.
    if (issue.codeErreur != null) _signaler(context, ref, issue.codeErreur);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;

    return EcranAdressePaiement(
      onPositionActuelle: _positionActuelle,
      onConfirmer: _enCours ? null : _confirmer,
      onSuivre: _apresCreation,
      libelleSuivre: app.parcoursSuivreCommande,
    );
  }

  /// Où mène une commande fraîchement créée.
  ///
  /// Une commande née `en_attente_paiement` (au-dessus du plafond cash) va au
  /// **règlement**, pas au suivi : la suivre alors qu'elle ne partira qu'une
  /// fois payée montrerait une attente sans expliquer ce qu'on attend. Le
  /// drapeau vient de la réponse de création, jamais d'une règle recopiée dans
  /// l'app — le plafond est une valeur de zone.
  void _apresCreation(String commandeId) {
    final creees = ref.read(confirmationProvider).commandesCreees;
    final creee = creees.where((c) => c.id == commandeId).firstOrNull;
    if (creee != null && creee.attendPaiement) {
      ouvrirPaiement(context, commandeId, remplacer: true);
    } else {
      ouvrirSuivi(context, commandeId, remplacer: true);
    }
  }
}

/// Règlement d'une commande prépayée (cycle PAY 011, US1).
///
/// L'ouverture de session part à la PREMIÈRE frame et non depuis l'écran de
/// confirmation : si le fournisseur est indisponible (`502`), la commande reste
/// intacte et la cliente voit le message sur un écran qui lui appartient, avec
/// la possibilité de réessayer — plutôt qu'un refus jeté par-dessus l'écran de
/// codes qu'elle était en train de lire.
class PagePaiement extends ConsumerStatefulWidget {
  /// Crée la page de règlement.
  const PagePaiement({required this.commandeId, super.key});

  /// Commande à régler.
  final String commandeId;

  @override
  ConsumerState<PagePaiement> createState() => _PagePaiementState();
}

class _PagePaiementState extends ConsumerState<PagePaiement> {
  @override
  void initState() {
    super.initState();
    // Après la première frame : `ouvrirPaiement` écrit dans un provider, ce
    // qu'un `initState` ne peut pas faire pendant la construction de l'arbre.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ouvrir());
  }

  Future<void> _ouvrir() async {
    final code = await ref
        .read(actionsCommandeProvider)
        .ouvrirPaiement(widget.commandeId);
    if (!mounted || code == null) return;
    _signaler(context, ref, code);
  }

  Future<void> _relire() async {
    final code = await ref
        .read(actionsCommandeProvider)
        .relirePaiement(widget.commandeId);
    if (!mounted || code == null) return;
    _signaler(context, ref, code);
  }

  @override
  Widget build(BuildContext context) => EcranPaiement(
        commandeId: widget.commandeId,
        onRelire: _relire,
        onSuivre: (id) => ouvrirSuivi(context, id, remplacer: true),
      );
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

  /// L'état de paiement a déjà été demandé. Sans ce garde, chaque
  /// rafraîchissement du suivi relancerait une lecture — et le compte à rebours
  /// repartirait de la valeur serveur à chaque frame, donc ne bougerait jamais.
  bool _paiementDemande = false;

  /// Charge l'état de la session quand — et seulement quand — la commande en
  /// attend un. Une commande cash n'a pas de session : la lire rendrait `404`
  /// et n'apprendrait rien.
  void _lirePaiementSiUtile(EtatSuivi suivi) {
    // `annulee` en fait partie : c'est la seule façon d'apprendre qu'une
    // commande a été annulée parce que le délai de paiement a été franchi — le
    // suivi ne porte pas le motif d'annulation. Sur une commande cash annulée,
    // la lecture rend `404` et le bandeau reste simplement muet.
    const concernes = {'en_attente_paiement', 'annulee'};
    if (_paiementDemande || !concernes.contains(suivi.etat)) return;
    _paiementDemande = true;
    ref.read(actionsCommandeProvider).relirePaiement(widget.commandeId);
  }

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
      if (suivi == null) return;
      _presenter(suivi);
      _lirePaiementSiUtile(suivi);
    });

    return EcranSuivi(
      commandeId: widget.commandeId,
      onAppeler: () =>
          ref.read(actionsCommandeProvider).signalerAppel(widget.commandeId),
      onAnnuler: _annuler,
      entete: BandeauPaiementSuivi(commandeId: widget.commandeId),
    );
  }
}

/// Bandeau de paiement posé au-dessus du suivi (cycle PAY 011, FR-016/FR-017).
///
/// Réf. `docs/design/png/C4-suivi-commande.png` — même forme que le bandeau
/// hors-ligne du cadre 4d, dont il emprunte le motif ; aucune planche de
/// paiement n'existe (écart assumé, plan.md Complexity Tracking ligne 3).
///
/// Il n'affiche **rien** tant qu'aucune session n'a été lue : le suivi d'une
/// commande cash ne doit pas laisser un espace vide là où il n'y a rien à dire.
class BandeauPaiementSuivi extends ConsumerWidget {
  /// Crée le bandeau de paiement du suivi.
  const BandeauPaiementSuivi({required this.commandeId, super.key});

  /// Commande suivie.
  final String commandeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = AppLocalizations.of(context)!;
    final session = ref.watch(sessionPaiementProvider(commandeId));
    if (session == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              switch (session.etat) {
                'reglee' => app.paiementEtatReglee,
                'echouee' => app.paiementEtatEchouee,
                // Le motif en CLAIR, et sans jargon : ni « transaction », ni
                // « session », ni « fournisseur ». Awa n'a pas à connaître
                // notre plomberie pour comprendre qu'elle n'a rien payé.
                'expiree' || 'payee_hors_delai' => app.paiementSessionExpiree,
                _ => app.paiementEtatOuverte,
              },
              style: theme.textTheme.titleSmall,
            ),
            // FR-082 — un paiement arrivé APRÈS l'annulation. La commande n'est
            // pas ressuscitée (R8) et le remboursement n'est pas automatique :
            // PAY-04 n'est pas construit. On le DIT plutôt que de laisser Awa
            // découvrir un prélèvement sans explication.
            if (session.etat == 'payee_hors_delai') ...[
              const SizedBox(height: MefaliTokens.space2),
              Text(
                app.paiementRemboursementAVenir,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            // La sortie : repartir du panier. Une annulation sans issue
            // proposée est une impasse, et l'impasse coûte une commande.
            if (session.expiree) ...[
              const SizedBox(height: MefaliTokens.space2),
              FilledButton.tonal(
                onPressed: () => ouvrirPanier(context),
                child: Text(app.paiementRecommander),
              ),
            ],
            // Le temps restant ne s'affiche que tant que la session vit : un
            // « 00:00 » sous un paiement confirmé serait une inquiétude
            // gratuite (FR-017).
            if (session.accepteEncore) ...[
              const SizedBox(height: MefaliTokens.space2),
              Text(
                app.paiementTempsRestant(_mmss(session.restantS)),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            // FR-016 — la reprise reste offerte TANT QUE la session vit. Elle
            // disparaît d'elle-même quand `reprenable` tombe : plus d'accès,
            // plus de temps, ou plus de session payable.
            if (session.reprenable) ...[
              const SizedBox(height: MefaliTokens.space2),
              FilledButton.tonal(
                onPressed: () => ouvrirPaiement(context, commandeId),
                child: Text(app.paiementReprendre),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _mmss(int secondes) {
    final s = secondes < 0 ? 0 : secondes;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}';
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
