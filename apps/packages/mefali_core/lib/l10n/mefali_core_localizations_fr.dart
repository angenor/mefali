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

  @override
  String get atelierRepereEntree => 'Repère vocal (atelier DEV)';

  @override
  String get atelierRepereTitre => 'Atelier repère vocal';

  @override
  String get atelierRepereAide =>
      'Surface de DÉVELOPPEMENT, absente des builds de production. Ouvre la feuille d\'enregistrement sur un pin GPS bouchon (Tiassalé) pour éprouver, sur appareil, la permission micro, l\'enregistrement, la réécoute et l\'envoi réel.';

  @override
  String get atelierRepereOuvrir => 'Ouvrir la feuille d\'enregistrement';

  @override
  String get atelierRepereCaptee => 'Repère capté';

  @override
  String atelierRepereOctets(int octets) {
    return '$octets octets captés';
  }

  @override
  String get atelierRepereSansNote =>
      'Aucune note vocale dans cette capture — repère écrit seul.';

  @override
  String get atelierRepereEnvoyer => 'Envoyer (POST /moi/adresses)';

  @override
  String get atelierRepereEnvoi => 'Envoi en cours…';

  @override
  String atelierRepereEnvoyee(String id) {
    return 'Adresse enregistrée : $id';
  }

  @override
  String atelierRepereErreur(String details) {
    return 'Échec de l\'envoi : $details';
  }

  @override
  String get atelierRepereSupprimer => 'Supprimer l\'adresse de test';

  @override
  String get panierTitre => 'Mon panier';

  @override
  String panierChezVendeur(String vendeur) {
    return 'Chez $vendeur';
  }

  @override
  String get panierSousTotal => 'Sous-total';

  @override
  String get panierRecapArticles => 'Articles';

  @override
  String get panierRecapLivraison => 'Livraison';

  @override
  String get panierRecapEffort => 'Effort de préparation';

  @override
  String get panierRecapTotal => 'Total';

  @override
  String get panierTotalEstime => 'Total estimé';

  @override
  String get panierHorsLigne => 'Hors connexion — panier conservé';

  @override
  String get panierHorsLigneAide =>
      'Votre panier est gardé sur cet appareil. Il sera envoyé une seule fois au retour du réseau.';

  @override
  String get panierPreferenceTitre => 'Si l\'article manque';

  @override
  String get panierPreferenceAppeler => 'M\'appeler';

  @override
  String get panierPreferenceRemplacer => 'Remplacer';

  @override
  String get panierPreferenceRetirer => 'Retirer';

  @override
  String get panierVide => 'Votre panier est vide.';

  @override
  String get panierCommander => 'Commander';

  @override
  String get panierScissionCategorieNonMixable =>
      'Les plats préparés se commandent séparément des courses.';

  @override
  String get panierScissionPlafondEclatement =>
      'Vos vendeurs sont très éloignés les uns des autres.';

  @override
  String get panierScissionAction => 'Scinder en 2 commandes';

  @override
  String get panierScissionAvertissement =>
      'Deux commandes, deux frais de déplacement.';

  @override
  String get commandeAdresseTitre => 'Où livrer ?';

  @override
  String get commandeAdressePositionActuelle => 'Utiliser ma position actuelle';

  @override
  String get commandeAdresseRepereTexte => 'Repère écrit';

  @override
  String get commandeAdresseRepereVocal => 'Repère vocal';

  @override
  String get commandeAdresseRepereAide =>
      'Un repère aide le coursier à vous trouver : écrivez-le ou dites-le.';

  @override
  String get commandePaiementTitre => 'Comment payer ?';

  @override
  String get commandePaiementCash => 'Espèces à la livraison';

  @override
  String get commandePaiementMobileMoney => 'Mobile money';

  @override
  String commandePaiementAppoint(String montant) {
    return 'Préparez l\'appoint : $montant';
  }

  @override
  String commandePaiementCashIndisponible(String plafond) {
    return 'Espèces indisponibles au-dessus de $plafond.';
  }

  @override
  String get commandeConfirmee => 'Commande confirmée';

  @override
  String get commandeCodeRemise => 'Code de remise';

  @override
  String get commandeQrRemise => 'QR de réception';

  @override
  String get commandeErreurCompteBloque =>
      'Votre compte ne peut pas passer commande. Contactez le support.';

  @override
  String get commandeErreurCategorieNonMixable =>
      'Les plats préparés se commandent séparément des courses.';

  @override
  String get commandeErreurRepereManquant =>
      'Ajoutez un repère écrit ou vocal pour que le coursier vous trouve.';

  @override
  String get commandeErreurTelephoneNonVerifie =>
      'Vérifiez votre numéro avant de commander.';

  @override
  String get commandeErreurVendeurIndisponible =>
      'Ce vendeur vient de fermer. Retirez ses articles ou réessayez plus tard.';

  @override
  String get commandeErreurArticleIndisponible =>
      'Un article n\'est plus disponible. Mettez votre panier à jour.';

  @override
  String get commandeErreurCashIndisponible =>
      'Le paiement en espèces n\'est pas possible pour cette commande.';

  @override
  String get commandeErreurTransitionRefusee =>
      'Cette action n\'est plus possible à cette étape.';

  @override
  String get commandeErreurNonProprietaire =>
      'Cette commande n\'est pas la vôtre.';

  @override
  String get commandeErreurCommandeInconnue => 'Commande introuvable.';

  @override
  String get commandeErreurPanierInvalide => 'Votre panier n\'est pas valide.';

  @override
  String get commandeErreurMotifRequis => 'Un motif est obligatoire.';

  @override
  String get commandeErreurCodeEpuise =>
      'Trop d\'essais. Un conseiller va vous contacter.';

  @override
  String get commandeErreurRemiseIncorrecte => 'Code ou QR incorrect.';

  @override
  String get commandeErreurPreuvesIncompletes =>
      'Les preuves de l\'incident sont incomplètes.';

  @override
  String get commandeErreurInterne =>
      'Une erreur est survenue. Réessayez dans un instant.';

  @override
  String get suiviTitre => 'Suivi de commande';

  @override
  String get suiviEtatRecue => 'Commande reçue';

  @override
  String get suiviEtatRechercheCoursier => 'Recherche d\'un coursier';

  @override
  String suiviEtatCollecteEnCours(int faites, int total) {
    return 'Collecte en cours $faites/$total';
  }

  @override
  String get suiviEtatEnRoute => 'En route vers vous';

  @override
  String get suiviEtatLivree => 'Livrée';

  @override
  String get suiviEtatAnnulee => 'Annulée';

  @override
  String get suiviEtatEchouee => 'Incident en cours de traitement';

  @override
  String suiviChezVendeur(String vendeur) {
    return 'Chez $vendeur';
  }

  @override
  String get suiviAppelerCoursier => 'Appeler le coursier';

  @override
  String suiviPositionAge(int secondes) {
    return 'Position il y a $secondes s';
  }

  @override
  String get suiviPositionInconnue => 'Position non disponible';

  @override
  String get suiviALaLivraison => 'À la livraison';

  @override
  String get suiviALaLivraisonHorsLigne =>
      'À la livraison — disponible sans réseau';

  @override
  String get suiviHorsLigne => 'Hors connexion';

  @override
  String get suiviDernierEtatConnu => 'Dernier état connu';

  @override
  String get suiviAnnulerSansFrais => 'Annuler sans frais';

  @override
  String get suiviAttenteAllongee =>
      'L\'attente est plus longue que d\'habitude.';

  @override
  String get substitutionTitre => 'Article manquant';

  @override
  String substitutionProposition(
    String propose,
    String prixPropose,
    String prixInitial,
  ) {
    return '$propose à $prixPropose au lieu de $prixInitial';
  }

  @override
  String substitutionCompteARebours(int secondes) {
    return '$secondes s pour répondre';
  }

  @override
  String get substitutionIssueParDefaut =>
      'Sans réponse, on vous appelle. Injoignable : article retiré, rien à payer.';

  @override
  String get substitutionAccepter => 'Accepter';

  @override
  String get substitutionRefuser => 'Refuser';

  @override
  String get substitutionErreurAutreVendeur =>
      'Un remplacement doit venir du même vendeur.';

  @override
  String get substitutionErreurEcartPrix =>
      'L\'écart de prix est trop important.';

  @override
  String get substitutionErreurExpiree => 'Le délai de réponse est passé.';

  @override
  String get substitutionRetireeNonFacturee =>
      'Article retiré — rien à payer pour lui.';
}
