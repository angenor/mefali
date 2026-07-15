import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../auth/session_auth.dart';
import '../theme/etats.dart';
import '../theme/tokens.dart';
import 'note_vocale.dart';

/// « Mes adresses » — lister, renommer, supprimer (FR-021).
///
/// Une adresse dont le repère vocal a été purgé (12 mois sans utilisation,
/// FR-022) reste ici et reste utilisable : elle affiche simplement de quoi en
/// réenregistrer un.
class ListeAdresses extends StatefulWidget {
  /// Crée l'écran.
  const ListeAdresses({super.key, required this.session, this.jouerNote = jouerNoteReseau});

  /// Session du compte connecté (porte le client généré, authentifié).
  final SessionAuth session;

  /// Lecteur de note — doublé par les tests.
  final JouerNote jouerNote;

  @override
  State<ListeAdresses> createState() => _ListeAdressesState();
}

class _ListeAdressesState extends State<ListeAdresses> {
  late Future<List<Adresse>> _adresses;

  @override
  void initState() {
    super.initState();
    _adresses = _charger();
  }

  Future<List<Adresse>> _charger() async {
    final reponse = await widget.session.client.getMoiApi().mesAdresses();
    return reponse.data?.toList() ?? const [];
  }

  void _recharger() {
    // Corps de BLOC : `setState(() => x = f())` rendrait un Future, que Flutter
    // rejette.
    setState(() {
      _adresses = _charger();
    });
  }

  Future<String> _urlRepere(String id) async {
    final reponse = await widget.session.client.getMoiApi().ecouterRepereVocal(adresseId: id);
    return reponse.data!.url;
  }

  Future<void> _renommer(Adresse adresse) async {
    final nouveau = await showDialog<String>(
      context: context,
      builder: (context) => _DialogueRenommer(libelle: adresse.libelle),
    );
    if (nouveau == null || nouveau.isEmpty) return;

    await widget.session.client.getMoiApi().modifierAdresse(
          adresseId: adresse.id,
          modifierAdresse: ModifierAdresse((b) => b..libelle = nouveau),
        );
    if (mounted) _recharger();
  }

  Future<void> _supprimer(Adresse adresse) async {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adressesSupprimerTitre(adresse.libelle)),
        content: Text(l10n.adressesSupprimerAide),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.adressesAnnuler),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.adressesSupprimer),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    await widget.session.client.getMoiApi().supprimerAdresse(adresseId: adresse.id);
    if (mounted) _recharger();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adressesTitre)),
      body: FutureBuilder<List<Adresse>>(
        future: _adresses,
        builder: (context, instantane) {
          // Squelettes, jamais un spinner plein écran (docs/design §7).
          if (instantane.connectionState != ConnectionState.done) {
            return const SqueletteListe();
          }
          if (instantane.hasError) {
            return MessageEtat(
              texte: l10n.adressesErreur,
              picto: Symbols.wifi_off,
              // Une erreur réseau SANS action est un cul-de-sac : l'utilisateur
              // n'a plus qu'à tuer l'app (règle d'or 5).
              action: _recharger,
              libelleAction: l10n.actionReessayer,
            );
          }
          final adresses = instantane.data ?? const <Adresse>[];
          if (adresses.isEmpty) {
            return MessageEtat(texte: l10n.adressesVide, picto: Symbols.bookmark);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(MefaliTokens.screenMargin),
            itemCount: adresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: MefaliTokens.space3),
            itemBuilder: (context, i) => _Carte(
              adresse: adresses[i],
              urlRepere: () => _urlRepere(adresses[i].id),
              jouerNote: widget.jouerNote,
              onRenommer: () => _renommer(adresses[i]),
              onSupprimer: () => _supprimer(adresses[i]),
            ),
          );
        },
      ),
    );
  }
}

/// Boîte de renommage — widget à part pour qu'elle POSSÈDE son contrôleur.
///
/// Le disposer depuis l'appelant, juste après `showDialog`, le tuerait pendant
/// que le champ vit encore le temps de l'animation de sortie.
class _DialogueRenommer extends StatefulWidget {
  const _DialogueRenommer({required this.libelle});

  final String libelle;

  @override
  State<_DialogueRenommer> createState() => _DialogueRenommerState();
}

class _DialogueRenommerState extends State<_DialogueRenommer> {
  late final TextEditingController _controleur =
      TextEditingController(text: widget.libelle);

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.adressesRenommer),
      content: TextField(
        controller: _controleur,
        autofocus: true,
        maxLength: 60,
        style: const TextStyle(
          fontSize: MefaliTokens.bodySize,
          height: MefaliTokens.bodyHeight,
        ),
        decoration: InputDecoration(labelText: l10n.adresseLibelleLibre, counterText: ''),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adressesAnnuler),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controleur.text.trim()),
          child: Text(l10n.adressesValider),
        ),
      ],
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({
    required this.adresse,
    required this.urlRepere,
    required this.jouerNote,
    required this.onRenommer,
    required this.onSupprimer,
  });

  final Adresse adresse;
  final Future<String> Function() urlRepere;
  final JouerNote jouerNote;
  final VoidCallback onRenommer;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(MefaliTokens.space3),
      decoration: BoxDecoration(
        color: MefaliTokens.surface,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusCard),
        border: Border.all(color: MefaliTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Symbols.location_on, color: MefaliTokens.textMuted),
              const SizedBox(width: MefaliTokens.space2),
              Expanded(child: Text(adresse.libelle, style: textTheme.titleMedium)),
              IconButton(
                onPressed: onRenommer,
                icon: const Icon(Symbols.edit),
                tooltip: l10n.adressesRenommer,
                constraints: const BoxConstraints(
                  minWidth: MefaliTokens.tapMin,
                  minHeight: MefaliTokens.tapMin,
                ),
              ),
              IconButton(
                onPressed: onSupprimer,
                icon: const Icon(Symbols.delete),
                tooltip: l10n.adressesSupprimer,
                color: MefaliTokens.danger,
                constraints: const BoxConstraints(
                  minWidth: MefaliTokens.tapMin,
                  minHeight: MefaliTokens.tapMin,
                ),
              ),
            ],
          ),
          const SizedBox(height: MefaliTokens.space2),
          if (adresse.aRepereVocal)
            LecteurNoteVocale(
              obtenirUrl: urlRepere,
              repereTexte: adresse.repereTexte,
              dureeS: adresse.repereVocalDureeS,
              jouer: jouerNote,
            )
          else ...[
            // FR-022 — repère purgé (ou jamais posé) : l'adresse RESTE
            // utilisable et en redemande un. On le dit ici plutôt que de
            // laisser un blanc que l'utilisateur lirait comme une perte.
            if (adresse.repereTexte != null && adresse.repereTexte!.isNotEmpty)
              Text(
                adresse.repereTexte!,
                style: textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
              )
            else
              Text(
                l10n.adresseRepereAbsent,
                style: textTheme.bodyLarge?.copyWith(color: MefaliTokens.textMuted),
              ),
          ],
        ],
      ),
    );
  }
}

