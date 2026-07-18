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
