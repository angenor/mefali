import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'etat_remise.dart';

/// Saisie du code de réception à 4 chiffres (K4-1b) et, quand le plafond est
/// atteint, l'écran de blocage (K4-1d).
///
/// Réf. `docs/design/png/K4-confirmation-livraison.png` états 1b et 1d ; valeurs
/// de `docs/design/tokens.md`. **Un seul écran pour deux états** parce que c'est
/// une seule destination pour Yao : « le code de réception ». Le faire basculer
/// visuellement plutôt que naviguer ailleurs est ce qui rend le blocage
/// compréhensible — il arrive là où on saisissait, pas dans un ailleurs.
class PaveCode extends ConsumerStatefulWidget {
  /// Crée l'écran de saisie du code.
  const PaveCode({
    super.key,
    required this.livraisonId,
    required this.commandeId,
    this.onReessayerScan,
    this.contactAgence,
  });

  /// Course concernée.
  final String livraisonId;

  /// Commande — **sel** de l'empreinte du code (R3).
  final String commandeId;

  /// Retour au scan QR — la voie qui reste ouverte même bloqué (FR-043).
  final VoidCallback? onReessayerScan;

  /// Contact de l'agence, s'il est déjà résolu. Absent, l'écran le lit lui-même
  /// dans la configuration de zone.
  final ContactAgence? contactAgence;

  @override
  ConsumerState<PaveCode> createState() => _PaveCodeState();
}

/// Le nom et le numéro de l'agence locale, lus dans la configuration de zone.
///
/// Un type nommé plutôt qu'un couple de `String?` : les deux vont ensemble, et
/// l'écran de blocage n'a de sens qu'avec les deux.
class ContactAgence {
  /// Crée un contact d'agence.
  const ContactAgence({required this.nom, required this.telephone});

  /// Nom de la ville (`texte.nom_agence`).
  final String nom;

  /// Numéro E.164 (`texte.telephone_agence`).
  final String telephone;
}

class _PaveCodeState extends ConsumerState<PaveCode> {
  /// Chiffres saisis. Quatre cases, pas un `TextField` : la maquette montre des
  /// cases, et un clavier système sur un écran tenu à bout de bras en plein
  /// soleil est le pire des pavés numériques.
  String _saisie = '';
  bool _enCours = false;
  ContactAgence? _agence;

  static const _longueur = 4;

  @override
  void initState() {
    super.initState();
    _agence = widget.contactAgence;
    if (_agence == null) unawaited(_chargerAgence());
  }

  /// Lit le contact de l'agence dans la configuration de zone (FR-043).
  ///
  /// `serviceConfigProvider` expose un **service**, jamais une valeur observée
  /// (FR-021) : on le lit une fois ici plutôt que d'introduire un `AsyncValue`
  /// dans un écran qui doit s'afficher même sans réseau. Le service sert sa
  /// dernière configuration connue depuis son cache local.
  Future<void> _chargerAgence() async {
    final service = await ref.read(serviceConfigProvider);
    final config = service.courante;
    final nom = config?.nomAgence;
    final telephone = config?.telephoneAgence;
    if (!mounted || nom == null || telephone == null) return;
    setState(() => _agence = ContactAgence(nom: nom, telephone: telephone));
  }

  void _taper(String chiffre) {
    if (_saisie.length >= _longueur) return;
    setState(() => _saisie += chiffre);
  }

  void _effacer() {
    if (_saisie.isEmpty) return;
    setState(() => _saisie = _saisie.substring(0, _saisie.length - 1));
  }

  Future<void> _valider() async {
    if (_saisie.length < _longueur || _enCours) return;
    setState(() => _enCours = true);
    final ok = await ref.read(etatRemiseProvider.notifier).confirmer(
          livraisonId: widget.livraisonId,
          commandeId: widget.commandeId,
          code: _saisie,
        );
    if (!mounted) return;
    setState(() {
      _enCours = false;
      // Un code faux vide les cases : laisser les chiffres refusés à l'écran
      // invite à en changer un seul, c'est-à-dire à deviner.
      if (!ok) _saisie = '';
    });
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final etat = ref.watch(etatRemiseProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.crsRemiseCodeTitre)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: etat.codeBloque
              ? EcranBlocageCode(
                  agence: _agence,
                  onReessayerScan: widget.onReessayerScan,
                )
              : _Saisie(
                  saisie: _saisie,
                  etat: etat,
                  enCours: _enCours,
                  onChiffre: _taper,
                  onEffacer: _effacer,
                  onValider: _valider,
                ),
        ),
      ),
    );
  }
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.saisie,
    required this.etat,
    required this.enCours,
    required this.onChiffre,
    required this.onEffacer,
    required this.onValider,
  });

  final String saisie;
  final EtatRemise etat;
  final bool enCours;
  final void Function(String) onChiffre;
  final VoidCallback onEffacer;
  final VoidCallback onValider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.crsRemiseCodeConsigne,
          style: textTheme.bodyMedium?.copyWith(color: MefaliTokens.textMuted),
        ),
        const SizedBox(height: MefaliTokens.space3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 4; i++) ...[
              _Case(chiffre: i < saisie.length ? saisie[i] : null),
              if (i < 3) const SizedBox(width: MefaliTokens.space2),
            ],
          ],
        ),
        if (etat.erreurCle != null) ...[
          const SizedBox(height: MefaliTokens.space2),
          // FR-042 : le nombre d'essais RESTANTS, jamais le bon code ni un
          // indice sur lui. Le compteur affiché est celui que le serveur
          // retiendra (`max(serveur, hors ligne)`) — sinon « il reste 2 essais »
          // mentirait au premier retour de réseau.
          _ChipAvertissement(
            texte: etat.erreurCle == 'remise_incorrecte'
                ? l10n.crsRemiseCodeFauxEssais(etat.essaisRestants)
                : l10n.crsErreurCodeIncorrect,
          ),
        ],
        const SizedBox(height: MefaliTokens.space4),
        _Clavier(onChiffre: onChiffre, onEffacer: onEffacer),
        const Spacer(),
        FilledButton.icon(
          onPressed: saisie.length == 4 && !enCours ? onValider : null,
          icon: const Icon(Symbols.check_rounded),
          label: Text(l10n.crsRemiseCodeValider),
          style: FilledButton.styleFrom(
            backgroundColor: MefaliTokens.success,
            minimumSize: const Size.fromHeight(MefaliTokens.buttonHeight),
          ),
        ),
      ],
    );
  }
}

/// Une case de code : 64 dp, bordure orange dès qu'elle est remplie (K4-1b).
class _Case extends StatelessWidget {
  const _Case({this.chiffre});

  final String? chiffre;

  @override
  Widget build(BuildContext context) {
    final rempli = chiffre != null;
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        border: Border.all(
          color: rempli ? MefaliTokens.primary : MefaliTokens.border,
          width: rempli ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
      ),
      child: Text(
        chiffre ?? '',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: MefaliTokens.weightBold,
            ),
      ),
    );
  }
}

/// Pavé numérique 3 × 4, touches de 64 dp — au-delà du minimum tactile de 48 dp
/// (`MefaliTokens.tapMin`), parce que la saisie a lieu debout, une main occupée
/// par un sac.
class _Clavier extends StatelessWidget {
  const _Clavier({required this.onChiffre, required this.onEffacer});

  final void Function(String) onChiffre;
  final VoidCallback onEffacer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (final rangee in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: MefaliTokens.space2),
            child: Row(
              children: [
                for (final c in rangee) ...[
                  Expanded(child: _Touche(libelle: c, onPresse: () => onChiffre(c))),
                  if (c != rangee.last) const SizedBox(width: MefaliTokens.space2),
                ],
              ],
            ),
          ),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            const SizedBox(width: MefaliTokens.space2),
            Expanded(child: _Touche(libelle: '0', onPresse: () => onChiffre('0'))),
            const SizedBox(width: MefaliTokens.space2),
            Expanded(
              child: _Touche(
                picto: Symbols.backspace_rounded,
                semantique: l10n.crsRemiseCodeEffacer,
                onPresse: onEffacer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Touche extends StatelessWidget {
  const _Touche({
    this.libelle,
    this.picto,
    this.semantique,
    required this.onPresse,
  });

  final String? libelle;
  final IconData? picto;
  final String? semantique;
  final VoidCallback onPresse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: OutlinedButton(
        onPressed: onPresse,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
          ),
        ),
        child: picto != null
            ? Icon(picto, semanticLabel: semantique)
            : Text(
                libelle!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
      ),
    );
  }
}

class _ChipAvertissement extends StatelessWidget {
  const _ChipAvertissement({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MefaliTokens.space3,
          vertical: MefaliTokens.space1,
        ),
        decoration: BoxDecoration(
          color: MefaliTokens.warningTint,
          borderRadius: BorderRadius.circular(MefaliTokens.radiusChip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.error_rounded,
                size: 16, color: MefaliTokens.warning),
            const SizedBox(width: MefaliTokens.space1),
            // `Flexible` et non `Text` nu : « Code faux — il reste 2 essais »
            // déborde d'un écran de 360 dp une fois le pictogramme et les
            // marges retirés. Débordement de 84 px attrapé par le test widget.
            Flexible(
              child: Text(
                texte,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: MefaliTokens.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// **K4-1d** — la saisie par code est fermée (T043).
///
/// Trois choses, et rien d'autre : le motif en langage clair (« pour protéger le
/// client »), l'appel à l'agence en **action principale**, et le scan QR
/// toujours proposé. Le numéro vient de la configuration de zone
/// (`texte.telephone_agence`), jamais d'une constante : un numéro en dur ne se
/// change qu'au prochain passage store.
class EcranBlocageCode extends StatelessWidget {
  /// Crée l'écran de blocage.
  const EcranBlocageCode({
    super.key,
    this.agence,
    this.onReessayerScan,
    this.composer,
  });

  /// Contact de l'agence, lu dans la configuration de zone. `null` tant que la
  /// configuration n'a jamais pu être chargée : l'écran dit alors le motif sans
  /// promettre un appel qu'il ne peut pas passer.
  final ContactAgence? agence;

  /// Retour au scan QR — la voie qui reste ouverte (FR-043).
  final VoidCallback? onReessayerScan;

  /// Composeur injecté (les tests widget ne servent pas le canal natif).
  final Future<bool> Function(String numero)? composer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final numero = agence?.telephone;
    final ville = agence?.nom ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(MefaliTokens.space4),
          decoration: BoxDecoration(
            color: MefaliTokens.surface,
            border: Border.all(color: MefaliTokens.danger),
            borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: MefaliTokens.dangerTint,
                child: Icon(Symbols.lock_rounded, color: MefaliTokens.danger),
              ),
              const SizedBox(height: MefaliTokens.space3),
              Text(
                l10n.crsRemiseBloqueeTitre,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: MefaliTokens.space2),
              Text(
                l10n.crsRemiseBloqueeTexte,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium
                    ?.copyWith(color: MefaliTokens.textMuted),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Action PRINCIPALE : l'appel. C'est la seule chose que Yao peut faire
        // pour avancer, et elle porte le numéro en clair — c'est le numéro de
        // Mefali, pas celui d'un client (aucune minimisation en jeu).
        FilledButton.icon(
          onPressed: numero == null
              ? null
              : () => (composer ?? _composerReel)(numero),
          icon: const Icon(Symbols.call_rounded),
          label: Text(
            numero == null
                ? l10n.crsRemiseBloqueeTitre
                : l10n.crsRemiseAppelerAgence(ville, _lisible(numero)),
            textAlign: TextAlign.center,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: MefaliTokens.danger,
            minimumSize: const Size.fromHeight(MefaliTokens.buttonHeight),
          ),
        ),
        const SizedBox(height: MefaliTokens.space2),
        OutlinedButton.icon(
          onPressed: onReessayerScan,
          icon: const Icon(Symbols.qr_code_scanner_rounded),
          label: Text(l10n.crsRemiseReessayerScan),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(MefaliTokens.buttonHeight),
          ),
        ),
      ],
    );
  }

  static Future<bool> _composerReel(String numero) =>
      launchUrl(Uri(scheme: 'tel', path: numero));

  /// « +2250707551212 » → « 07 07 55 12 12 » : le numéro doit être lisible à
  /// voix haute par quelqu'un qui le compose sur un autre téléphone.
  static String _lisible(String e164) {
    final national = e164.startsWith('+225') ? e164.substring(4) : e164;
    final morceaux = <String>[];
    for (var i = 0; i < national.length; i += 2) {
      morceaux.add(national.substring(i, (i + 2).clamp(0, national.length)));
    }
    return morceaux.join(' ');
  }
}
