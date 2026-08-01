import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';
import '../course/etat_course.dart';
import 'etat_remise.dart';

/// Scan du **QR de réception du client** — la voie principale de K4-1a.
///
/// À ne pas confondre avec `EcranScan` (cycle 006), qui lit la plaque d'un
/// **vendeur** : ce sont deux secrets différents, deux empreintes différentes,
/// et deux moments différents de la course. Les fusionner aurait rendu possible
/// de clore une livraison en scannant une plaque de vendeur.
///
/// Aucun appel réseau pour vérifier : l'empreinte du jeton est
/// pré-provisionnée, la comparaison a lieu sur l'appareil (FR-040), et le
/// serveur revalide au rejeu (FR-046).
class EcranScanRemise extends ConsumerStatefulWidget {
  /// Crée l'écran de scan du QR client.
  const EcranScanRemise({super.key, required this.etat});

  /// La course, arrivée chez le client.
  final EtatCourse etat;

  @override
  ConsumerState<EcranScanRemise> createState() => _EcranScanRemiseState();
}

class _EcranScanRemiseState extends ConsumerState<EcranScanRemise> {
  final _controleur = MobileScannerController();
  bool _enCours = false;
  // Anti-tempête : `MobileScanner` réémet le même QR plusieurs fois par
  // seconde. Sans refroidissement, un refus déclencherait une rafale de POST
  // identiques (piège corrigé au cycle 006).
  DateTime? _dernierTraite;
  static const _refroidissement = Duration(seconds: 3);

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  /// Extrait le jeton d'une valeur scannée. Le QR client encode le jeton nu, ou
  /// une URL dont il est le paramètre `t` — même convention que la plaque.
  String _jetonDe(String valeur) {
    final t = Uri.tryParse(valeur)?.queryParameters['t'];
    return (t != null && t.isNotEmpty) ? t : valeur;
  }

  Future<void> _surScan(BarcodeCapture capture) async {
    if (_enCours) return;
    final maintenant = DateTime.now();
    final dernier = _dernierTraite;
    if (dernier != null && maintenant.difference(dernier) < _refroidissement) {
      return;
    }
    final valeur = capture.barcodes.firstOrNull?.rawValue;
    if (valeur == null) return;
    _dernierTraite = maintenant;

    final livraison = widget.etat.livraisonId;
    final commande = widget.etat.commandeId;
    if (livraison == null || commande == null) return;

    setState(() => _enCours = true);
    final notifier = ref.read(etatRemiseProvider.notifier)
      ..choisirVoie(VoieRemise.qr);
    final ok = await notifier.confirmer(
      livraisonId: livraison,
      commandeId: commande,
      jeton: _jetonDe(valeur),
    );
    if (!mounted) return;
    setState(() => _enCours = false);
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final erreur = ref.watch(etatRemiseProvider.select((e) => e.erreurCle));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.crsRemiseScannerQrClient)),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controleur,
              onDetect: _surScan,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MefaliTokens.screenMargin),
            child: Column(
              children: [
                if (erreur != null)
                  Text(
                    l10n.crsErreurCodeIncorrect,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: MefaliTokens.danger),
                  ),
                const SizedBox(height: MefaliTokens.space2),
                // La rassurance de K4-1c : le scan n'a jamais eu besoin du
                // réseau, et c'est tout l'intérêt du pré-provisionnement.
                Text(
                  l10n.crsRemiseScanEtCodeSansReseau,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: MefaliTokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
