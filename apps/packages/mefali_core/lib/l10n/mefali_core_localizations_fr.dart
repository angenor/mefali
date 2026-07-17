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
  String get authOtpDevTitre =>
      'Mode développement — code tracé par le serveur';

  @override
  String get authOtpDevUtiliser => 'Renseigner';

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
  String get actionReessayer => 'Réessayer';

  @override
  String get parametresAppareils => 'Appareils connectés';

  @override
  String get parametresAdresses => 'Mes adresses';

  @override
  String get adressesTitre => 'Mes adresses';

  @override
  String get adressesVide =>
      'Aucune adresse enregistrée. Mefali vous proposera d\'en garder une après votre prochaine livraison.';

  @override
  String get adressesErreur =>
      'Impossible de charger vos adresses. Vérifiez votre réseau.';

  @override
  String get adressesRenommer => 'Renommer';

  @override
  String get adressesSupprimer => 'Supprimer';

  @override
  String adressesSupprimerTitre(String libelle) {
    return 'Supprimer « $libelle » ?';
  }

  @override
  String get adressesSupprimerAide =>
      'Vos livraisons passées n\'en sont pas affectées.';

  @override
  String get adressesAnnuler => 'Annuler';

  @override
  String get adressesValider => 'Valider';

  @override
  String get adresseProposerTitre => 'Garder cette adresse ?';

  @override
  String get adresseProposerAide =>
      'Votre prochaine commande ici tiendra en un geste.';

  @override
  String get adresseProposerAction => 'Garder cette adresse';

  @override
  String get adresseProposerRefuser => 'Pas maintenant';

  @override
  String get adresseLibelleMaison => 'Maison';

  @override
  String get adresseLibelleBureau => 'Bureau';

  @override
  String get adresseLibelleLibre => 'Nom de l\'adresse';

  @override
  String get adresseRepereTexte => 'Repère';

  @override
  String get adresseRepereExemple => 'Derrière la pharmacie, portail bleu';

  @override
  String get adresseRepereEnregistrer => 'Enregistrer un repère vocal';

  @override
  String adresseRepereRefaire(int secondes) {
    return 'Repère vocal de $secondes s — refaire';
  }

  @override
  String adresseRepereArreter(int secondes) {
    return 'Arrêter ($secondes s)';
  }

  @override
  String adresseRepereMax(int secondes) {
    return '$secondes s au maximum';
  }

  @override
  String get adresseRepereEcouter => 'Écouter le repère';

  @override
  String adresseRepereDuree(int secondes) {
    return '$secondes s';
  }

  @override
  String get adresseRepereErreur => 'Lecture impossible';

  @override
  String get adresseRepereAbsent =>
      'Aucun repère vocal — Mefali vous en redemandera un à la prochaine commande.';
}
