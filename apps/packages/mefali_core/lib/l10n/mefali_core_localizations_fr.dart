// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'mefali_core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class MefaliCoreLocalizationsFr extends MefaliCoreLocalizations {
  MefaliCoreLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get authTelephoneTitre => 'Votre numéro';

  @override
  String get authTelephoneAide =>
      'Nous vous envoyons un code par SMS pour vérifier ce numéro.';

  @override
  String get authTelephoneChamp => 'Numéro de mobile';

  @override
  String get authTelephoneExemple => 'Ex. 07 01 02 03 04';

  @override
  String get authTelephoneAction => 'Recevoir le code';

  @override
  String get authTelephoneVide => 'Saisissez votre numéro de mobile.';

  @override
  String get authOtpTitre => 'Code de vérification';

  @override
  String get authOtpAide => 'Saisissez le code à 6 chiffres reçu par SMS.';

  @override
  String get authOtpAction => 'Valider';

  @override
  String get authOtpRenvoyer => 'Renvoyer le code';

  @override
  String authOtpRenvoyerDans(int secondes) {
    return 'Renvoyer le code dans $secondes s';
  }

  @override
  String get authConsentementTitre => 'Protection de vos données';

  @override
  String get authConsentementTexte =>
      'Mefali enregistre votre numéro de mobile pour créer votre compte et vous permettre de commander. Aucune autre donnée personnelle n\'est demandée. Vos données sont traitées conformément à la réglementation ivoirienne sur la protection des données personnelles (ARTCI).';

  @override
  String get authConsentementCase =>
      'J\'accepte le traitement de mes données personnelles.';

  @override
  String get authConsentementAction => 'Créer mon compte';

  @override
  String get authErreurTelephoneInvalide =>
      'Ce numéro n\'est pas valide. Vérifiez-le et réessayez.';

  @override
  String get authErreurCodeInvalide =>
      'Code invalide ou expiré. Demandez un nouveau code.';

  @override
  String get authErreurReseau =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.';

  @override
  String get accueilProvisoireTitre => 'Vous êtes connecté';

  @override
  String get accueilProvisoireDeconnexion => 'Se déconnecter';

  @override
  String get appareilsTitre => 'Appareils connectés';

  @override
  String get appareilsCourant => 'Cet appareil';

  @override
  String get appareilsDeconnecter => 'Déconnecter cet appareil';

  @override
  String get appareilsVide => 'Aucun autre appareil connecté.';

  @override
  String get appareilsErreur =>
      'Impossible de charger vos appareils. Vérifiez votre réseau.';

  @override
  String get parametresAppareils => 'Appareils connectés';
}
