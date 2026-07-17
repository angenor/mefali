import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../auth/clients.dart';
import '../theme/etats.dart';
import '../theme/tokens.dart';

part 'ecran_appareils.g.dart';

/// La liste des appareils/sessions du compte. `@riverpod` nu (autoDispose) :
/// écran de liste, aucun état à faire survivre.
@riverpod
class MesSessions extends _$MesSessions {
  @override
  Future<List<SessionAppareil>> build() => _charger();

  Future<List<SessionAppareil>> _charger() async {
    final reponse = await ref.read(clientSessionProvider).getMoiApi().mesSessions();
    return reponse.data?.toList() ?? const [];
  }

  /// FR-023 — le squelette DOIT réapparaître, comme le
  /// `setState(() => _appareils = _charger())` d'avant (retour en
  /// `ConnectionState.waiting`). `state = const AsyncLoading()` EXPLICITE : à un
  /// seul endroit, `.when()` reste aux défauts partout (R9).
  Future<void> recharger() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_charger);
  }

  /// Déconnecte un appareil à distance puis réaffiche le squelette (CPT-02).
  Future<void> revoquer(String sessionId) async {
    await ref.read(clientSessionProvider).getMoiApi().revoquerSession(
          sessionId: sessionId,
        );
    await recharger();
  }
}

/// Appareils connectés au compte, avec déconnexion à distance (CPT-02, FR-008).
///
/// L'écran du téléphone perdu : c'est ici qu'on coupe l'accès sans avoir le
/// téléphone en main (SC-004). La session COURANTE est marquée et ne propose
/// pas de déconnexion à distance — se couper soi-même depuis cette liste
/// laisserait l'utilisateur sur un écran mort ; la déconnexion locale a son
/// propre bouton, ailleurs.
class EcranAppareils extends ConsumerWidget {
  /// Crée l'écran des appareils.
  const EcranAppareils({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final appareils = ref.watch(mesSessionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appareilsTitre)),
      body: appareils.when(
        // Squelettes, jamais un spinner plein écran (docs/design §7).
        loading: () => const SqueletteListe(hauteurLigne: 72),
        error: (erreur, _) => MessageEtat(
          texte: l10n.appareilsErreur,
          picto: Symbols.cloud_off,
          // Une erreur réseau SANS action est un cul-de-sac — et ici elle
          // bloquerait la révocation d'un téléphone perdu (règle d'or 5).
          action: () => ref.read(mesSessionsProvider.notifier).recharger(),
          libelleAction: l10n.actionReessayer,
        ),
        data: (appareils) {
          if (appareils.isEmpty) {
            return MessageEtat(texte: l10n.appareilsVide, picto: Symbols.devices);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(MefaliTokens.screenMargin),
            itemCount: appareils.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: MefaliTokens.space2),
            itemBuilder: (context, i) => _Carte(
              appareil: appareils[i],
              onRevoquer: () =>
                  ref.read(mesSessionsProvider.notifier).revoquer(appareils[i].id),
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
