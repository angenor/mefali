import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';
import 'etat_course.dart';

/// Écran de scan de la plaque (QRC-02/03/04). `mobile_scanner` lit le QR,
/// `geolocator` fournit la position de la porte de présence anti-fraude, et le
/// mode dégradé (code 4 chiffres, 3 essais) prend le relais si le QR est
/// illisible. Réf. `docs/design/png/K3-course-active.png`.
class EcranScan extends ConsumerStatefulWidget {
  /// Crée l'écran de scan pour un arrêt.
  const EcranScan({required this.arret, super.key});

  /// Arrêt courant à collecter.
  final ArretCourse arret;

  @override
  ConsumerState<EcranScan> createState() => _EcranScanState();
}

class _EcranScanState extends ConsumerState<EcranScan> {
  final _controleurScan = MobileScannerController();
  final _codeCtrl = TextEditingController();
  bool _modeDegrade = false;
  bool _enCours = false;
  int _essais = 0;
  static const _maxEssais = 3;

  @override
  void dispose() {
    _controleurScan.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  /// Extrait le jeton d'une valeur scannée (URL `.../p/{jeton}` ou jeton brut).
  String _jetonDe(String valeur) {
    final uri = Uri.tryParse(valeur);
    if (uri != null && uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    return valeur;
  }

  /// Position courante (porte de présence). `null` si permission refusée.
  Future<Position?> _position() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition();
  }

  Future<void> _surScan(BarcodeCapture capture) async {
    if (_enCours || _modeDegrade) return;
    final valeur = capture.barcodes.firstOrNull?.rawValue;
    if (valeur == null) return;
    await _collecter(mode: ModeScan.scanQr, jeton: _jetonDe(valeur));
  }

  Future<void> _surCode() async {
    if (_enCours) return;
    if (_essais >= _maxEssais) return;
    setState(() => _essais++);
    await _collecter(mode: ModeScan.codeSecours, code: _codeCtrl.text.trim());
  }

  Future<void> _collecter({required ModeScan mode, String? jeton, String? code}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _enCours = true);
    try {
      final pos = await _position();
      if (pos == null) {
        _message(l10n.scanPermissionPosition);
        return;
      }
      // Photo si exigée par la politique résolue (image_picker délègue à la caméra).
      List<int>? photo;
      if (widget.arret.photoExigee) {
        final xfile = await ImagePicker().pickImage(source: ImageSource.camera);
        if (xfile == null) {
          _message(l10n.collecteErreurPhotoRequise);
          return;
        }
        photo = await xfile.readAsBytes();
      }

      final erreur = await ref.read(etatCourseActiveProvider.notifier).collecter(
            arretId: widget.arret.arretId,
            mode: mode,
            jeton: jeton,
            code: code,
            positionLat: pos.latitude,
            positionLon: pos.longitude,
            photo: photo,
          );
      if (!mounted) return;
      if (erreur == null) {
        Navigator.of(context).pop();
        return;
      }
      _message(_messageErreur(l10n, erreur));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// Mappe une clé d'erreur serveur vers un message i18n fr.
  String _messageErreur(AppLocalizations l10n, String code) {
    switch (code) {
      case 'hors_zone':
        return l10n.collecteErreurHorsZone;
      case 'plaque_invalide':
        return l10n.collecteErreurPlaqueInvalide;
      case 'prestataire_indisponible':
        return l10n.collecteErreurPrestataireIndisponible;
      case 'photo_requise':
        return l10n.collecteErreurPhotoRequise;
      case 'code_incorrect':
        return l10n.collecteErreurCodeIncorrect;
      case 'code_epuise':
        return l10n.collecteErreurCodeEpuise;
      case 'arret_hors_course':
        return l10n.collecteErreurArretHorsCourse;
      default:
        return l10n.proErreurTitre;
    }
  }

  void _message(String texte) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanTitre)),
      body: SafeArea(
        child: _modeDegrade ? _corpsDegrade(l10n) : _corpsScan(l10n),
      ),
    );
  }

  Widget _corpsScan(AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(child: MobileScanner(controller: _controleurScan, onDetect: _surScan)),
        Padding(
          padding: const EdgeInsets.all(MefaliTokens.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.scanAlignez, textAlign: TextAlign.center),
              const SizedBox(height: MefaliTokens.space3),
              TextButton.icon(
                onPressed: () => setState(() => _modeDegrade = true),
                icon: const Icon(Symbols.dialpad),
                label: Text(l10n.scanModeDegrade),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _corpsDegrade(AppLocalizations l10n) {
    final epuise = _essais >= _maxEssais;
    return Padding(
      padding: const EdgeInsets.all(MefaliTokens.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            enabled: !epuise && !_enCours,
            decoration: InputDecoration(labelText: l10n.scanCodeLabel),
          ),
          const SizedBox(height: MefaliTokens.space2),
          if (_essais > 0 && !epuise)
            Text(
              l10n.scanEssaisRestants(_maxEssais - _essais),
              style: const TextStyle(color: MefaliTokens.warning),
            ),
          if (epuise)
            Text(l10n.collecteErreurCodeEpuise,
                style: const TextStyle(color: MefaliTokens.danger)),
          const SizedBox(height: MefaliTokens.space3),
          BoutonPrincipal(
            libelle: l10n.scanCodeValider,
            picto: Symbols.check,
            onPresse: (epuise || _enCours) ? null : _surCode,
          ),
        ],
      ),
    );
  }
}
