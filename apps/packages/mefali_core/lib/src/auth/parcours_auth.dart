import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import '../../l10n/mefali_core_localizations.dart';
import '../config/service_config.dart';
import 'clients.dart';
import 'ecran_consentement.dart';
import 'ecran_otp.dart';
import 'ecran_telephone.dart';
import 'otp_dev.dart';
import 'session.dart';
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
class ParcoursAuth extends ConsumerStatefulWidget {
  /// Crée le parcours.
  const ParcoursAuth({
    super.key,
    required this.onConnecte,
    this.zone = zoneBootstrapTiassale,
    this.versionConsentement,
    this.nomAppareil = 'Appareil Mefali',
    this.plateforme = PlateformeDto.android,
    this.lireCodeDev,
  });

  /// Appelé une fois la session ouverte (l'app route vers son accueil).
  final VoidCallback onConnecte;

  /// Zone déclarée à l'inscription (research R13).
  final String zone;

  /// Version du texte ARTCI que l'app a AFFICHÉ, servie par la config de zone
  /// (`consentement.artci_version` → vue dérivée de `/config`).
  ///
  /// `null` tant que la config n'est pas chargée : l'inscription est alors
  /// refusée plutôt que d'horodater un consentement sur une version inventée
  /// (FR-006 : « conservé avec la version du texte accepté »). C'est cette
  /// valeur qui permet de faire évoluer le texte par configuration, sans
  /// release — un défaut en dur ici la rendrait inerte (FR-024).
  final String? versionConsentement;

  /// Nom d'appareil affiché dans la liste des sessions.
  final String nomAppareil;

  /// Plateforme déclarée.
  final PlateformeDto plateforme;

  /// Lecteur du code tracé, en mode DEV seulement — doublé par les tests.
  ///
  /// `null` = le lecteur réseau du client généré (voir [lireCodeDevReseau]).
  /// N'est consulté que si [modeDevOtp], donc jamais en build normal.
  final LireCodeDev? lireCodeDev;

  @override
  ConsumerState<ParcoursAuth> createState() => _ParcoursAuthState();
}

class _ParcoursAuthState extends ConsumerState<ParcoursAuth> {
  _Etape _etape = _Etape.telephone;
  String _telephone = '';
  String? _jetonInscription;
  String? _erreur;
  bool _enCours = false;

  /// Code relu sur la surface dev, en mode DEV seulement — toujours `null` en
  /// build normal ([modeDevOtp] est `const false`).
  String? _codeDev;

  AuthApi get _api => ref.read(clientSessionProvider).getAuthApi();

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
          // Un renvoi périme le code précédent : ne pas laisser afficher
          // l'ancien pendant que le nouveau se relit.
          _codeDev = null;
        });
        await _relireCodeDev(telephone);
      });

  /// Relit le code que le backend vient de tracer — mode DEV uniquement.
  ///
  /// Sort immédiatement en build normal : [modeDevOtp] est une constante à
  /// `false`, donc tout ce qui suit est du code mort que le compilateur retire.
  ///
  /// Un échec est silencieux et laisse `_codeDev` à `null` : la demande d'OTP,
  /// elle, a réussi — l'écran de saisie doit s'afficher quoi qu'il arrive. Le
  /// cas le plus courant est le plafond (202 neutre SANS SMS, donc rien de
  /// tracé à relire).
  Future<void> _relireCodeDev(String telephone) async {
    if (!modeDevOtp) return;
    final lire =
        widget.lireCodeDev ?? lireCodeDevReseau(ref.read(clientSessionProvider).dio);
    final code = await lire(telephone: telephone, zone: widget.zone);
    if (mounted) setState(() => _codeDev = code);
  }

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
        final version = widget.versionConsentement;
        // Sans la version affichée, on ne PEUT pas horodater honnêtement le
        // consentement (FR-006) : on le dit au lieu d'en inventer une.
        if (version == null) {
          setState(() => _erreur = l10n.authErreurReseau);
          return;
        }
        final reponse = await _api.inscrire(
          inscription: Inscription(
            (b) => b
              ..jetonInscription = _jetonInscription!
              ..consentementVersion = version,
          ),
        );
        // Le consentement vient d'être fourni : l'inscription n'a qu'une issue,
        // et le contrat la type comme telle — rien à discriminer ici.
        final ouverte = reponse.data;
        if (ouverte != null) await _ouvrirSession(ouverte);
      });

  /// Deux issues possibles, discriminées par le `oneOf` du contrat.
  Future<void> _traiterResultat(ResultatVerification? resultat) async {
    final valeur = resultat?.oneOf.value;
    if (valeur is SessionOuverte) {
      await _ouvrirSession(valeur);
    } else if (valeur is ConsentementRequis) {
      if (!mounted) return;
      setState(() {
        _jetonInscription = valeur.jetonInscription;
        _etape = _Etape.consentement;
      });
    }
  }

  Future<void> _ouvrirSession(SessionOuverte ouverte) async {
    await ref.read(sessionProvider.notifier).ouvrir(
          JetonsSession(
            acces: ouverte.jetons.acces,
            rafraichissement: ouverte.jetons.rafraichissement,
          ),
        );
    if (mounted) widget.onConnecte();
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
          codeDev: _codeDev,
        ),
      _Etape.consentement => EcranConsentement(
          erreur: _erreur,
          enCours: _enCours,
          onAccepter: () => _inscrire(l10n),
        ),
    };
  }
}
