import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../auth/session_auth.dart';
import '../theme/tokens.dart';

/// Appareils connectés au compte, avec déconnexion à distance (CPT-02, FR-008).
///
/// L'écran du téléphone perdu : c'est ici qu'on coupe l'accès sans avoir le
/// téléphone en main (SC-004). La session COURANTE est marquée et ne propose
/// pas de déconnexion à distance — se couper soi-même depuis cette liste
/// laisserait l'utilisateur sur un écran mort ; la déconnexion locale a son
/// propre bouton, ailleurs.
class EcranAppareils extends StatefulWidget {
  /// Crée l'écran des appareils.
  const EcranAppareils({super.key, required this.session});

  /// Session courante (client généré + jetons).
  final SessionAuth session;

  @override
  State<EcranAppareils> createState() => _EcranAppareilsState();
}

class _EcranAppareilsState extends State<EcranAppareils> {
  late Future<List<SessionAppareil>> _appareils;

  @override
  void initState() {
    super.initState();
    _appareils = _charger();
  }

  Future<List<SessionAppareil>> _charger() async {
    final reponse = await widget.session.client.getMoiApi().mesSessions();
    return reponse.data?.toList() ?? const [];
  }

  Future<void> _revoquer(SessionAppareil appareil) async {
    await widget.session.client.getMoiApi().revoquerSession(
          sessionId: appareil.id,
        );
    if (!mounted) return;
    // Corps de BLOC, jamais `setState(() => _appareils = _charger())` : la
    // lambda fléchée RETOURNE le Future de l'affectation, et Flutter rejette
    // un callback de setState qui rend un Future. La liste ne se serait
    // jamais rafraîchie après une révocation.
    setState(() {
      _appareils = _charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appareilsTitre)),
      body: FutureBuilder<List<SessionAppareil>>(
        future: _appareils,
        builder: (context, instantane) {
          if (instantane.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (instantane.hasError) {
            return _Message(texte: l10n.appareilsErreur, picto: Symbols.cloud_off);
          }
          final appareils = instantane.data ?? const [];
          if (appareils.isEmpty) {
            return _Message(texte: l10n.appareilsVide, picto: Symbols.devices);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(MefaliTokens.screenMargin),
            itemCount: appareils.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: MefaliTokens.space2),
            itemBuilder: (context, i) => _Carte(
              appareil: appareils[i],
              onRevoquer: () => _revoquer(appareils[i]),
            ),
          );
        },
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({required this.appareil, required this.onRevoquer});

  final SessionAppareil appareil;
  final VoidCallback onRevoquer;

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
      child: Row(
        children: [
          Icon(
            appareil.appareilPlateforme == PlateformeDto.ios
                ? Symbols.phone_iphone
                : Symbols.phone_android,
            color: MefaliTokens.textMuted,
          ),
          const SizedBox(width: MefaliTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appareil.appareilNom, style: textTheme.titleMedium),
                if (appareil.courante) ...[
                  const SizedBox(height: MefaliTokens.space1),
                  _Puce(texte: l10n.appareilsCourant),
                ],
              ],
            ),
          ),
          if (!appareil.courante)
            IconButton(
              onPressed: onRevoquer,
              icon: const Icon(Symbols.logout),
              tooltip: l10n.appareilsDeconnecter,
              // Cible ≥ 48 dp (tokens) — un bouton d'icône fait 40 par défaut.
              constraints: const BoxConstraints(
                minWidth: MefaliTokens.tapMin,
                minHeight: MefaliTokens.tapMin,
              ),
              color: MefaliTokens.danger,
            ),
        ],
      ),
    );
  }
}

/// Puce de statut — fond teinté, texte foncé (`.mf-chip`).
class _Puce extends StatelessWidget {
  const _Puce({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MefaliTokens.space2,
        vertical: MefaliTokens.space1,
      ),
      decoration: BoxDecoration(
        color: MefaliTokens.successTint,
        borderRadius: BorderRadius.circular(MefaliTokens.radiusChip),
      ),
      child: Text(
        texte,
        style: const TextStyle(
          fontSize: MefaliTokens.bodySize,
          color: MefaliTokens.text,
          fontWeight: MefaliTokens.weightMedium,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.texte, required this.picto});

  final String texte;
  final IconData picto;

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}
