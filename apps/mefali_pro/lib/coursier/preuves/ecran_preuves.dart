import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';
import 'etat_preuves.dart';

/// **K4-1e** — les trois preuves et leur décompte (T059).
///
/// Réf. `docs/design/png/K4-confirmation-livraison.png` état 1e ; valeurs de
/// `docs/design/tokens.md`.
///
/// Ce que cet écran doit rendre visible, et pourquoi c'est produit et non
/// décoratif : **le bouton reste gris tant que les trois preuves ne sont pas
/// réunies**, et chaque preuve DIT où elle en est. Un compteur figé sans
/// explication ferait recommencer Yao au hasard — deux appels de plus, une
/// photo de plus — alors qu'il lui manque peut-être seulement trois minutes
/// d'attente (FR-058).
///
/// La minuterie d'affichage (« encore 4 min ») est **locale à ce widget** :
/// dans un provider, elle survivrait à l'écran et ferait échouer les tests par
/// « a Timer is still pending » (piège du cycle 004, constitution XII).
class EcranPreuves extends ConsumerStatefulWidget {
  /// Crée l'écran des preuves.
  const EcranPreuves({
    super.key,
    required this.livraisonId,
    this.onAppeler,
    this.prendrePhoto,
    this.onDeclare,
    this.echantillonner = true,
  });

  /// Livraison dont on réunit les preuves.
  final String livraisonId;

  /// Compose le numéro du client — **sans jamais l'afficher** (FR-034).
  final Future<void> Function()? onAppeler;

  /// Capture de la photo de preuve. Injectable : `image_picker` passe par un
  /// canal de plateforme qu'un test widget ne sert pas.
  final Future<List<int>?> Function()? prendrePhoto;

  /// Appelé quand l'échec a été déclaré (ou enfilé) avec succès.
  final VoidCallback? onDeclare;

  /// Échantillonner la présence pendant que l'écran est ouvert.
  ///
  /// Désactivable pour les tests widget : un échantillonnage réel demanderait
  /// le GPS, que le canal de plateforme ne sert pas sous test.
  final bool echantillonner;

  @override
  ConsumerState<EcranPreuves> createState() => _EcranPreuvesState();
}

class _EcranPreuvesState extends ConsumerState<EcranPreuves> {
  /// Minuterie d'ÉCHANTILLONNAGE — locale au widget, arrêtée avec lui.
  Timer? _echantillonnage;
  bool _declarationEnCours = false;

  @override
  void initState() {
    super.initState();
    // Après le premier rendu : `charger` écrit dans un provider, et le faire
    // pendant la construction de l'arbre est le piège relevé au cycle 004.
    Future.microtask(() async {
      final notifier = ref.read(etatPreuvesProvider.notifier);
      await notifier.charger(widget.livraisonId);
      if (!mounted || !widget.echantillonner) return;
      await notifier.echantillonnerPresence(widget.livraisonId);
      if (!mounted) return;
      _echantillonnage = Timer.periodic(periodeEchantillonPresence, (_) {
        ref
            .read(etatPreuvesProvider.notifier)
            .echantillonnerPresence(widget.livraisonId);
      });
    });
  }

  @override
  void dispose() {
    _echantillonnage?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final etat = ref.watch(etatPreuvesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.crsPreuvesTitre)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          children: [
            Text(l10n.crsPreuvesConsigne, style: theme.textTheme.bodyMedium),
            const SizedBox(height: MefaliTokens.space3),

            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _LignePreuve(
                    etat: etat.appels.etat,
                    titre: l10n.crsPreuveAppels(etat.appels.requis),
                    detail: _detailAppels(l10n, etat.appels),
                    action: TextButton.icon(
                      onPressed: widget.onAppeler == null
                          ? null
                          : () => _appeler(),
                      icon: const Icon(Symbols.call, size: 18),
                      label: Text(l10n.crsAppeler),
                    ),
                  ),
                  const Divider(height: 1),
                  _LignePreuve(
                    etat: etat.presence.etat,
                    titre: l10n.crsPreuvePresence(etat.presence.requis ~/ 60),
                    detail: _detailPresence(l10n, etat.presence),
                    action: Chip(
                      label: Text(
                        l10n.crsPreuvePresenceRatio(
                          etat.presence.secondes ~/ 60,
                          etat.presence.requis ~/ 60,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Divider(height: 1),
                  _LignePreuve(
                    etat: etat.photos.etat,
                    titre: l10n.crsPreuvePhoto(etat.photos.requis),
                    detail: etat.photos.ok ? null : l10n.crsPreuveAFaire,
                    action: OutlinedButton.icon(
                      onPressed: widget.prendrePhoto == null
                          ? null
                          : () => _photographier(),
                      icon: const Icon(Symbols.photo_camera, size: 18),
                      label: Text(l10n.crsPreuvePhotoAction),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MefaliTokens.space3),
            // Le compteur global, répété en chip : c'est lui que Yao regarde
            // pour savoir s'il peut partir.
            Center(
              child: Chip(
                key: const Key('preuves-compteur'),
                backgroundColor: etat.reunies
                    ? MefaliTokens.successTint
                    : MefaliTokens.warningTint,
                label: Text(
                  l10n.crsPreuvesCompteur(etat.reuniesSur, EtatPreuvesVue.total),
                ),
              ),
            ),

            if (etat.enAttenteDeSynchro) ...[
              const SizedBox(height: MefaliTokens.space3),
              BandeauHorsLigne(message: l10n.crsHorsLigneBandeau),
            ],
            if (etat.erreurCle != null) ...[
              const SizedBox(height: MefaliTokens.space3),
              Text(
                _messageErreur(l10n, etat.erreurCle!),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: MefaliTokens.danger),
              ),
            ],

            const SizedBox(height: MefaliTokens.space4),
            // ⚠ GRISÉ tant que les trois preuves ne sont pas réunies (FR-058).
            // Le serveur refuserait de toute façon (FR-060) ; le griser ici
            // évite à Yao de croire qu'il a fini.
            FilledButton.icon(
              key: const Key('preuves-declarer'),
              onPressed: etat.reunies && !_declarationEnCours
                  ? () => _declarer()
                  : null,
              icon: const Icon(Symbols.gpp_maybe),
              label: Text(l10n.crsPreuvesDeclarer),
            ),
            const SizedBox(height: MefaliTokens.space2),
            OutlinedButton.icon(
              onPressed: widget.onAppeler == null ? null : () => _appeler(),
              icon: const Icon(Symbols.call),
              label: Text(l10n.crsPreuvesRappelerClient),
            ),
          ],
        ),
      ),
    );
  }

  String _detailAppels(AppLocalizations l10n, PreuveAppelsVue appels) {
    // Deux appels trop rapprochés : dire « attends », pas « rappelle ». Le
    // délai vient de la zone, jamais d'un nombre écrit ici.
    if (!appels.espacementOk && !appels.ok) {
      return l10n.crsPreuveAppelsTropRapproches(appels.espacementS);
    }
    if (appels.horodatages.isEmpty) return l10n.crsPreuveAFaire;
    final heures = appels.horodatages
        .map((h) => '${h.hour.toString().padLeft(2, '0')}:'
            '${h.minute.toString().padLeft(2, '0')}')
        .join(' et ');
    return l10n.crsPreuveAppelsFaits(heures);
  }

  String _detailPresence(AppLocalizations l10n, PreuvePresenceVue presence) {
    if (presence.ok) return l10n.crsPreuveAppelsFaits('');
    if (presence.gpsIndisponible) return l10n.crsPreuvePresenceGpsAbsent;
    if (presence.horsRayon) {
      return l10n.crsPreuvePresenceTropLoin(presence.distanceM ?? 0);
    }
    return l10n.crsPreuvePresenceEnCours(presence.minutesRestantes);
  }

  String _messageErreur(AppLocalizations l10n, String cle) => switch (cle) {
        'preuves_incompletes' => l10n.crsErreurPreuvesIncompletes,
        'course_non_proprietaire' => l10n.crsErreurCourseNonProprietaire,
        'depot_non_autorise' => l10n.crsErreurDepotNonAutorise,
        _ => l10n.crsErreurPreuvesIncompletes,
      };

  /// L'appel lui-même passe par `ActionsAppel` (journalisation + composition +
  /// issue déclarée) ; l'écran ne fait que tenir son décompte local à jour.
  Future<void> _appeler() async {
    await widget.onAppeler?.call();
    if (!mounted) return;
    await ref
        .read(etatPreuvesProvider.notifier)
        .noterAppelClientAbsent(widget.livraisonId);
  }

  Future<void> _photographier() async {
    final octets = await widget.prendrePhoto?.call();
    if (octets == null || !mounted) return;
    await ref
        .read(etatPreuvesProvider.notifier)
        .deposerPhoto(widget.livraisonId, octets);
  }

  Future<void> _declarer() async {
    setState(() => _declarationEnCours = true);
    final abouti = await ref.read(etatPreuvesProvider.notifier).declarerEchec(
          livraisonId: widget.livraisonId,
          // §7.5-1 : client injoignable, marchandise non périssable. C'est la
          // seule ligne de l'arbre que CET écran ouvre — les autres se
          // déclarent depuis leur propre contexte (rupture, casse, faux billet).
          typeIssue: 'refus_non_perissable',
          motifCle: 'echec.client_injoignable',
        );
    if (!mounted) return;
    setState(() => _declarationEnCours = false);
    if (abouti) widget.onDeclare?.call();
  }
}

/// Une ligne de preuve : pastille d'état, titre, détail, action (K4-1e).
class _LignePreuve extends StatelessWidget {
  const _LignePreuve({
    required this.etat,
    required this.titre,
    required this.action,
    this.detail,
  });

  final EtatPreuve etat;
  final String titre;
  final String? detail;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icone, couleur) = switch (etat) {
      EtatPreuve.faite => (Symbols.check_circle, MefaliTokens.success),
      EtatPreuve.enCours => (Symbols.more_horiz, MefaliTokens.warning),
      EtatPreuve.aFaire => (Symbols.circle, MefaliTokens.textMuted),
    };

    return ListTile(
      leading: Icon(icone, color: couleur, fill: etat == EtatPreuve.faite ? 1 : 0),
      title: Text(titre, style: theme.textTheme.bodyLarge),
      subtitle: detail == null || detail!.isEmpty
          ? null
          : Text(
              detail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: etat == EtatPreuve.faite
                    ? MefaliTokens.success
                    : MefaliTokens.textMuted,
              ),
            ),
      trailing: etat == EtatPreuve.faite ? null : action,
    );
  }
}
