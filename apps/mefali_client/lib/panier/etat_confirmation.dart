/// État de l'écran **adresse et paiement** (CMD-02 + CMD-03, US2 et US3).
///
/// Moule **`Notifier`** de la constitution XII, comme le panier : ce n'est pas
/// un chargement, c'est un formulaire que la cliente remplit — pin, repère,
/// mode de paiement. Il n'a pas d'état « en cours de chargement », il a un
/// contenu, et ce contenu doit survivre à un aller-retour vers la carte.
library;

import 'package:flutter/foundation.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'etat_confirmation.g.dart';

/// Le repère est fourni en TEXTE ou en VOCAL — l'un des deux suffit (FR-018).
enum ModeRepere {
  /// Repère écrit.
  texte,

  /// Note vocale (≤ durée max de zone).
  vocal,
}

/// Ce que la cliente a saisi avant de confirmer.
///
/// Immuable et sans `operator ==`, comme [`EtatPanier`] : deux saisies
/// identiques restent deux valeurs distinctes, et une réémission ne doit jamais
/// être avalée.
@immutable
class EtatConfirmation {
  /// Crée un état de confirmation.
  const EtatConfirmation({
    this.lat,
    this.lon,
    this.adresseId,
    this.mode = ModeRepere.texte,
    this.repereTexte = '',
    this.noteVocale,
    this.modePaiement = 'cash',
    this.repereMinCaracteres = 10,
    this.commandesCreees = const [],
  });

  /// Pin GPS choisi (`null` tant que rien n'est posé).
  final double? lat;

  /// Pin GPS choisi.
  final double? lon;

  /// Adresse du carnet réutilisée en un tap (CPT-05), s'il y en a une.
  final String? adresseId;

  /// Onglet Texte / Vocal.
  final ModeRepere mode;

  /// Repère écrit saisi.
  final String repereTexte;

  /// Note vocale captée.
  final NoteVocaleCaptee? noteVocale;

  /// `cash` | `mobile_money`.
  final String modePaiement;

  /// Longueur minimale du repère écrit — **paramètre de zone**, servi par
  /// `/config` (`commande.repere_texte_min_caracteres`), jamais une constante
  /// d'app : la règle doit pouvoir changer sans passage store.
  final int repereMinCaracteres;

  /// Commandes créées, dans l'ordre de création (C3 → C4).
  ///
  /// Une LISTE, et non une commande : une scission acceptée en crée N, chacune
  /// avec son propre code de remise et son propre QR. N'en montrer qu'un ferait
  /// présenter le mauvais code à la seconde livraison.
  final List<CommandeCreeeVue> commandesCreees;

  /// La première commande créée, ou `null` — le chemin sans scission n'en a
  /// qu'une, et c'est celle-là que le suivi ouvre.
  CommandeCreeeVue? get commandeCreee =>
      commandesCreees.isEmpty ? null : commandesCreees.first;

  /// Le repère est FOURNI : texte assez long **ou** note vocale (FR-018).
  ///
  /// C'est la même règle que celle du serveur — dupliquée ici pour désactiver
  /// le bouton plutôt que d'envoyer une requête vouée au `422`. Le serveur
  /// reste seul juge : cette copie ne fait qu'éviter un aller-retour inutile.
  bool get repereFourni => switch (mode) {
        ModeRepere.texte => repereTexte.trim().length >= repereMinCaracteres,
        ModeRepere.vocal => noteVocale != null,
      };

  /// Tout est réuni pour confirmer.
  bool get pretAConfirmer => lat != null && lon != null && repereFourni;

  /// Copie avec un champ modifié.
  EtatConfirmation copie({
    double? lat,
    double? lon,
    String? adresseId,
    ModeRepere? mode,
    String? repereTexte,
    NoteVocaleCaptee? noteVocale,
    String? modePaiement,
    int? repereMinCaracteres,
    List<CommandeCreeeVue>? commandesCreees,
  }) =>
      EtatConfirmation(
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        adresseId: adresseId ?? this.adresseId,
        mode: mode ?? this.mode,
        repereTexte: repereTexte ?? this.repereTexte,
        noteVocale: noteVocale ?? this.noteVocale,
        modePaiement: modePaiement ?? this.modePaiement,
        repereMinCaracteres: repereMinCaracteres ?? this.repereMinCaracteres,
        commandesCreees: commandesCreees ?? this.commandesCreees,
      );
}

/// La commande créée, réduite à ce que l'écran de confirmation affiche.
@immutable
class CommandeCreeeVue {
  /// Crée la vue d'une commande créée.
  const CommandeCreeeVue({
    required this.id,
    required this.etat,
    required this.totalUnites,
    required this.devise,
    required this.codeLivraison,
    required this.jetonReception,
  });

  /// Identifiant (= la clé d'idempotence envoyée).
  final String id;

  /// État initial : `nouvelle` ou `en_attente_paiement`.
  final String etat;

  /// Total à régler.
  final int totalUnites;

  /// Devise ISO 4217.
  final String devise;

  /// Code de remise à 4 chiffres — remis DÈS la création (R6).
  final String codeLivraison;

  /// Jeton du QR de réception.
  final String jetonReception;

  /// La commande est née **en attente de paiement** : au-dessus du plafond
  /// cash, ou basculée par le dispatch (cycle PAY 011, FR-010).
  ///
  /// C'est ce drapeau qui décide de la suite du parcours : écran de paiement
  /// plutôt que suivi. Le lire sur la réponse de création évite un aller-retour
  /// de plus, et surtout évite à l'app de deviner à partir du mode de paiement
  /// — le plafond cash est une règle de zone, l'app ne la connaît pas.
  bool get attendPaiement => etat == 'en_attente_paiement';

  /// Construit la vue depuis le corps JSON de `POST /commandes`.
  factory CommandeCreeeVue.depuisJson(Map<String, Object?> json) {
    final remise = json['remise']! as Map<String, Object?>;
    return CommandeCreeeVue(
      id: json['id']! as String,
      etat: json['etat']! as String,
      totalUnites: json['total_unites']! as int,
      devise: json['devise']! as String,
      codeLivraison: remise['code_livraison']! as String,
      jetonReception: remise['jeton_reception']! as String,
    );
  }
}

/// Porteur de la saisie d'adresse et de paiement.
///
/// `keepAlive` explicite (constitution XII) : la saisie traverse l'aller-retour
/// vers la carte et le carnet d'adresses. Sans cela, choisir une adresse
/// enregistrée effacerait le mode de paiement déjà sélectionné.
@Riverpod(keepAlive: true)
class Confirmation extends _$Confirmation {
  @override
  EtatConfirmation build() => const EtatConfirmation();

  /// Pose le pin GPS (carte déplaçable, ou « ma position actuelle »).
  void poserPin(double lat, double lon) =>
      state = state.copie(lat: lat, lon: lon);

  /// Réutilise une adresse du carnet en un tap (CPT-05) : pin, repère écrit et
  /// note vocale d'un coup — c'est tout l'intérêt du carnet.
  void reutiliser({
    required String adresseId,
    required double lat,
    required double lon,
    String? repereTexte,
    NoteVocaleCaptee? noteVocale,
  }) {
    state = EtatConfirmation(
      lat: lat,
      lon: lon,
      adresseId: adresseId,
      // Un repère vocal PURGÉ (rétention de zone, cycle 003) laisse l'adresse
      // sans repère : on retombe alors sur la saisie écrite, et le bouton
      // reste désactivé tant que rien n'est fourni. L'app ne prétend pas
      // qu'un repère existe encore.
      mode: noteVocale != null ? ModeRepere.vocal : ModeRepere.texte,
      repereTexte: repereTexte ?? '',
      noteVocale: noteVocale,
      modePaiement: state.modePaiement,
      repereMinCaracteres: state.repereMinCaracteres,
    );
  }

  /// Bascule Texte / Vocal.
  void changerMode(ModeRepere mode) => state = state.copie(mode: mode);

  /// Saisit le repère écrit.
  void saisirRepere(String texte) => state = state.copie(repereTexte: texte);

  /// Enregistre la note vocale captée.
  void poserNoteVocale(NoteVocaleCaptee note) =>
      state = state.copie(noteVocale: note, mode: ModeRepere.vocal);

  /// Choisit le mode de paiement.
  void choisirPaiement(String mode) => state = state.copie(modePaiement: mode);

  /// Applique la longueur minimale du repère servie par la configuration de
  /// zone.
  void appliquerConfig({required int repereMinCaracteres}) =>
      state = state.copie(repereMinCaracteres: repereMinCaracteres);

  /// Une commande vient d'être créée : son code et son QR sont disponibles.
  ///
  /// AJOUTE au lieu de remplacer : une scission acceptée appelle cette méthode
  /// N fois, et l'écran de confirmation doit rendre les N codes — celui de la
  /// deuxième livraison n'est pas celui de la première.
  void poserCommande(CommandeCreeeVue commande) => state = state.copie(
        commandesCreees: [...state.commandesCreees, commande],
      );
}
