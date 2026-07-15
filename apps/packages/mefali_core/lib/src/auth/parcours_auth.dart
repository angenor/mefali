import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../config/service_config.dart';
import 'ecran_consentement.dart';
import 'ecran_otp.dart';
import 'ecran_telephone.dart';
import 'session_auth.dart';
import 'stockage_jetons.dart';

/// Étape courante du parcours.
enum _Etape { telephone, otp, consentement }

/// Parcours d'authentification complet — le flux UNIQUE inscription/connexion
/// (CPT-01), partagé par les deux apps (constitution XI).
///
/// L'app appelante ne sait jamais si l'utilisateur s'inscrit ou se reconnecte :
/// c'est le serveur qui tranche, après vérification. Cette ignorance est le
/// mécanisme même de l'anti-énumération (FR-004) — la dupliquer côté client
/// avec un « avez-vous déjà un compte ? » ruinerait la propriété.
class ParcoursAuth extends StatefulWidget {
  /// Crée le parcours.
  const ParcoursAuth({
    super.key,
    required this.session,
    required this.onConnecte,
    this.zone = zoneBootstrapTiassale,
    this.versionConsentement = versionConsentementParDefaut,
    this.nomAppareil = 'Appareil Mefali',
    this.plateforme = PlateformeDto.android,
  });

  /// Session à ouvrir en cas de succès.
  final SessionAuth session;

  /// Appelé une fois la session ouverte (l'app route vers son accueil).
  final VoidCallback onConnecte;

  /// Zone déclarée à l'inscription (research R13).
  final String zone;

  /// Version du texte ARTCI acceptée — servie par la config de zone
  /// (`consentement.artci_version`) ; le défaut n'est qu'un filet.
  final String versionConsentement;

  /// Nom d'appareil affiché dans la liste des sessions.
  final String nomAppareil;

  /// Plateforme déclarée.
  final PlateformeDto plateforme;

  @override
  State<ParcoursAuth> createState() => _ParcoursAuthState();
}

/// Version ARTCI de repli si la config distante n'est pas encore chargée.
/// Alignée sur le seed `20_comptes.sql` (`consentement.artci_version`).
const String versionConsentementParDefaut = '2026-07';

class _ParcoursAuthState extends State<ParcoursAuth> {
  _Etape _etape = _Etape.telephone;
  String _telephone = '';
  String? _jetonInscription;
  String? _erreur;
  bool _enCours = false;

  AuthApi get _api => widget.session.client.getAuthApi();

  /// Traduit un échec réseau en message i18n fr.
  ///
  /// Le 401 de vérification est rendu par la clé NEUTRE, comme le serveur :
  /// afficher « ce numéro n'existe pas » ici trahirait ce que l'API a pris
  /// soin de taire (SC-003).
  String _messageErreur(Object erreur, MefaliCoreLocalizations l10n) {
    if (erreur is DioException) {
      final statut = erreur.response?.statusCode;
      if (statut == 401) return l10n.authErreurCodeInvalide;
      if (statut == 422) {
        final code = erreur.response?.data is Map
            ? (erreur.response!.data as Map)['code']
            : null;
        if (code == 'telephone_invalide') return l10n.authErreurTelephoneInvalide;
      }
    }
    return l10n.authErreurReseau;
  }

  Future<void> _executer(
    MefaliCoreLocalizations l10n,
    Future<void> Function() action,
  ) async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _erreur = _messageErreur(e, l10n));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _demander(MefaliCoreLocalizations l10n, String telephone) =>
      _executer(l10n, () async {
        await _api.demander(
          demandeOtp: DemandeOtp(
            (b) => b
              ..telephone = telephone
              ..zone = widget.zone,
          ),
        );
        if (!mounted) return;
        setState(() {
          _telephone = telephone;
          _etape = _Etape.otp;
        });
      });

  Future<void> _verifier(MefaliCoreLocalizations l10n, String code) =>
      _executer(l10n, () async {
        final reponse = await _api.verifier(
          verificationOtp: VerificationOtp(
            (b) => b
              ..telephone = _telephone
              ..zone = widget.zone
              ..code = code
              ..appareil.nom = widget.nomAppareil
              ..appareil.plateforme = widget.plateforme,
          ),
        );
        await _traiterResultat(reponse.data);
      });

  Future<void> _inscrire(MefaliCoreLocalizations l10n) => _executer(l10n, () async {
        final reponse = await _api.inscrire(
          inscription: Inscription(
            (b) => b
              ..jetonInscription = _jetonInscription!
              ..consentementVersion = widget.versionConsentement,
          ),
        );
        await _traiterResultat(reponse.data);
      });

  /// Deux issues possibles, discriminées par le `oneOf` du contrat.
  Future<void> _traiterResultat(ResultatVerification? resultat) async {
    final valeur = resultat?.oneOf.value;
    if (valeur is ResultatVerificationOneOf) {
      await widget.session.ouvrir(
        JetonsSession(
          acces: valeur.jetons.acces,
          rafraichissement: valeur.jetons.rafraichissement,
        ),
      );
      if (mounted) widget.onConnecte();
    } else if (valeur is ResultatVerificationOneOf1) {
      if (!mounted) return;
      setState(() {
        _jetonInscription = valeur.jetonInscription;
        _etape = _Etape.consentement;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MefaliCoreLocalizations.of(context)!;
    return switch (_etape) {
      _Etape.telephone => EcranTelephone(
          erreur: _erreur,
          enCours: _enCours,
          onValider: (telephone) => _demander(l10n, telephone),
        ),
      _Etape.otp => EcranOtp(
          erreur: _erreur,
          enCours: _enCours,
          onValider: (code) => _verifier(l10n, code),
          onRenvoyer: () => _demander(l10n, _telephone),
        ),
      _Etape.consentement => EcranConsentement(
          erreur: _erreur,
          enCours: _enCours,
          onAccepter: () => _inscrire(l10n),
        ),
    };
  }
}
