import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'mefali_core_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of MefaliCoreLocalizations
/// returned by `MefaliCoreLocalizations.of(context)`.
///
/// Applications need to include `MefaliCoreLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/mefali_core_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: MefaliCoreLocalizations.localizationsDelegates,
///   supportedLocales: MefaliCoreLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the MefaliCoreLocalizations.supportedLocales
/// property.
abstract class MefaliCoreLocalizations {
  MefaliCoreLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static MefaliCoreLocalizations? of(BuildContext context) {
    return Localizations.of<MefaliCoreLocalizations>(
      context,
      MefaliCoreLocalizations,
    );
  }

  static const LocalizationsDelegate<MefaliCoreLocalizations> delegate =
      _MefaliCoreLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// Titre de l'écran de saisie du numéro de téléphone
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro'**
  String get authTelephoneTitre;

  /// Explication sous le titre de l'écran téléphone
  ///
  /// In fr, this message translates to:
  /// **'Nous vous envoyons un code par SMS pour vérifier ce numéro.'**
  String get authTelephoneAide;

  /// Libellé du champ de saisie du numéro
  ///
  /// In fr, this message translates to:
  /// **'Numéro de mobile'**
  String get authTelephoneChamp;

  /// Exemple de saisie locale, sans indicatif
  ///
  /// In fr, this message translates to:
  /// **'Ex. 07 01 02 03 04'**
  String get authTelephoneExemple;

  /// Bouton principal de l'écran téléphone
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code'**
  String get authTelephoneAction;

  /// Erreur affichée quand le champ numéro est vide
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre numéro de mobile.'**
  String get authTelephoneVide;

  /// Titre de l'écran de saisie du code OTP
  ///
  /// In fr, this message translates to:
  /// **'Code de vérification'**
  String get authOtpTitre;

  /// Explication sous le titre de l'écran OTP
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code à 6 chiffres reçu par SMS.'**
  String get authOtpAide;

  /// Bouton principal de l'écran OTP
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get authOtpAction;

  /// Bouton de renvoi d'un nouveau code, actif après le compte à rebours
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get authOtpRenvoyer;

  /// Compte à rebours avant de pouvoir redemander un code
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans {secondes} s'**
  String authOtpRenvoyerDans(int secondes);

  /// En-tête du bandeau DEV de l'écran OTP. Jamais vu par un utilisateur : ce bandeau n'existe que dans un build --dart-define=MEFALI_DEV_OTP=true, où le serveur journalise le code au lieu de l'envoyer par SMS.
  ///
  /// In fr, this message translates to:
  /// **'Mode développement — code tracé par le serveur'**
  String get authOtpDevTitre;

  /// Bouton du bandeau DEV qui recopie le code tracé dans les six cases de saisie
  ///
  /// In fr, this message translates to:
  /// **'Renseigner'**
  String get authOtpDevUtiliser;

  /// Titre de l'écran de consentement ARTCI
  ///
  /// In fr, this message translates to:
  /// **'Protection de vos données'**
  String get authConsentementTitre;

  /// Texte du consentement ARTCI présenté à l'inscription
  ///
  /// In fr, this message translates to:
  /// **'Mefali enregistre votre numéro de mobile pour créer votre compte et vous permettre de commander. Aucune autre donnée personnelle n\'est demandée. Vos données sont traitées conformément à la réglementation ivoirienne sur la protection des données personnelles (ARTCI).'**
  String get authConsentementTexte;

  /// Libellé de la case à cocher — JAMAIS pré-cochée (FR-006)
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte le traitement de mes données personnelles.'**
  String get authConsentementCase;

  /// Bouton principal de l'écran de consentement
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get authConsentementAction;

  /// Erreur de format du numéro (422 telephone_invalide)
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro n\'est pas valide. Vérifiez-le et réessayez.'**
  String get authErreurTelephoneInvalide;

  /// Erreur NEUTRE de vérification — ne révèle jamais si le numéro a un compte (SC-003)
  ///
  /// In fr, this message translates to:
  /// **'Code invalide ou expiré. Demandez un nouveau code.'**
  String get authErreurCodeInvalide;

  /// Erreur réseau générique
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau et réessayez.'**
  String get authErreurReseau;

  /// Titre de l'accueil provisoire posé par le cycle CPT
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes connecté'**
  String get accueilProvisoireTitre;

  /// Action de déconnexion depuis l'accueil provisoire
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get accueilProvisoireDeconnexion;

  /// Titre de l'écran des sessions/appareils
  ///
  /// In fr, this message translates to:
  /// **'Appareils connectés'**
  String get appareilsTitre;

  /// Puce marquant la session de l'appareil qui consulte
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil'**
  String get appareilsCourant;

  /// Action de déconnexion à distance
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter cet appareil'**
  String get appareilsDeconnecter;

  /// État vide de la liste des appareils
  ///
  /// In fr, this message translates to:
  /// **'Aucun autre appareil connecté.'**
  String get appareilsVide;

  /// Erreur de chargement de la liste des appareils
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos appareils. Vérifiez votre réseau.'**
  String get appareilsErreur;

  /// Action commune des états d'erreur réseau (règle d'or 5 : erreur réseau = réessayer)
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get actionReessayer;

  /// Entrée de menu vers l'écran des appareils
  ///
  /// In fr, this message translates to:
  /// **'Appareils connectés'**
  String get parametresAppareils;

  /// Entrée de menu vers l'écran des adresses enregistrées
  ///
  /// In fr, this message translates to:
  /// **'Mes adresses'**
  String get parametresAdresses;

  /// Titre de l'écran des adresses enregistrées (CPT-05)
  ///
  /// In fr, this message translates to:
  /// **'Mes adresses'**
  String get adressesTitre;

  /// État vide de la liste des adresses
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse enregistrée. Mefali vous proposera d\'en garder une après votre prochaine livraison.'**
  String get adressesVide;

  /// Erreur de chargement de la liste des adresses
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos adresses. Vérifiez votre réseau.'**
  String get adressesErreur;

  /// Action : renommer une adresse enregistrée (FR-021)
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get adressesRenommer;

  /// Action : supprimer une adresse enregistrée (FR-021)
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get adressesSupprimer;

  /// Titre de la confirmation de suppression d'une adresse
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {libelle} » ?'**
  String adressesSupprimerTitre(String libelle);

  /// Aide de la confirmation de suppression (FR-021 : ne vaut que pour l'avenir)
  ///
  /// In fr, this message translates to:
  /// **'Vos livraisons passées n\'en sont pas affectées.'**
  String get adressesSupprimerAide;

  /// Action : abandonner la boîte de dialogue
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get adressesAnnuler;

  /// Action : confirmer la boîte de dialogue
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get adressesValider;

  /// Titre de la proposition d'enregistrement après une livraison (FR-019)
  ///
  /// In fr, this message translates to:
  /// **'Garder cette adresse ?'**
  String get adresseProposerTitre;

  /// Aide de la proposition d'enregistrement d'adresse
  ///
  /// In fr, this message translates to:
  /// **'Votre prochaine commande ici tiendra en un geste.'**
  String get adresseProposerAide;

  /// Action principale : accepter la proposition d'enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Garder cette adresse'**
  String get adresseProposerAction;

  /// Action : refuser la proposition — l'enregistrement n'est jamais obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Pas maintenant'**
  String get adresseProposerRefuser;

  /// Libellé d'adresse proposé
  ///
  /// In fr, this message translates to:
  /// **'Maison'**
  String get adresseLibelleMaison;

  /// Libellé d'adresse proposé
  ///
  /// In fr, this message translates to:
  /// **'Bureau'**
  String get adresseLibelleBureau;

  /// Champ : libellé libre de l'adresse
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'adresse'**
  String get adresseLibelleLibre;

  /// Champ : repère écrit de l'adresse
  ///
  /// In fr, this message translates to:
  /// **'Repère'**
  String get adresseRepereTexte;

  /// Exemple de repère écrit (cadrage §8.2)
  ///
  /// In fr, this message translates to:
  /// **'Derrière la pharmacie, portail bleu'**
  String get adresseRepereExemple;

  /// Action : capter une note vocale de repère
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un repère vocal'**
  String get adresseRepereEnregistrer;

  /// Action : remplacer la note vocale déjà captée
  ///
  /// In fr, this message translates to:
  /// **'Repère vocal de {secondes} s — refaire'**
  String adresseRepereRefaire(int secondes);

  /// Action : arrêter l'enregistrement en cours, avec son compteur
  ///
  /// In fr, this message translates to:
  /// **'Arrêter ({secondes} s)'**
  String adresseRepereArreter(int secondes);

  /// Borne de durée servie par la configuration de zone (FR-019)
  ///
  /// In fr, this message translates to:
  /// **'{secondes} s au maximum'**
  String adresseRepereMax(int secondes);

  /// Action : jouer la note vocale de repère (planche de style, bouton audio)
  ///
  /// In fr, this message translates to:
  /// **'Écouter le repère'**
  String get adresseRepereEcouter;

  /// Durée de la note vocale, à côté du bouton d'écoute
  ///
  /// In fr, this message translates to:
  /// **'{secondes} s'**
  String adresseRepereDuree(int secondes);

  /// Erreur de lecture de la note vocale
  ///
  /// In fr, this message translates to:
  /// **'Lecture impossible'**
  String get adresseRepereErreur;

  /// Adresse dont le repère vocal a été purgé après 12 mois sans usage (FR-022)
  ///
  /// In fr, this message translates to:
  /// **'Aucun repère vocal — Mefali vous en redemandera un à la prochaine commande.'**
  String get adresseRepereAbsent;

  /// Entrée de l'accueil provisoire vers l'atelier DEV — visible seulement en build --dart-define=MEFALI_DEV_ADRESSE
  ///
  /// In fr, this message translates to:
  /// **'Repère vocal (atelier DEV)'**
  String get atelierRepereEntree;

  /// Titre de l'écran de l'atelier DEV du repère vocal
  ///
  /// In fr, this message translates to:
  /// **'Atelier repère vocal'**
  String get atelierRepereTitre;

  /// Bandeau explicatif de l'atelier DEV
  ///
  /// In fr, this message translates to:
  /// **'Surface de DÉVELOPPEMENT, absente des builds de production. Ouvre la feuille d\'enregistrement sur un pin GPS bouchon (Tiassalé) pour éprouver, sur appareil, la permission micro, l\'enregistrement, la réécoute et l\'envoi réel.'**
  String get atelierRepereAide;

  /// Action : présenter FeuilleEnregistrerAdresse sur le pin bouchon
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la feuille d\'enregistrement'**
  String get atelierRepereOuvrir;

  /// Titre de la carte récapitulant ce que la feuille a rendu
  ///
  /// In fr, this message translates to:
  /// **'Repère capté'**
  String get atelierRepereCaptee;

  /// Taille de la note vocale captée, avant envoi
  ///
  /// In fr, this message translates to:
  /// **'{octets} octets captés'**
  String atelierRepereOctets(int octets);

  /// La capture n'a pas de note vocale (l'utilisateur n'en a pas enregistré)
  ///
  /// In fr, this message translates to:
  /// **'Aucune note vocale dans cette capture — repère écrit seul.'**
  String get atelierRepereSansNote;

  /// Action : téléverser la capture vers le serveur pour de vrai
  ///
  /// In fr, this message translates to:
  /// **'Envoyer (POST /moi/adresses)'**
  String get atelierRepereEnvoyer;

  /// Libellé du bouton d'envoi pendant l'appel réseau
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours…'**
  String get atelierRepereEnvoi;

  /// Confirmation de l'enregistrement, avec l'id rendu par le serveur
  ///
  /// In fr, this message translates to:
  /// **'Adresse enregistrée : {id}'**
  String atelierRepereEnvoyee(String id);

  /// Diagnostic DEV d'un envoi échoué (code HTTP et message)
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi : {details}'**
  String atelierRepereErreur(String details);

  /// Action : nettoyer l'adresse créée par l'atelier (DELETE)
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'adresse de test'**
  String get atelierRepereSupprimer;

  /// Titre de l'écran panier (C3-3a)
  ///
  /// In fr, this message translates to:
  /// **'Mon panier'**
  String get panierTitre;

  /// En-tête de la carte d'un vendeur du panier
  ///
  /// In fr, this message translates to:
  /// **'Chez {vendeur}'**
  String panierChezVendeur(String vendeur);

  /// Libellé du sous-total d'un vendeur
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get panierSousTotal;

  /// Ligne « Articles » du récapitulatif
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get panierRecapArticles;

  /// Ligne « Livraison » du récapitulatif
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get panierRecapLivraison;

  /// Ligne d'effort du récapitulatif (TRF-06)
  ///
  /// In fr, this message translates to:
  /// **'Effort de préparation'**
  String get panierRecapEffort;

  /// Total à payer du récapitulatif
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get panierRecapTotal;

  /// Total affiché HORS LIGNE — les frais réels viennent du serveur (C3-3c)
  ///
  /// In fr, this message translates to:
  /// **'Total estimé'**
  String get panierTotalEstime;

  /// Bandeau du panier composé sans réseau (C3-3c)
  ///
  /// In fr, this message translates to:
  /// **'Hors connexion — panier conservé'**
  String get panierHorsLigne;

  /// Explication du brouillon hors ligne
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est gardé sur cet appareil. Il sera envoyé une seule fois au retour du réseau.'**
  String get panierHorsLigneAide;

  /// Titre du sélecteur de préférence de substitution
  ///
  /// In fr, this message translates to:
  /// **'Si l\'article manque'**
  String get panierPreferenceTitre;

  /// Préférence par défaut (CMD-01)
  ///
  /// In fr, this message translates to:
  /// **'M\'appeler'**
  String get panierPreferenceAppeler;

  /// Préférence : accepter un remplacement proposé
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get panierPreferenceRemplacer;

  /// Préférence : retirer l'article sans appeler
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get panierPreferenceRetirer;

  /// État vide du panier
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide.'**
  String get panierVide;

  /// Action principale du panier
  ///
  /// In fr, this message translates to:
  /// **'Commander'**
  String get panierCommander;

  /// Cause « catégorie non mixable » d'une proposition de scission (FR-009)
  ///
  /// In fr, this message translates to:
  /// **'Les plats préparés se commandent séparément des courses.'**
  String get panierScissionCategorieNonMixable;

  /// Cause « plafond d'éclatement » d'une proposition de scission
  ///
  /// In fr, this message translates to:
  /// **'Vos vendeurs sont très éloignés les uns des autres.'**
  String get panierScissionPlafondEclatement;

  /// Bouton de la proposition de scission (C3-3d). Le nombre vient du SERVEUR : une catégorie non mixable à trois vendeurs propose trois commandes, pas deux
  ///
  /// In fr, this message translates to:
  /// **'Scinder en {n} commandes'**
  String panierScissionAction(int n);

  /// Avertissement chiffré de la scission — jamais scindée d'office (FR-010). Le cas à deux garde la lettre de la maquette C3-3d
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =2{Deux commandes, deux frais de déplacement.} other{{n} commandes, {n} frais de déplacement.}}'**
  String panierScissionAvertissement(int n);

  /// Titre du bloc de scission ACCEPTÉE, avant confirmation
  ///
  /// In fr, this message translates to:
  /// **'{n} commandes séparées'**
  String panierScissionAcceptee(int n);

  /// Numéro d'une des commandes d'une scission, dans la prévisualisation et sur les codes de remise
  ///
  /// In fr, this message translates to:
  /// **'Commande {n}'**
  String panierScissionCommandeNumero(int n);

  /// Annule une scission acceptée — refuser doit rester aussi simple qu'accepter (FR-010)
  ///
  /// In fr, this message translates to:
  /// **'Revenir à une seule commande'**
  String get panierScissionAnnuler;

  /// Échec partiel d'une scission : ce qui a bien été créé
  ///
  /// In fr, this message translates to:
  /// **'{creees, plural, =1{1 commande sur {total} a été créée.} other{{creees} commandes sur {total} ont été créées.}}'**
  String commandeScissionCreees(int creees, int total);

  /// Échec partiel d'une scission : ce qui n'a PAS été créé. Ce qui l'est reste dû
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{La commande restante n\'a pas pu être créée.} other{{n} commandes n\'ont pas pu être créées.}}'**
  String commandeScissionReste(int n);

  /// Relance les seules commandes non créées, avec leurs clés d'idempotence inchangées (R7)
  ///
  /// In fr, this message translates to:
  /// **'Reprendre le reste'**
  String get commandeScissionReprendre;

  /// Ouvre le carnet d'adresses depuis le bloc adresse (CPT-05)
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get commandeAdresseChanger;

  /// Titre du bloc adresse de commande
  ///
  /// In fr, this message translates to:
  /// **'Où livrer ?'**
  String get commandeAdresseTitre;

  /// Action de centrage sur le GPS
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position actuelle'**
  String get commandeAdressePositionActuelle;

  /// Onglet du repère texte
  ///
  /// In fr, this message translates to:
  /// **'Repère écrit'**
  String get commandeAdresseRepereTexte;

  /// Onglet du repère vocal
  ///
  /// In fr, this message translates to:
  /// **'Repère vocal'**
  String get commandeAdresseRepereVocal;

  /// Explication de l'obligation de repère (FR-018)
  ///
  /// In fr, this message translates to:
  /// **'Un repère aide le coursier à vous trouver : écrivez-le ou dites-le.'**
  String get commandeAdresseRepereAide;

  /// Titre du bloc paiement
  ///
  /// In fr, this message translates to:
  /// **'Comment payer ?'**
  String get commandePaiementTitre;

  /// Option de paiement en espèces
  ///
  /// In fr, this message translates to:
  /// **'Espèces à la livraison'**
  String get commandePaiementCash;

  /// Option de paiement mobile
  ///
  /// In fr, this message translates to:
  /// **'Mobile money'**
  String get commandePaiementMobileMoney;

  /// Mention d'appoint exact du paiement cash (C3-3b)
  ///
  /// In fr, this message translates to:
  /// **'Préparez l\'appoint : {montant}'**
  String commandePaiementAppoint(String montant);

  /// Raison affichée quand le cash est grisé (C3-3b, FR-024)
  ///
  /// In fr, this message translates to:
  /// **'Espèces indisponibles au-dessus de {plafond}.'**
  String commandePaiementCashIndisponible(String plafond);

  /// Titre de l'écran de confirmation. Une scission acceptée en crée N : le singulier mentirait sur ce que l'écran montre (constaté sur appareil)
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Commande confirmée} other{{n} commandes confirmées}}'**
  String commandeConfirmee(int n);

  /// Libellé du code à 4 chiffres remis au client
  ///
  /// In fr, this message translates to:
  /// **'Code de remise'**
  String get commandeCodeRemise;

  /// Libellé du QR de réception
  ///
  /// In fr, this message translates to:
  /// **'QR de réception'**
  String get commandeQrRemise;

  /// Refus 403 compte_bloque (FR-026)
  ///
  /// In fr, this message translates to:
  /// **'Votre compte ne peut pas passer commande. Contactez le support.'**
  String get commandeErreurCompteBloque;

  /// Refus 409 categorie_non_mixable (FR-009)
  ///
  /// In fr, this message translates to:
  /// **'Les plats préparés se commandent séparément des courses.'**
  String get commandeErreurCategorieNonMixable;

  /// Refus 422 repere_manquant (FR-018)
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un repère écrit ou vocal pour que le coursier vous trouve.'**
  String get commandeErreurRepereManquant;

  /// Refus 403 telephone_non_verifie (FR-019)
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre numéro avant de commander.'**
  String get commandeErreurTelephoneNonVerifie;

  /// Refus 409 vendeur_indisponible (FR-029)
  ///
  /// In fr, this message translates to:
  /// **'Ce vendeur vient de fermer. Retirez ses articles ou réessayez plus tard.'**
  String get commandeErreurVendeurIndisponible;

  /// Refus 409 article_indisponible (FR-029)
  ///
  /// In fr, this message translates to:
  /// **'Un article n\'est plus disponible. Mettez votre panier à jour.'**
  String get commandeErreurArticleIndisponible;

  /// Refus 409 cash_indisponible (FR-024/025)
  ///
  /// In fr, this message translates to:
  /// **'Le paiement en espèces n\'est pas possible pour cette commande.'**
  String get commandeErreurCashIndisponible;

  /// Refus 409 transition_refusee
  ///
  /// In fr, this message translates to:
  /// **'Cette action n\'est plus possible à cette étape.'**
  String get commandeErreurTransitionRefusee;

  /// Refus 403 non_proprietaire (FR-041)
  ///
  /// In fr, this message translates to:
  /// **'Cette commande n\'est pas la vôtre.'**
  String get commandeErreurNonProprietaire;

  /// Refus 404 commande_inconnue
  ///
  /// In fr, this message translates to:
  /// **'Commande introuvable.'**
  String get commandeErreurCommandeInconnue;

  /// Refus 422 panier_invalide
  ///
  /// In fr, this message translates to:
  /// **'Votre panier n\'est pas valide.'**
  String get commandeErreurPanierInvalide;

  /// Refus 422 motif_requis (FR-054, admin)
  ///
  /// In fr, this message translates to:
  /// **'Un motif est obligatoire.'**
  String get commandeErreurMotifRequis;

  /// Refus 423 code_epuise (CRS-04)
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Un conseiller va vous contacter.'**
  String get commandeErreurCodeEpuise;

  /// Refus 409 remise_incorrecte
  ///
  /// In fr, this message translates to:
  /// **'Code ou QR incorrect.'**
  String get commandeErreurRemiseIncorrecte;

  /// Refus 409 preuves_incompletes (FR-056)
  ///
  /// In fr, this message translates to:
  /// **'Les preuves de l\'incident sont incomplètes.'**
  String get commandeErreurPreuvesIncompletes;

  /// Erreur technique NEUTRE — aucun détail exposé
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez dans un instant.'**
  String get commandeErreurInterne;

  /// Titre de l'écran de suivi
  ///
  /// In fr, this message translates to:
  /// **'Suivi de commande'**
  String get suiviTitre;

  /// 1ᵉʳ pas du stepper (C4-4a)
  ///
  /// In fr, this message translates to:
  /// **'Commande reçue'**
  String get suiviEtatRecue;

  /// État d'attente de coursier (C4-4b, CMD-10)
  ///
  /// In fr, this message translates to:
  /// **'Recherche d\'un coursier'**
  String get suiviEtatRechercheCoursier;

  /// 2ᵉ pas du stepper — la remise n'est jamais comptée (P1)
  ///
  /// In fr, this message translates to:
  /// **'Collecte en cours {faites}/{total}'**
  String suiviEtatCollecteEnCours(int faites, int total);

  /// 3ᵉ pas du stepper
  ///
  /// In fr, this message translates to:
  /// **'En route vers vous'**
  String get suiviEtatEnRoute;

  /// 4ᵉ pas du stepper
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get suiviEtatLivree;

  /// État terminal — commande annulée
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get suiviEtatAnnulee;

  /// État terminal — échec déclaré (§7.5)
  ///
  /// In fr, this message translates to:
  /// **'Incident en cours de traitement'**
  String get suiviEtatEchouee;

  /// Arrêt courant du suivi
  ///
  /// In fr, this message translates to:
  /// **'Chez {vendeur}'**
  String suiviChezVendeur(String vendeur);

  /// Bouton d'appel du suivi
  ///
  /// In fr, this message translates to:
  /// **'Appeler le coursier'**
  String get suiviAppelerCoursier;

  /// Âge de la dernière position — l'app n'en invente jamais une (FR-040)
  ///
  /// In fr, this message translates to:
  /// **'Position il y a {secondes} s'**
  String suiviPositionAge(int secondes);

  /// Aucune position connue — jamais une position inventée (R13)
  ///
  /// In fr, this message translates to:
  /// **'Position non disponible'**
  String get suiviPositionInconnue;

  /// Titre du bloc code + QR de remise
  ///
  /// In fr, this message translates to:
  /// **'À la livraison'**
  String get suiviALaLivraison;

  /// Titre du bloc de remise en mode hors ligne (C4-4d)
  ///
  /// In fr, this message translates to:
  /// **'À la livraison — disponible sans réseau'**
  String get suiviALaLivraisonHorsLigne;

  /// Bandeau hors ligne du suivi (C4-4d)
  ///
  /// In fr, this message translates to:
  /// **'Hors connexion'**
  String get suiviHorsLigne;

  /// Mention explicite que l'état affiché peut avoir changé (C4-4d)
  ///
  /// In fr, this message translates to:
  /// **'Dernier état connu'**
  String get suiviDernierEtatConnu;

  /// Annulation avant toute collecte (C4-4b, CMD-07)
  ///
  /// In fr, this message translates to:
  /// **'Annuler sans frais'**
  String get suiviAnnulerSansFrais;

  /// Message d'escalade de la file d'attente (FR-038)
  ///
  /// In fr, this message translates to:
  /// **'L\'attente est plus longue que d\'habitude.'**
  String get suiviAttenteAllongee;

  /// Titre de la feuille de substitution (C4-4c)
  ///
  /// In fr, this message translates to:
  /// **'Article manquant'**
  String get substitutionTitre;

  /// Écart de prix de la proposition
  ///
  /// In fr, this message translates to:
  /// **'{propose} à {prixPropose} au lieu de {prixInitial}'**
  String substitutionProposition(
    String propose,
    String prixPropose,
    String prixInitial,
  );

  /// Compte à rebours de la fenêtre de décision (FR-045)
  ///
  /// In fr, this message translates to:
  /// **'{secondes} s pour répondre'**
  String substitutionCompteARebours(int secondes);

  /// Phrase d'issue par défaut affichée sous la proposition (C4-4c)
  ///
  /// In fr, this message translates to:
  /// **'Sans réponse, on vous appelle. Injoignable : article retiré, rien à payer.'**
  String get substitutionIssueParDefaut;

  /// Bouton d'acceptation du remplacement
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get substitutionAccepter;

  /// Bouton de refus du remplacement
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get substitutionRefuser;

  /// Refus 409 substitution_autre_vendeur (FR-048)
  ///
  /// In fr, this message translates to:
  /// **'Un remplacement doit venir du même vendeur.'**
  String get substitutionErreurAutreVendeur;

  /// Refus 409 substitution_ecart_prix (FR-047)
  ///
  /// In fr, this message translates to:
  /// **'L\'écart de prix est trop important.'**
  String get substitutionErreurEcartPrix;

  /// Refus 409 substitution_expiree (R10)
  ///
  /// In fr, this message translates to:
  /// **'Le délai de réponse est passé.'**
  String get substitutionErreurExpiree;

  /// Confirmation d'un retrait : seul le montant des articles bouge (FR-050)
  ///
  /// In fr, this message translates to:
  /// **'Article retiré — rien à payer pour lui.'**
  String get substitutionRetireeNonFacturee;
}

class _MefaliCoreLocalizationsDelegate
    extends LocalizationsDelegate<MefaliCoreLocalizations> {
  const _MefaliCoreLocalizationsDelegate();

  @override
  Future<MefaliCoreLocalizations> load(Locale locale) {
    return SynchronousFuture<MefaliCoreLocalizations>(
      lookupMefaliCoreLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_MefaliCoreLocalizationsDelegate old) => false;
}

MefaliCoreLocalizations lookupMefaliCoreLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return MefaliCoreLocalizationsFr();
  }

  throw FlutterError(
    'MefaliCoreLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
