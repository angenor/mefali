import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import '../../l10n/app_localizations.dart';

/// Feuille de modification des horaires hebdomadaires (FR-034 — « ✎ Changer
/// les horaires », maquette V1). Un jour SANS plage est un jour de fermeture
/// (FR-031) ; l'édition porte UNE plage par jour au MVP — le modèle et
/// l'affichage en acceptent plusieurs, l'API admin les pose déjà.
Future<void> afficherFeuilleHoraires(
  BuildContext context, {
  required HorairesSemaineDto horaires,
  required Future<void> Function(HorairesSemaineDto) onEnregistrer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FeuilleHoraires(
      horaires: horaires,
      onEnregistrer: onEnregistrer,
    ),
  );
}

class _FeuilleHoraires extends StatefulWidget {
  const _FeuilleHoraires({required this.horaires, required this.onEnregistrer});

  final HorairesSemaineDto horaires;
  final Future<void> Function(HorairesSemaineDto) onEnregistrer;

  @override
  State<_FeuilleHoraires> createState() => _FeuilleHorairesState();
}

class _JourEdite {
  _JourEdite({required this.ouvert, required this.debut, required this.fin});

  bool ouvert;
  TimeOfDay debut;
  TimeOfDay fin;
}

class _FeuilleHorairesState extends State<_FeuilleHoraires> {
  /// Brouillon LOCAL (constitution XII) — 7 jours, une plage éditable.
  late final List<_JourEdite> _jours;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _jours = [
      for (var jour = 0; jour < 7; jour++)
        _JourEdite(
          ouvert: widget.horaires.jours[jour].isNotEmpty,
          debut: _heure(
            widget.horaires.jours[jour].isNotEmpty
                ? widget.horaires.jours[jour].first.debut
                : '08:00',
          ),
          fin: _heure(
            widget.horaires.jours[jour].isNotEmpty
                ? widget.horaires.jours[jour].first.fin
                : '19:00',
          ),
        ),
    ];
  }

  static TimeOfDay _heure(String hhmm) {
    final morceaux = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(morceaux[0]) ?? 8,
      minute: int.tryParse(morceaux.elementAtOrNull(1) ?? '0') ?? 0,
    );
  }

  static String _texte(TimeOfDay heure) =>
      '${heure.hour.toString().padLeft(2, '0')}:${heure.minute.toString().padLeft(2, '0')}';

  Future<void> _choisir(int jour, bool debut) async {
    final courant = debut ? _jours[jour].debut : _jours[jour].fin;
    final choisi = await showTimePicker(context: context, initialTime: courant);
    if (choisi == null) return;
    setState(() {
      if (debut) {
        _jours[jour].debut = choisi;
      } else {
        _jours[jour].fin = choisi;
      }
    });
  }

  bool get _valide => _jours.every((j) =>
      !j.ouvert ||
      j.debut.hour * 60 + j.debut.minute < j.fin.hour * 60 + j.fin.minute);

  Future<void> _enregistrer() async {
    setState(() => _enCours = true);
    final dto = HorairesSemaineDto((b) => b
      ..jours.replace([
        for (final jour in _jours)
          BuiltList<PlageDto>(
            jour.ouvert
                ? [
                    PlageDto((p) => p
                      ..debut = _texte(jour.debut)
                      ..fin = _texte(jour.fin)),
                  ]
                : const <PlageDto>[],
          ),
      ]));
    try {
      await widget.onEnregistrer(dto);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final noms = l10n.proJours.split('|');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: MefaliTokens.screenMargin,
          right: MefaliTokens.screenMargin,
          top: MefaliTokens.space3,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + MefaliTokens.space3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.proBoutiqueHorairesTitre,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: MefaliTokens.space2),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var jour = 0; jour < 7; jour++)
                    Row(
                      children: [
                        SizedBox(width: 48, child: Text(noms[jour])),
                        Switch.adaptive(
                          value: _jours[jour].ouvert,
                          onChanged: (valeur) =>
                              setState(() => _jours[jour].ouvert = valeur),
                        ),
                        const SizedBox(width: MefaliTokens.space2),
                        if (_jours[jour].ouvert) ...[
                          TextButton(
                            onPressed: () => _choisir(jour, true),
                            child: Text(_texte(_jours[jour].debut)),
                          ),
                          const Text('—'),
                          TextButton(
                            onPressed: () => _choisir(jour, false),
                            child: Text(_texte(_jours[jour].fin)),
                          ),
                        ] else
                          Text(
                            l10n.proBoutiqueFermeAujourdhui,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: MefaliTokens.textMuted),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: MefaliTokens.space3),
            FilledButton(
              onPressed: _valide && !_enCours ? _enregistrer : null,
              child: Text(l10n.proArticleEnregistrer),
            ),
          ],
        ),
      ),
    );
  }
}
