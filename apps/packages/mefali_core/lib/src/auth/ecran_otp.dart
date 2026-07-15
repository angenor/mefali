import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../theme/tokens.dart';
import 'cadre_auth.dart';

/// Longueur du code — constante PRODUIT, alignée sur `comptes::otp::OTP_LONGUEUR`.
const int longueurCodeOtp = 6;

/// Délai avant de pouvoir redemander un code. Purement ERGONOMIQUE : le vrai
/// garde-fou est le plafond serveur de 3 SMS/h/numéro (FR-003), qu'aucun
/// client ne peut contourner. Ce compte à rebours évite juste à l'utilisateur
/// de brûler son quota en tapotant.
const Duration delaiRenvoiOtp = Duration(seconds: 60);

/// Saisie du code à 6 chiffres (CPT-01).
class EcranOtp extends StatefulWidget {
  /// Crée l'écran de saisie du code.
  const EcranOtp({
    super.key,
    required this.onValider,
    required this.onRenvoyer,
    this.erreur,
    this.enCours = false,
  });

  /// Appelé quand un code de 6 chiffres est prêt.
  final ValueChanged<String> onValider;

  /// Redemande un code (le précédent devient caduc — FR-002).
  final VoidCallback onRenvoyer;

  /// Message d'erreur (déjà traduit).
  final String? erreur;

  /// Requête en cours.
  final bool enCours;

  @override
  State<EcranOtp> createState() => _EcranOtpState();
}

class _EcranOtpState extends State<EcranOtp> {
  final TextEditingController _controleur = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _minuteur;
  int _secondesRestantes = delaiRenvoiOtp.inSeconds;

  @override
  void initState() {
    super.initState();
    // Le PARENT écoute la saisie : c'est lui qui calcule `complet` et active
    // l'action. Laisser ce setState au widget des cases ne rafraîchirait
    // qu'elles — le bouton « Valider » resterait inerte à jamais.
    _controleur.addListener(_surSaisie);
    _demarrerCompteARebours();
  }

  void _surSaisie() => setState(() {});

  @override
  void dispose() {
    _minuteur?.cancel();
    _controleur.removeListener(_surSaisie);
    _controleur.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _demarrerCompteARebours() {
    _minuteur?.cancel();
    setState(() => _secondesRestantes = delaiRenvoiOtp.inSeconds);
    _minuteur = Timer.periodic(const Duration(seconds: 1), (minuteur) {
      if (!mounted) {
        minuteur.cancel();
        return;
      }
      setState(() => _secondesRestantes--);
      if (_secondesRestantes <= 0) minuteur.cancel();
    });
  }

  void _renvoyer() {
    _controleur.clear();
    _demarrerCompteARebours();
    widget.onRenvoyer();
  }

  void _valider() {
    if (_controleur.text.length == longueurCodeOtp) {
      widget.onValider(_controleur.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    final complet = _controleur.text.length == longueurCodeOtp;
    final peutRenvoyer = _secondesRestantes <= 0 && !widget.enCours;

    return CadreAuth(
      titre: l10n.authOtpTitre,
      aide: l10n.authOtpAide,
      picto: Symbols.lock,
      erreur: widget.erreur,
      action: BoutonPrincipal(
        libelle: l10n.authOtpAction,
        picto: Symbols.check,
        enCours: widget.enCours,
        actif: complet,
        onPresse: _valider,
      ),
      corps: [
        _CasesCode(controleur: _controleur, focus: _focus),
        const SizedBox(height: MefaliTokens.space4),
        // Cible ≥ 48 dp même désactivée (le libellé change, pas la place).
        SizedBox(
          height: MefaliTokens.tapMin,
          child: TextButton.icon(
            onPressed: peutRenvoyer ? _renvoyer : null,
            icon: const Icon(Symbols.refresh),
            label: Text(
              peutRenvoyer
                  ? l10n.authOtpRenvoyer
                  : l10n.authOtpRenvoyerDans(_secondesRestantes),
            ),
          ),
        ),
      ],
    );
  }
}

/// Six cases affichant le code. Sans état : le parent écoute le contrôleur et
/// reconstruit — une double source de rafraîchissement se désynchroniserait.
///
/// UN seul champ invisible capte la saisie, six cases l'affichent. Six vrais
/// `TextField` chaînés par des `FocusNode` est le piège classique : le
/// collage d'un code, la correction et le clavier SMS d'Android s'y cassent.
class _CasesCode extends StatelessWidget {
  const _CasesCode({required this.controleur, required this.focus});

  final TextEditingController controleur;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Champ réel, invisible mais bien présent (jamais Offstage : il doit
        // rester focalisable et recevoir l'autofill SMS).
        SizedBox(
          height: MefaliTokens.tapMin,
          child: TextField(
            controller: controleur,
            focusNode: focus,
            autofocus: true,
            keyboardType: TextInputType.number,
            // Autofill du code reçu par SMS (Android) — zéro friction.
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(longueurCodeOtp),
            ],
            showCursor: false,
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        // Cases affichées, non interactives : le tap traverse vers le champ.
        IgnorePointer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(longueurCodeOtp, (i) {
              final saisi = controleur.text;
              final rempli = i < saisi.length;
              final actif = i == saisi.length;
              return Container(
                width: MefaliTokens.tapMin,
                height: MefaliTokens.buttonHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MefaliTokens.surface,
                  borderRadius: BorderRadius.circular(MefaliTokens.radiusButton),
                  border: Border.all(
                    color: actif ? MefaliTokens.primary : MefaliTokens.border,
                    width: actif ? 2 : 1,
                  ),
                ),
                child: Text(
                  rempli ? saisi[i] : '',
                  style: const TextStyle(
                    fontSize: MefaliTokens.titleSize,
                    fontWeight: MefaliTokens.weightSemiBold,
                    color: MefaliTokens.text,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
