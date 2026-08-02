/// Écran **régler ma commande** (cycle PAY 011, US1 — PAY-01/PAY-02).
///
/// ⚠ **Écart de design assumé.** `docs/design/png/` ne contient aucune planche
/// de paiement : C3 (panier) et C4 (suivi) s'arrêtent avant l'encaissement
/// (plan.md, Complexity Tracking ligne 3). Cet écran EMPRUNTE donc ses motifs
/// aux planches voisines :
///
/// - le **bandeau d'état** et son compte à rebours : `C4-suivi-commande.png`,
///   cadre 4b (« recherche de coursier ») — même forme, même hiérarchie ;
/// - le **bloc de montant** en display : `C3-panier-multi-vendeurs.png`, ligne
///   de total.
///
/// Toutes les valeurs viennent de `docs/design/tokens.md` via `MefaliTokens` et
/// le thème M3 de `mefali_core` ; aucune structure DOM/CSS de
/// `docs/design/html/` n'est transposée (constitution XI). L'écart est **assumé
/// et documenté**, pas inventé : la planche manquante reste à produire.
///
/// # Ce que cet écran ne fait jamais
///
/// **Il ne crédite rien.** Le retour depuis le navigateur ne confirme aucun
/// paiement (FR-025) : il déclenche une **relecture** de l'état auprès du
/// serveur, et l'écran affiche ce que le serveur dit. Si Awa a payé et que la
/// notification n'est pas encore arrivée, elle lit « en attente » — ce qui est
/// la vérité, et non « échec ».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'etat_session_paiement.dart';

/// Ouvre une URL dans le **navigateur système** — injecté par la PORTÉE.
///
/// Un provider plutôt qu'un appel direct à `launchUrl` : c'est ce qui permet au
/// test widget d'exercer le chemin « revenu sans confirmation » sans canal de
/// plateforme. Rend `false` quand aucune application ne sait ouvrir le lien.
///
/// ⚠ `url_launcher` est un **plugin natif** : Shorebird ne le patche pas
/// (research R17). Toute correction qui le touche passe par le store.
final ouvrirUrlProvider = Provider<Future<bool> Function(String)>(
  (ref) => _ouvrirDansNavigateurSysteme,
);

/// Implémentation de production de [ouvrirUrlProvider].
///
/// `LaunchMode.externalApplication` et non une vue web intégrée : les
/// applications de mobile money s'ouvrent par lien profond depuis le navigateur
/// système, et une WebView les manquerait. C'est aussi ce qui garantit que la
/// page de paiement s'affiche dans un contexte que l'utilisatrice reconnaît.
Future<bool> _ouvrirDansNavigateurSysteme(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Écran de règlement d'une commande.
class EcranPaiement extends ConsumerStatefulWidget {
  /// Crée l'écran de paiement.
  const EcranPaiement({
    required this.commandeId,
    this.onRelire,
    this.onSuivre,
    super.key,
  });

  /// Commande à régler.
  final String commandeId;

  /// Relit l'état auprès du serveur (`GET /commandes/{id}/paiement`).
  final Future<void> Function()? onRelire;

  /// Ouvre le suivi une fois le paiement confirmé.
  final void Function(String commandeId)? onSuivre;

  @override
  ConsumerState<EcranPaiement> createState() => _EcranPaiementState();
}

class _EcranPaiementState extends ConsumerState<EcranPaiement> {
  /// Ouverture du navigateur en vol. État strictement LOCAL (constitution
  /// XII) : il empêche un double appui d'ouvrir deux onglets.
  bool _ouverture = false;

  /// L'accès a été ouvert au moins une fois : c'est ce qui autorise le message
  /// « revenu sans confirmation » au retour, et qui l'interdit avant.
  bool _revenu = false;

  /// Poignée capturée à l'initialisation.
  ///
  /// `ref` est déjà libéré quand `State.dispose` s'exécute (règle
  /// `avoid_ref_inside_state_dispose`) : la poignée est donc prise ICI, tant
  /// qu'elle est valide. Le porteur, lui, est `keepAlive` — il survit à l'écran,
  /// et c'est bien pour ça qu'il faut lui dire de s'éteindre.
  late final SessionPaiement _porteur =
      ref.read(sessionPaiementProvider(widget.commandeId).notifier);

  @override
  void initState() {
    super.initState();
    _porteur;
  }

  @override
  void dispose() {
    _porteur.liberer();
    super.dispose();
  }

  Future<void> _payer(String acces) async {
    if (_ouverture) return;
    final app = AppLocalizations.of(context)!;
    setState(() => _ouverture = true);
    final ouvert = await ref.read(ouvrirUrlProvider)(acces);
    if (!mounted) return;
    setState(() {
      _ouverture = false;
      _revenu = ouvert;
    });
    if (!ouvert) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(app.paiementNavigateurIndisponible)),
      );
      return;
    }
    // Le RETOUR ne crédite rien (FR-025) : on relit l'état, et c'est le
    // serveur qui dit s'il s'est passé quelque chose.
    await widget.onRelire?.call();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final session = ref.watch(sessionPaiementProvider(widget.commandeId));

    return Scaffold(
      appBar: AppBar(title: Text(app.paiementTitre)),
      body: session == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _Corps(
              session: session,
              revenu: _revenu,
              ouvertureEnCours: _ouverture,
              onPayer: session.accesPaiement == null
                  ? null
                  : () => _payer(session.accesPaiement!),
              onSuivre: session.reglee && widget.onSuivre != null
                  ? () => widget.onSuivre!(widget.commandeId)
                  : null,
            ),
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({
    required this.session,
    required this.revenu,
    required this.ouvertureEnCours,
    this.onPayer,
    this.onSuivre,
  });

  final EtatSessionPaiement session;
  final bool revenu;
  final bool ouvertureEnCours;
  final VoidCallback? onPayer;
  final VoidCallback? onSuivre;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(MefaliTokens.screenMargin),
      children: [
        // Bloc de montant — motif de la ligne de total de C3.
        Text(app.paiementMontantLibelle, style: theme.textTheme.labelLarge),
        const SizedBox(height: MefaliTokens.space2),
        Text(
          formaterMontant(session.montantUnites, session.devise),
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: MefaliTokens.space4),

        // Bandeau d'état — motif du cadre C4-4b.
        _BandeauEtat(session: session),
        const SizedBox(height: MefaliTokens.space3),

        // Le compte à rebours n'apparaît QUE tant que la session vit : afficher
        // « 00:00 » sur une session réglée serait une inquiétude gratuite.
        if (session.accepteEncore) ...[
          Row(
            children: [
              const Icon(Symbols.timer_rounded),
              const SizedBox(width: MefaliTokens.space2),
              Text(
                app.paiementTempsRestant(_duree(session.restantS)),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space4),
        ],

        if (onPayer != null)
          FilledButton.icon(
            onPressed: ouvertureEnCours ? null : onPayer,
            icon: const Icon(Symbols.open_in_new_rounded),
            label: Text(
              ouvertureEnCours
                  ? app.paiementOuvertureEnCours
                  // « Reprendre » dès qu'on est déjà sorti une fois : le geste
                  // n'est plus le même, et le libellé doit le dire (FR-016).
                  : (revenu ? app.paiementReprendre : app.paiementOuvrir),
            ),
          ),

        // FR-025 — revenue sans confirmation. Le texte ne dit ni « payé » ni
        // « échoué » : il dit ce que le serveur sait, c'est-à-dire rien encore.
        if (revenu && session.accepteEncore) ...[
          const SizedBox(height: MefaliTokens.space3),
          Text(
            app.paiementRevenuSansConfirmation,
            style: theme.textTheme.bodyMedium,
          ),
        ],

        if (onSuivre != null) ...[
          const SizedBox(height: MefaliTokens.space3),
          FilledButton(
            onPressed: onSuivre,
            child: Text(app.parcoursSuivreCommande),
          ),
        ],
      ],
    );
  }

  /// `mm:ss` — jamais de valeur négative, le porteur d'état la borne déjà.
  static String _duree(int secondes) {
    final s = secondes < 0 ? 0 : secondes;
    final minutes = (s ~/ 60).toString().padLeft(2, '0');
    final reste = (s % 60).toString().padLeft(2, '0');
    return '$minutes:$reste';
  }
}

/// Bandeau d'état — motif du cadre C4-4b (`docs/design/png/C4-suivi-commande.png`).
class _BandeauEtat extends StatelessWidget {
  const _BandeauEtat({required this.session});

  final EtatSessionPaiement session;

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (icone, libelle) = switch (session.etat) {
      'reglee' => (Symbols.check_circle_rounded, app.paiementEtatReglee),
      'echouee' => (Symbols.error_rounded, app.paiementEtatEchouee),
      'expiree' || 'payee_hors_delai' => (
          Symbols.schedule_rounded,
          app.paiementEtatExpiree,
        ),
      // Un état inconnu vient d'un serveur plus récent que l'app : on rend
      // l'attente plutôt qu'une chaîne technique.
      _ => (Symbols.hourglass_top_rounded, app.paiementEtatOuverte),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MefaliTokens.space3),
        child: Row(
          children: [
            Icon(icone),
            const SizedBox(width: MefaliTokens.space3),
            Expanded(
              child: Text(libelle, style: theme.textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}
