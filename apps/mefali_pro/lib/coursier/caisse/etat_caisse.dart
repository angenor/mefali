/// Porteur de la **caisse du coursier** (CRS-06, K5).
///
/// `AsyncNotifier` et non `Notifier` (constitution XII, R15) : c'est un
/// **chargement** — une lecture de `GET /moi/caisse` qui peut échouer et qu'on
/// rejoue — pas un processus qui dure comme la course ou les preuves.
///
/// **Durée de vie : `@riverpod` nu (autoDispose).** L'écran caisse n'a aucune
/// mémoire à garder entre deux visites : tout ce qu'il affiche vient du
/// serveur, et le cache local sert la relecture hors ligne. Un `keepAlive`
/// afficherait un solde périmé au retour sur l'écran, exactement là où la
/// fraîcheur compte.
///
/// **Hors ligne (FR-076)** : la dernière lecture réussie est rangée dans la
/// base locale et resservie telle quelle, avec son heure. Ne rien montrer
/// serait le pire choix — la caisse est justement l'écran que Yao ouvre dans
/// une cour, entre deux marchés, là où le réseau tombe.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'etat_caisse.g.dart';

/// Une course de l'historique du jour — **trois chiffres** (K5-1a).
class LigneCaisseVue {
  /// Crée la ligne.
  const LigneCaisseVue({
    required this.commandeId,
    required this.reference,
    required this.avanceUnites,
    required this.rembourseUnites,
    required this.gainUnites,
    required this.terminee,
    required this.enAttenteReglement,
    required this.heure,
  });

  /// Reconstruit une ligne depuis son JSON de cache.
  factory LigneCaisseVue.depuisJson(Map<String, dynamic> j) => LigneCaisseVue(
        commandeId: j['commande_id'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
        avanceUnites: j['avance_unites'] as int? ?? 0,
        rembourseUnites: j['rembourse_unites'] as int? ?? 0,
        gainUnites: j['gain_unites'] as int? ?? 0,
        terminee: j['terminee'] as bool? ?? false,
        enAttenteReglement: j['en_attente_reglement'] as bool? ?? false,
        heure: DateTime.parse(j['heure'] as String).toLocal(),
      );

  /// Commande concernée.
  final String commandeId;

  /// Référence lisible (`#418`) — de quoi se parler au téléphone.
  final String reference;

  /// Ce que Yao a sorti de sa poche (positif).
  final int avanceUnites;

  /// Ce qu'il a récupéré (positif).
  final int rembourseUnites;

  /// Sa part sur cette course (devis figé du cycle 007).
  final int gainUnites;

  /// La course est-elle terminée ?
  final bool terminee;

  /// Avance NON SOLDÉE parce que la commande était prépayée (R10, FR-117).
  final bool enAttenteReglement;

  /// Heure de la première écriture — **horodatage serveur** (FR-010).
  final DateTime heure;

  /// Sérialise pour le cache local.
  Map<String, dynamic> versJson() => {
        'commande_id': commandeId,
        'reference': reference,
        'avance_unites': avanceUnites,
        'rembourse_unites': rembourseUnites,
        'gain_unites': gainUnites,
        'terminee': terminee,
        'en_attente_reglement': enAttenteReglement,
        'heure': heure.toUtc().toIso8601String(),
      };
}

/// Un **mouvement du livre de caisse** (cycle PAY 011, T050).
///
/// L'historique agrégé par course ne peut pas les porter tous : un règlement
/// d'agence et un reversement ne sont rattachés à aucune commande — ils
/// portent sur un solde. Les y agréger les aurait fait disparaître de l'écran,
/// et un versement invisible est exactement ce que la caisse existe pour
/// empêcher.
class MouvementCaisseVue {
  /// Crée le mouvement.
  const MouvementCaisseVue({
    required this.id,
    required this.typeEcriture,
    required this.montantUnites,
    required this.entree,
    required this.heure,
    this.commandeId,
    this.reference,
  });

  /// Reconstruit un mouvement depuis son JSON.
  factory MouvementCaisseVue.depuisJson(Map<String, dynamic> j) =>
      MouvementCaisseVue(
        id: j['id'] as String? ?? '',
        typeEcriture: j['type_ecriture'] as String? ?? '',
        montantUnites: j['montant_unites'] as int? ?? 0,
        // Le SENS vient du serveur, dérivé du signe du montant. L'app ne tient
        // pas sa propre table de types : elle divergerait le jour où une nature
        // changerait de sens, et le coursier lirait « entrée » sur une sortie.
        entree: j['entree'] as bool? ?? false,
        commandeId: j['commande_id'] as String?,
        reference: j['reference'] as String?,
        heure: DateTime.parse(j['heure'] as String).toLocal(),
      );

  /// Écriture.
  final String id;

  /// Nature : `avance`, `remboursement`, `indemnisation`, `correction`,
  /// `frais_encaisses`, `reglement`, `reversement`.
  final String typeEcriture;

  /// Montant **signé** — négatif quand l'argent sort de la poche.
  final int montantUnites;

  /// Vrai si l'argent entre dans la poche du coursier.
  final bool entree;

  /// Commande concernée — `null` sur un règlement ou un reversement.
  final String? commandeId;

  /// Référence lisible de la commande, quand il y en a une.
  final String? reference;

  /// Horodatage **serveur**.
  final DateTime heure;

  /// Sérialise pour le cache local.
  Map<String, dynamic> versJson() => {
        'id': id,
        'type_ecriture': typeEcriture,
        'montant_unites': montantUnites,
        'entree': entree,
        'commande_id': commandeId,
        'reference': reference,
        'heure': heure.toUtc().toIso8601String(),
      };
}

/// Une indemnisation et son état (K5-1a, K5-1c).
class IndemnisationCaisseVue {
  /// Crée l'indemnisation.
  const IndemnisationCaisseVue({
    required this.id,
    required this.commandeReference,
    required this.montantUnites,
    required this.etat,
    required this.motifCle,
    this.litigeId,
  });

  /// Reconstruit depuis le JSON de cache.
  factory IndemnisationCaisseVue.depuisJson(Map<String, dynamic> j) =>
      IndemnisationCaisseVue(
        id: j['id'] as String? ?? '',
        commandeReference: j['commande_reference'] as String? ?? '',
        montantUnites: j['montant_unites'] as int? ?? 0,
        etat: j['etat'] as String? ?? 'demandee',
        motifCle: j['motif_cle'] as String? ?? '',
        litigeId: j['litige_id'] as String?,
      );

  /// Indemnisation.
  final String id;

  /// Référence lisible de la commande d'origine.
  final String commandeReference;

  /// Montant (unités mineures, positif).
  final int montantUnites;

  /// `demandee` | `validee` | `refusee`.
  final String etat;

  /// Clé i18n du motif — jamais un texte serveur en dur.
  final String motifCle;

  /// Litige rattaché, ou `null` (AVI-04 non construit).
  final String? litigeId;

  /// Sérialise pour le cache local.
  Map<String, dynamic> versJson() => {
        'id': id,
        'commande_reference': commandeReference,
        'montant_unites': montantUnites,
        'etat': etat,
        'motif_cle': motifCle,
        'litige_id': litigeId,
      };
}

/// Un litige en cours attaché au coursier (K5-1c, FR-074).
class LitigeCaisseVue {
  /// Crée le litige.
  const LitigeCaisseVue({
    required this.id,
    required this.reference,
    required this.etatCle,
    required this.montantUnites,
  });

  /// Reconstruit depuis le JSON de cache.
  factory LitigeCaisseVue.depuisJson(Map<String, dynamic> j) => LitigeCaisseVue(
        id: j['id'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
        etatCle: j['etat_cle'] as String? ?? '',
        montantUnites: j['montant_unites'] as int? ?? 0,
      );

  /// Litige.
  final String id;

  /// Référence lisible de la commande.
  final String reference;

  /// Clé i18n de l'état affiché.
  final String etatCle;

  /// Montant en jeu (unités mineures).
  final int montantUnites;

  /// Sérialise pour le cache local.
  Map<String, dynamic> versJson() => {
        'id': id,
        'reference': reference,
        'etat_cle': etatCle,
        'montant_unites': montantUnites,
      };
}

/// Tout l'écran caisse, en un objet (K5).
class EtatCaisseVue {
  /// Crée l'état.
  const EtatCaisseVue({
    this.avanceEnCoursUnites = 0,
    this.coursesConcernees = 0,
    this.avancesEnAttenteReglementUnites = 0,
    this.historique = const [],
    this.mouvements = const [],
    this.indemnisations = const [],
    this.litiges = const [],
    this.devise = '',
    this.ecartPlafond = false,
    this.horsLigne = false,
    this.luLe,
  });

  /// Reconstruit l'état depuis le JSON rangé en base locale.
  factory EtatCaisseVue.depuisJson(Map<String, dynamic> j) => EtatCaisseVue(
        avanceEnCoursUnites: j['avance_en_cours_unites'] as int? ?? 0,
        coursesConcernees: j['courses_concernees'] as int? ?? 0,
        avancesEnAttenteReglementUnites:
            j['avances_en_attente_reglement_unites'] as int? ?? 0,
        historique: [
          for (final l in (j['historique_du_jour'] as List? ?? const []))
            LigneCaisseVue.depuisJson(l as Map<String, dynamic>),
        ],
        mouvements: [
          for (final m in (j['mouvements'] as List? ?? const []))
            MouvementCaisseVue.depuisJson(m as Map<String, dynamic>),
        ],
        indemnisations: [
          for (final i in (j['indemnisations'] as List? ?? const []))
            IndemnisationCaisseVue.depuisJson(i as Map<String, dynamic>),
        ],
        litiges: [
          for (final l in (j['litiges_en_cours'] as List? ?? const []))
            LitigeCaisseVue.depuisJson(l as Map<String, dynamic>),
        ],
        devise: j['devise'] as String? ?? '',
        ecartPlafond: j['ecart_plafond'] as bool? ?? false,
      );

  /// Argent avancé et non encore récupéré (FR-067) — toujours positif.
  final int avanceEnCoursUnites;

  /// Combien de courses portent cette avance.
  final int coursesConcernees;

  /// Part que le cash ne soldera jamais (commandes prépayées, R10, FR-117).
  final int avancesEnAttenteReglementUnites;

  /// Historique du jour civil **de la zone**.
  final List<LigneCaisseVue> historique;

  /// Mouvements du livre du jour, du plus récent au plus ancien.
  final List<MouvementCaisseVue> mouvements;

  /// Indemnisations rattachées.
  final List<IndemnisationCaisseVue> indemnisations;

  /// Litiges en cours — vide tant qu'AVI-04 n'existe pas.
  final List<LitigeCaisseVue> litiges;

  /// Devise ISO 4217 de la zone. Vide quand aucune course n'a jamais eu lieu :
  /// une devise inventée serait pire qu'une absence (patron serveur).
  final String devise;

  /// Les avances dépassent le plafond du jour (FR-078) — l'agence est prévenue.
  final bool ecartPlafond;

  /// L'état servi vient du cache local, pas du serveur (FR-076).
  final bool horsLigne;

  /// Quand cette vue a été lue en ligne pour la dernière fois.
  final DateTime? luLe;

  /// Aucune course du jour, aucune avance : l'état vide de K5-1b (FR-077).
  ///
  /// Le solde reste affiché **à 0**, il ne disparaît pas : « jamais de carte
  /// manquante » (note de maquette 1b).
  /// `mouvements` en fait partie depuis le cycle PAY 011 : un règlement
  /// d'agence ou un reversement n'apparaît dans AUCUNE course, et une journée
  /// sans course mais avec un versement n'est pas une journée vide — la
  /// déclarer vide ferait disparaître de l'argent réel de l'écran.
  bool get vide =>
      historique.isEmpty &&
      mouvements.isEmpty &&
      indemnisations.isEmpty &&
      avanceEnCoursUnites == 0;

  /// Copie avec substitution.
  EtatCaisseVue copieAvec({bool? horsLigne, DateTime? luLe}) => EtatCaisseVue(
        avanceEnCoursUnites: avanceEnCoursUnites,
        coursesConcernees: coursesConcernees,
        avancesEnAttenteReglementUnites: avancesEnAttenteReglementUnites,
        historique: historique,
        mouvements: mouvements,
        indemnisations: indemnisations,
        litiges: litiges,
        devise: devise,
        ecartPlafond: ecartPlafond,
        horsLigne: horsLigne ?? this.horsLigne,
        luLe: luLe ?? this.luLe,
      );

  /// Sérialise pour le cache local — **le même format que le serveur**, pour
  /// que la relecture n'ait qu'un seul chemin de code.
  Map<String, dynamic> versJson() => {
        'avance_en_cours_unites': avanceEnCoursUnites,
        'courses_concernees': coursesConcernees,
        'avances_en_attente_reglement_unites': avancesEnAttenteReglementUnites,
        'historique_du_jour': [for (final l in historique) l.versJson()],
        'mouvements': [for (final m in mouvements) m.versJson()],
        'indemnisations': [for (final i in indemnisations) i.versJson()],
        'litiges_en_cours': [for (final l in litiges) l.versJson()],
        'devise': devise,
        'ecart_plafond': ecartPlafond,
      };
}

/// Chargement de la caisse (CRS-06, K5).
///
/// `retry: pasDeRetry` vient de la **portée** (`mefali_core`, constitution XII),
/// et c'est ce qu'il faut ici : un rejeu automatique masquerait la coupure que
/// l'écran doit justement annoncer, et relancerait la requête dans le dos de
/// Yao sur un forfait prépayé.
@riverpod
class EtatCaisse extends _$EtatCaisse {
  @override
  Future<EtatCaisseVue> build() async {
    // Session fermée ⇒ provider invalidé ⇒ caisse vide (patron `EtatCourseActive`).
    ref.watch(sessionProvider.select((e) => e.connecte));
    final file = ref.read(fileActionsProvider);

    try {
      final reponse =
          await ref.read(clientSessionProvider).getCoursierApi().maCaisse();
      final vue = _depuisContrat(reponse.data);
      await file.remplacerCaisse(jsonEncode(vue.versJson()));
      return vue;
    } on DioException catch (e) {
      if (e.response != null) rethrow;
      // Réseau muet : le dernier état connu, DATÉ (FR-076). Une caisse vide
      // ferait croire à Yao qu'il ne porte rien.
      final cache = await file.caisseCache();
      if (cache == null) {
        // Jamais lue en ligne : rien à servir, mais l'écran vide de K5-1b est
        // encore préférable à un écran de panne — le solde y vaut 0.
        return const EtatCaisseVue(horsLigne: true);
      }
      return EtatCaisseVue.depuisJson(
        jsonDecode(cache.vueJson) as Map<String, dynamic>,
      ).copieAvec(horsLigne: true, luLe: cache.luLeLocal);
    }
  }

  /// Relit la caisse — le geste « tirer pour rafraîchir » de K5.
  Future<void> rafraichir() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// Traduit le contrat généré en vue d'écran.
///
/// Passer par une classe à nous plutôt que d'afficher `VueCaisse` directement :
/// c'est ce qui rend l'état **sérialisable** pour le cache hors-ligne et
/// testable sans client HTTP.
EtatCaisseVue _depuisContrat(VueCaisse? v) {
  if (v == null) return const EtatCaisseVue();
  return EtatCaisseVue(
    avanceEnCoursUnites: v.avanceEnCoursUnites,
    coursesConcernees: v.coursesConcernees,
    avancesEnAttenteReglementUnites: v.avancesEnAttenteReglementUnites,
    historique: [
      for (final l in v.historiqueDuJour)
        LigneCaisseVue(
          commandeId: l.commandeId,
          reference: l.reference,
          avanceUnites: l.avanceUnites,
          rembourseUnites: l.rembourseUnites,
          gainUnites: l.gainUnites,
          terminee: l.terminee,
          enAttenteReglement: l.enAttenteReglement,
          heure: l.heure.toLocal(),
        ),
    ],
    mouvements: [
      for (final m in v.mouvements)
        MouvementCaisseVue(
          id: m.id,
          typeEcriture: m.typeEcriture,
          montantUnites: m.montantUnites,
          entree: m.entree,
          commandeId: m.commandeId,
          reference: m.reference,
          heure: m.heure.toLocal(),
        ),
    ],
    indemnisations: [
      for (final i in v.indemnisations)
        IndemnisationCaisseVue(
          id: i.id,
          commandeReference: i.commandeReference,
          montantUnites: i.montantUnites,
          etat: i.etat,
          motifCle: i.motifCle,
          litigeId: i.litigeId,
        ),
    ],
    litiges: [
      for (final l in v.litigesEnCours)
        LitigeCaisseVue(
          id: l.id,
          reference: l.reference,
          etatCle: l.etatCle,
          montantUnites: l.montantUnites,
        ),
    ],
    devise: v.devise,
    ecartPlafond: v.ecartPlafond,
  );
}
