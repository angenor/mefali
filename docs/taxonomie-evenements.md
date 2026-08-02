# Taxonomie des événements Mefali

Registre des événements métier du journal outbox (TRX-02, constitution VI).
Le journal est la **matière première des métriques** — aucun KPI manuel :
tout indicateur dérive d'événements enregistrés ici.

Ce document résout le TODO de la constitution (principe VI). Le cycle socle
n'émet aucun événement produit ; le registre se remplit avec les parcours
utilisateur des cycles suivants.

## Convention de nommage

`<entite>.<action>` — entité au singulier, action au participe passé.

Exemples (à créer par leurs cycles, **non émis ce cycle**) :
`commande.creee`, `commande.terminee`, `livraison.affectee`,
`coursier.disponibilite_changee`, `paiement.encaisse`, `avis.depose`.

## Propriétés standard du `payload` (cadrage §10.9)

Chaque événement porte, quand elles existent, les propriétés transverses qui
permettent de segmenter les métriques sans retraitement :

| Propriété | Description |
|---|---|
| `zone` | Zone concernée (héritage de configuration — cycle ZON) |
| `categorie` | Catégorie de service / vertical (ex. `resto_courses`) |
| `role` | Rôle de l'acteur à l'origine de la transition (client, coursier, vendeur, admin) |
| `version_app` | Version de l'app émettrice (client / pro) |

Les propriétés spécifiques à l'événement s'ajoutent à côté de ces clés standard.

## Format d'enregistrement

Colonnes de `outbox.evenement` (data-model.md §1) : `type_evenement`,
`entite_type`, `entite_id`, `payload` (jsonb), `survenu_le`. L'`id` est un
UUIDv7 (ordre temporel) ; l'idempotence des consommateurs se fait par cet `id`.

## Registre

| Type d'événement | Entité | Émis par | Statut |
|---|---|---|---|
| `socle.ping` | `socle` | tests d'intégration outbox | **Technique** — hors taxonomie produit, sert à valider le cycle de vie de l'outbox |
| `zone.parametre_modifie` | `zone` | `PgZones::definir_parametre` (cycle ZON) | **Produit** — modification d'un paramètre de zone |
| `categorie.forcage_change` | `activation_categorie` | `PgZones::forcer_categorie` (cycle ZON) | **Produit** — changement du mode de forçage admin |
| `categorie.activation_changee` | `activation_categorie` | `PgZones::forcer_categorie` / `recalculer_activation` (cycle ZON) | **Produit** — bascule de l'état EFFECTIF d'activation |
| `compte.cree` | `compte` | `PgComptes::creer_compte` (cycle CPT) | **Produit** — inscription d'un numéro vérifié + consentement |
| `session.creee` | `session` | `PgComptes::creer_session` (cycle CPT) | **Produit** — ouverture d'une session d'appareil |
| `session.revoquee` | `session` | `PgComptes::revoquer_session` / `tourner_refresh` (cycle CPT) | **Produit** — fin de session (locale, à distance, réutilisation détectée) |
| `role.demande` | `attribution_role` | `PgComptes::soumettre_dossier_coursier` (cycle CPT) | **Produit** — demande de rôle coursier (in-app) |
| `role.attribue` | `attribution_role` | `PgComptes::attribuer_role` (cycle CPT) | **Produit** — attribution directe par un admin (vendeur à l'agrément, admin) |
| `role.valide` | `attribution_role` | `PgComptes::decider_role` (cycle CPT) | **Produit** — demande acceptée par un admin |
| `role.refuse` | `attribution_role` | `PgComptes::decider_role` (cycle CPT) | **Produit** — demande refusée (motif requis) |
| `role.suspendu` | `attribution_role` | `PgComptes::decider_role` (cycle CPT) | **Produit** — rôle suspendu (motif requis) |
| `role.retabli` | `attribution_role` | `PgComptes::decider_role` (cycle CPT) | **Produit** — rôle rétabli après suspension |
| `dossier_coursier.soumis` | `dossier_coursier` | `PgComptes::soumettre_dossier_coursier` (cycle CPT) | **Produit** — dépôt du dossier (première fois ou re-soumission) |
| `dossier_coursier.vehicules_modifies` | `dossier_coursier` | `PgComptes::remplacer_vehicules_declares` (cycle CPT) | **Produit** — la flotte d'un dossier DÉJÀ validé change, SANS revue admin |
| `adresse.enregistree` | `adresse` | `PgComptes::enregistrer_adresse` (cycle CPT) | **Produit** — adresse enregistrée après livraison |
| `adresse.modifiee` | `adresse` | `PgComptes::modifier_adresse` (cycle CPT) | **Produit** — renommage ou nouveau repère |
| `adresse.supprimee` | `adresse` | `PgComptes::supprimer_adresse` (cycle CPT) | **Produit** — suppression (soft delete) |
| `adresse.repere_vocal_purge` | `adresse` | `PgComptes::purger_reperes_vocaux` (cycle CPT) | **Produit** — repère vocal purgé après la rétention de zone |
| `prestataire.cree` | `prestataire` | `PgPrestataires::creer_prestataire` (cycle VND) | **Produit** — création de la fiche (état prospect) |
| `prestataire.modifie` | `prestataire` | `PgPrestataires::modifier_prestataire` (cycle VND) | **Produit** — modification de la fiche (noms de champs seulement) |
| `prestataire.agree` | `prestataire` | `PgPrestataires::agreer` (cycle VND) | **Produit** — agrément (plaque créée au premier passage) |
| `prestataire.suspendu` | `prestataire` | `PgPrestataires::suspendre` (cycle VND) | **Produit** — suspension (motif requis) ; coupe fiche, commandabilité, plaque |
| `prestataire.retabli` | `prestataire` | `PgPrestataires::retablir` (cycle VND) | **Produit** — rétablissement (plaque inchangée) |
| `prestataire.corrige` | `prestataire` | `PgPrestataires::corriger` (cycle VND) | **Produit** — correction catégorie/ville (double recalcul d'activation) |
| `charte.deposee` | `charte_signee` | `PgPrestataires::deposer_charte` (cycle VND) | **Produit** — dépôt du scan de charte signée (version + date) |
| `rattachement.cree` | `rattachement` | `PgPrestataires::rattacher_compte` (cycle VND) | **Produit** — rattachement compte ↔ prestataire (rôle vendeur si absent) |
| `rattachement.supprime` | `rattachement` | `PgPrestataires::detacher_compte` (cycle VND) | **Produit** — détachement (le rôle du compte ne bouge pas) |
| `site.statut_boutique_change` | `site` | `PgPrestataires::changer_statut_boutique` (cycle VND) | **Produit** — changement DÉCIDÉ de statut de boutique (jamais les échéances) |
| `site.horaires_modifies` | `site` | `PgPrestataires::modifier_horaires` (cycle VND) | **Produit** — remplacement des horaires hebdomadaires |
| `article.cree` | `article` | `PgPrestataires::creer_article` (cycle VND) | **Produit** — article ajouté au catalogue (disponible par défaut) |
| `article.modifie` | `article` | `PgPrestataires::modifier_article` (cycle VND) | **Produit** — modification (prix, prix barré, nom, photo, catégorie interne) |
| `article.retire_du_catalogue` | `article` | `PgPrestataires::retirer_article` (cycle VND) | **Produit** — retrait RÉVERSIBLE (la ligne subsiste) |
| `article.remis_au_catalogue` | `article` | `PgPrestataires::remettre_article` (cycle VND) | **Produit** — remise au catalogue sans ressaisie |
| `article.mis_en_rupture` | `article` | `PgPrestataires::basculer_disponibilite` / masquage automatique (cycle VND) | **Produit** — bascule en rupture, trois sources ; consommé par VND-09 |
| `article.remis_en_vente` | `article` | `PgPrestataires::basculer_disponibilite` (cycle VND) | **Produit** — retour en stock ; consommé par VND-09 (T4) |
| `signalement_rupture.recu` | `signalement_rupture` | `PgPrestataires::signaler_rupture` (cycle VND) | **Produit** — signalement coursier ACCEPTÉ (les refus n'émettent rien) |
| `plaque.generee` | `plaque` | `PgQr::plaque_pdf` (cycle QRC) | **Produit** — génération (ou régénération) du PDF de plaque imprimable |
| `arret.collecte` | `arret` | `PgCommandes::marquer_arret_collecte` (cycle QRC) | **Produit** — arrêt basculé COLLECTÉ (scan ou code de secours), horodatage serveur |
| `livraison.mise_en_livraison` | `livraison` | `PgCommandes::marquer_arret_collecte` (cycle QRC) | **Produit** — tous les arrêts résolus → la livraison passe EN_LIVRAISON |
| `plaque.remplacement_requis` | `plaque` | `PgQr::collecter` (cycle QRC) | **Produit** — incident « plaque à remplacer » créé au 1er passage en mode dégradé |
| `arret.collecte_rejetee` | `arret` | `PgQr::collecter` (cycle QRC) | **Produit** — refus métier d'une collecte (hors-ligne réconciliée) ; jamais au rejeu idempotent |
| `grille.publiee` | `grille` | `PgTarification::publier` (cycle TRF) | **Produit** — publication d'une grille tarifaire (version + effet) |
| `routage.degrade` | `devis` | `tarification::routage` (cycle TRF) | **Produit** — repli vol d'oiseau × facteur de zone (constitution IV) |
| `effort.calcule` | `devis` | `tarification::effort` (cycle TRF) | **Produit** — effort calculé mais NON facturé (promo) |
| `commande.creee` | `commande` | `commandes::creation` (cycle CMD) | **Produit** — commande née avec ses prix verrouillés et son devis figé |
| `commande.paiement_requis` | `commande` | `commandes::creation` (cycle CMD) | **Produit** — prépaiement imposé (plafond, restriction, restauration sans historique) |
| `commande.prete_a_dispatcher` | `commande` | `commandes::creation` (cycle CMD) | **Produit** — contrat SANS consommateur ce cycle (branché par DSP) |
| `commande.paiement_confirme` | `commande` | `PgCommandes::confirmer_prepaiement` (cycle CMD) | **Produit** — prépaiement confirmé (PAY simulé) ; le tronc repasse NOUVELLE |
| `commande.mise_en_attente_coursier` | `commande` | `PgCommandes::mettre_en_attente_coursier` (cycle CMD) | **Produit** — aucun coursier éligible ; file FIFO par âge |
| `commande.attente_coursier_escaladee` | `commande` | `PgCommandes::escalader_attentes` (cycle CMD) | **Produit** — seuil d'attente franchi (FR-038) |
| `commande.assignee` | `commande` | `PgCommandes::affecter` (cycle CMD) | **Produit** — livraison assignée, le tronc passe EN_COURS |
| `commande.terminee` | `commande` | `commandes::collecte::remise` (cycle CMD) | **Produit** — remise validée, commande close |
| `commande.annulee` | `commande` | `commandes::annulation` (cycle CMD) | **Produit** — annulation client ou admin (sans frais ou règles d'échec) |
| `commande.echec_declare` | `commande` | `commandes::echec` (cycle CMD) | **Produit** — échec déclaré avec preuves réunies |
| `panier.scission_proposee` | `commande` (virtuel) | `commandes::panier` (cycle CMD) | **Produit** — proposition de scission (métrique SC-006) ; le devis lui-même n'écrit rien |
| `livraison.creee` | `livraison` | `commandes::creation` (cycle CMD) | **Produit** — composant de livraison avec son devis figé |
| `livraison.affectee` | `livraison` | `PgCommandes::affecter` (cycle CMD) | **Produit** — coursier affecté à la livraison |
| `livraison.mise_en_collecte` | `livraison` | `commandes::collecte` (cycle CMD) | **Produit** — premier arrêt passé EN ROUTE → la livraison passe EN_COLLECTE |
| `livraison.livree` | `livraison` | `commandes::collecte::remise` (cycle CMD) | **Produit** — remise validée (QR, code ou dépôt) |
| `arret.en_route` | `arret` | `commandes::collecte` (cycle CMD) | **Produit** — le coursier part vers l'arrêt |
| `arret.arrive` | `arret` | `commandes::collecte` (cycle CMD) | **Produit** — arrivée sur l'arrêt (base de la prime d'attente TRF-06) |
| `arret.indisponible` | `arret` | `commandes::collecte` (cycle CMD) | **Produit** — arrêt entièrement indisponible ; compté RÉSOLU au gating |
| `substitution.proposee` | `substitution` | `commandes::substitution` (cycle CMD) | **Produit** — remplacement proposé par le coursier (échéance persistée) |
| `substitution.decidee` | `substitution` | `commandes::substitution` (cycle CMD) | **Produit** — acceptée, refusée, expirée ou retirée |
| `ligne.retiree` | `ligne_commande` | `commandes::substitution` (cycle CMD) | **Produit** — ligne retirée, montant des articles révisé (frais inchangés) |
| `appel.intention` | `commande` | `commandes_http::appeler` / `commandes::substitution` (cycle CMD) | **Produit** — intention d'appel journalisée (aucun numéro dans le payload) |
| `remise.code_epuise` | `commande` | `commandes::collecte::valider_remise` (cycle CMD) | **Produit** — essais du code de remise épuisés : la commande est bloquée à la porte du client et **exige un humain** (l'app dit « un conseiller va vous contacter »). Un `tracing::warn!` ne s'abonne pas — l'exploitation doit le recevoir comme les autres. |
| `echec.issue_enregistree` | `issue_echec` | `commandes::echec` (cycle CMD) | **Produit** — issue de l'arbre §7.5 avec ses deux détenteurs |
| `litige.ouvert` | `issue_echec` | `commandes::echec` (cycle CMD) | **Produit** — contrat SANS consommateur ce cycle (branché par AVI-04) |
| `indemnisation.due` | `issue_echec` | `commandes::echec` (cycle CMD) | **Produit** — contrat SANS consommateur ce cycle (branché par CRS-06) |
| `sanction.posee` | `compte` | `comptes::restriction::poser_restriction` (cycle CMD) | **Produit** — restriction posée sur un compte client (CPT-06) |
| `coursier.disponibilite_changee` | `coursier` | `dispatch::pool` (cycle DSP) | **Produit** — entrée ou sortie du pool (manuelle, ou constatée après expiration) |
| `coursier.plafond_jour_declare` | `coursier` | `dispatch::plafond` (cycle DSP) | **Produit** — plafond d'avance déclaré pour le jour civil de la zone |
| `dispatch.evaluation_faite` | `commande` | `dispatch::pipeline` (cycle DSP) | **Opérations** — agrégat d'un passage de pipeline (le détail va aux logs structurés) |
| `dispatch.offre_emise` | `offre` | `dispatch::offre` (cycle DSP) | **Opérations** — offre émise sous double verrou (cascade ou broadcast) |
| `dispatch.offre_acceptee` | `offre` | `dispatch::offre` (cycle DSP) | **Opérations** — offre acceptée ; l'affectation passe par `CommandesADispatcher::affecter` |
| `dispatch.offre_refusee` | `offre` | `dispatch::offre` (cycle DSP) | **Opérations** — refus explicite ; le candidat suivant est sollicité immédiatement |
| `dispatch.offre_non_repondue` | `offre` | `dispatch::tic` (cycle DSP) | **Opérations** — échéance atteinte ; `franche` les 3 premières fois du jour |
| `dispatch.offre_deja_prise` | `offre` | `dispatch::offre` (cycle DSP) | **Opérations** — seconde acceptation refusée, **sans pénalité** (FR-049) |
| `dispatch.broadcast_ouvert` | `commande` | `dispatch::pipeline` (cycle DSP) | **Opérations** — bascule en broadcast (candidats épuisés ou délai) |
| `dispatch.bascule_prepaiement` | `commande` | `dispatch::pipeline` (cycle DSP) | **Opérations** — la capacité d'avance était le SEUL obstacle (FR-026) |
| `dispatch.reassignation` | `livraison` | `dispatch::reprise` (cycle DSP) | **Opérations** — coursier retiré ; le devis figé n'est JAMAIS recalculé |
| `dispatch.course_bloquee_escaladee` | `livraison` | `dispatch::reprise` (cycle DSP) | **Opérations** — un arrêt est collecté : aucune reprise automatique, l'exploitation tranche |
| `preuves_echec.reunies` | `livraison` | `coursier::preuves` (cycle CRS) | **Produit** — les trois preuves d'un client absent sont réunies ; l'échec devient déclarable |
| `caisse.mouvement` | `ecriture_caisse` | `coursier::caisse` (cycle CRS) | **Produit** — une écriture est portée au livre de caisse du coursier (append-only) |
| `indemnisation.validee` | `indemnisation` | `coursier::indemnisation` (cycle CRS) | **Produit** — indemnisation validée par l'exploitation ; l'écriture de caisse suit dans la même transaction |
| `indemnisation.refusee` | `indemnisation` | `coursier::indemnisation` (cycle CRS) | **Produit** — indemnisation refusée (motif requis) ; aucune écriture de caisse |
| `remise.code_debloque` | `commande` | `commandes::collecte` (cycle CRS) | **Produit** — l'exploitation lève le blocage du code de remise (motif requis) |
| `depot.autorise` | `commande` | `commandes::depot` (cycle CRS) | **Produit** — la voie « dépôt » est ouverte (ou refermée) sur une commande, avec sa trace |
| `coursier.action_reconciliee` | `livraison` | `coursier::course` (cycle CRS) | **Opérations** — une action rejouée depuis la file a été rejouée ou refusée définitivement |

### Événements du cycle ZON (002 — zones & configuration héritée)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que la mutation
(constitution VI, research R9). `entite_id` = identifiant de la ligne mutée.
Le journal « qui/quand/avant/après » exigé par ADM-05 est porté par ces
événements — pas de table d'audit parallèle. Les seeds (chargement initial)
n'émettent aucun événement.

| Type | `entite_type` | Payload spécifique (en plus des propriétés standard) |
|---|---|---|
| `zone.parametre_modifie` | `zone` | `zone` (id), `cle`, `avant` (`null` si création), `apres`, `acteur` |
| `categorie.forcage_change` | `activation_categorie` | `zone` (id), `categorie` (slug), `avant`, `apres` (modes de forçage), `acteur` |
| `categorie.activation_changee` | `activation_categorie` | `zone` (id), `categorie` (slug), `avant`, `apres` (état effectif booléen), `origine` (`seuil` \| `forcage`), `nb_vendeurs` (si `origine=seuil`), `seuil` |

`categorie.forcage_change` est émis à CHAQUE forçage ; `categorie.activation_changee`
seulement quand l'état effectif (`actif`) bascule — les deux dans la même
transaction que l'UPDATE. Les métriques d'activation dériveront de ces
événements (aucun KPI manuel).

### Événements du cycle CPT (003 — comptes, authentification OTP et rôles)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que la transition
(constitution VI, research R10). Le registre est posé AVANT l'implémentation.

**Identification des entités.** `attribution_role` a une clé primaire composite
`(compte_id, role)` et donc aucun `id` de substitution : ses événements portent
`entite_id` = `compte_id`, le rôle concerné vivant dans le payload. Idem pour
`dossier_coursier`, dont la clé primaire EST `compte_id` (1:1 avec le compte).

**Minimisation (ARTCI).** Les payloads ne portent AUCUNE donnée nominative ni
position GPS : ni numéro de téléphone, ni libellé d'adresse, ni `lat`/`lng`.
Les repères sont décrits par des booléens de présence. Le journal des décisions
admin exigé par FR-014 (qui / quand / motif) est porté par `decide_par` +
`motif` + `survenu_le`, doublé par les colonnes de `attribution_role` — aucune
table d'audit parallèle (patron du cycle 002).

| Type | `entite_type` | `entite_id` | Payload spécifique (en plus des propriétés standard) |
|---|---|---|---|
| `compte.cree` | `compte` | `compte.id` | `zone`, `role` (`client` — l'attribution automatique de l'inscription y est INCLUSE, data-model §4), `consentement_version`, `consentement_le` |
| `session.creee` | `session` | `session.id` | `zone`, `compte`, `appareil_plateforme` (`android` \| `ios`), `origine` (`verification_otp` \| `inscription`) |
| `session.revoquee` | `session` | `session.id` | `zone`, `compte`, `origine` (`locale` \| `a_distance` \| `reutilisation_detectee`), `revoquee_par` (compte de l'appareil demandeur ; `null` si détection automatique) |
| `role.demande` | `attribution_role` | `compte_id` | `zone`, `compte`, `role` (`coursier`), `avant` (`null` \| `refuse`), `apres` (`en_attente`) |
| `role.attribue` | `attribution_role` | `compte_id` | `zone`, `compte`, `role` (`vendeur` \| `admin`), `avant` (`null`), `apres` (`valide`), `decide_par`, `motif` |
| `role.valide` | `attribution_role` | `compte_id` | `zone`, `compte`, `role`, `avant` (`en_attente`), `apres` (`valide`), `decide_par`, `motif` (facultatif) |
| `role.refuse` | `attribution_role` | `compte_id` | `zone`, `compte`, `role`, `avant` (`en_attente`), `apres` (`refuse`), `decide_par`, `motif` (REQUIS) |
| `role.suspendu` | `attribution_role` | `compte_id` | `zone`, `compte`, `role`, `avant` (`valide`), `apres` (`suspendu`), `decide_par`, `motif` (REQUIS) |
| `role.retabli` | `attribution_role` | `compte_id` | `zone`, `compte`, `role`, `avant` (`suspendu`), `apres` (`valide`), `decide_par`, `motif` (facultatif) |
| `dossier_coursier.soumis` | `dossier_coursier` | `compte_id` | `zone`, `compte`, `role` (`coursier`), `vehicules` (slugs déclarés), `re_soumission` (booléen — `true` si le dossier repart d'un `refuse`) |
| `dossier_coursier.vehicules_modifies` | `dossier_coursier` | `compte_id` | `zone`, `compte`, `role` (`coursier`), `vehicules` (la flotte APRÈS le geste), `avant` (la flotte remplacée — c'est la seule trace du changement, la table ne garde pas d'historique) |
| `adresse.enregistree` | `adresse` | `adresse.id` | `zone`, `compte`, `a_repere_texte`, `a_repere_vocal`, `livraison_origine` (`null` tant que CMD/CRS ne le posent pas — PROVISION) |
| `adresse.modifiee` | `adresse` | `adresse.id` | `zone`, `compte`, `champs` (noms des champs modifiés : `libelle`, `repere_texte`, `repere_vocal`) |
| `adresse.supprimee` | `adresse` | `adresse.id` | `zone`, `compte` |
| `adresse.repere_vocal_purge` | `adresse` | `adresse.id` | `zone`, `compte`, `retention_jours` (paramètre de zone appliqué), `derniere_utilisation_le` |

**Ce qui n'émet PAS d'événement outbox** (research R10) :

- les demandes et vérifications d'OTP — aucune entité durable ne transitionne ;
  l'entonnoir d'inscription relèvera de la taxonomie produit du cycle MET ;
- la rotation du refresh — ce n'est pas une transition d'état (data-model §4) ;
  seule la révocation qu'une réutilisation déclenche en émet une ;
- une flotte redéclarée À L'IDENTIQUE : `remplacer_vehicules_declares` compare
  l'avant et l'après, et n'écrit ni ligne ni événement quand rien ne change.
  Un rejeu réseau ne doit pas produire une seconde trace d'un changement qui
  n'a eu lieu qu'une fois (patron `adresse.modifiee`) ;
- les seeds — chargement initial, pas une transition (patron du cycle 002).

**Pourquoi `dossier_coursier.vehicules_modifies` n'est PAS un
`dossier_coursier.soumis`.** Une re-soumission repart d'un `refuse`, redépose
une pièce d'identité et remet le rôle `en_attente` d'une revue admin. Changer
de véhicule sur un dossier déjà validé ne fait rien de tout cela : le rôle a été
validé sur la pièce et le référent, pas sur la moto. Réutiliser `soumis`
annoncerait à tout consommateur qu'une revue est attendue — l'inverse de ce qui
se passe. Le changement reste tracé parce qu'il déplace l'éligibilité au
dispatch : `avant` et `vehicules` portent les deux flottes, la table n'en
gardant aucun historique.

### Événements du cycle VND (005 — prestataires agréés et catalogue vendeur)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que la transition
(constitution VI ; specs/005 data-model.md §6). Le registre est posé AVANT
l'implémentation (FR-051).

**Identification des entités.** `rattachement_compte` a une clé primaire
composite `(prestataire_id, compte_id)` : ses événements portent `entite_id` =
`compte_id`, le prestataire vivant dans le payload (patron `attribution_role`
du cycle 003).

**Minimisation (ARTCI, FR-052).** AUCUN payload ne porte de donnée nominative
ni de position GPS : ni nom de prestataire, ni contact téléphonique, ni
coordonnées de site. `acteur` est un UUID de compte ; `motif` est le texte de
décision admin (précédent des événements `role.*`) ; les modifications de fiche
sont décrites par des NOMS de champs, jamais leurs valeurs.

| Type | `entite_type` | `entite_id` | Payload spécifique (en plus des propriétés standard) |
|---|---|---|---|
| `prestataire.cree` | `prestataire` | `prestataire.id` | `zone`, `categorie` (slug), `acteur` |
| `prestataire.modifie` | `prestataire` | `prestataire.id` | `champs` (noms seulement : `nom`, `contact`, `delai_preparation`, `photos`), `acteur` |
| `prestataire.agree` | `prestataire` | `prestataire.id` | `zone`, `categorie`, `plaque_creee` (booléen — `true` au premier agrément), `acteur` |
| `prestataire.suspendu` | `prestataire` | `prestataire.id` | `zone`, `categorie`, `motif` (REQUIS), `acteur` |
| `prestataire.retabli` | `prestataire` | `prestataire.id` | `zone`, `categorie`, `acteur` |
| `prestataire.corrige` | `prestataire` | `prestataire.id` | `avant` (`{categorie, zone}`), `apres` (`{categorie, zone}`), `acteur` |
| `charte.deposee` | `charte_signee` | `charte_signee.id` | `prestataire`, `version_charte`, `acteur` |
| `rattachement.cree` | `rattachement` | `compte_id` | `prestataire`, `compte`, `role_attribue` (booléen — `false` si le compte portait déjà le rôle vendeur), `acteur` |
| `rattachement.supprime` | `rattachement` | `compte_id` | `prestataire`, `compte`, `acteur` |
| `site.statut_boutique_change` | `site` | `site.id` | `prestataire`, `avant`, `apres` (statuts), `pause_fin` (si mise en pause / prolongation), `source` (`vendeur` \| `admin`), `acteur` |
| `site.horaires_modifies` | `site` | `site.id` | `prestataire`, `avant`, `apres` (plages par jour), `source`, `acteur` |
| `article.cree` | `article` | `article.id` | `prestataire`, `prix` (unités mineures), `devise`, `prix_barre` (facultatif), `source`, `acteur` |
| `article.modifie` | `article` | `article.id` | `prestataire`, `champs` (noms), `prix`, `prix_barre` (si modifiés), `source`, `acteur` |
| `article.retire_du_catalogue` | `article` | `article.id` | `prestataire`, `source`, `acteur` |
| `article.remis_au_catalogue` | `article` | `article.id` | `prestataire`, `source`, `acteur` |
| `article.mis_en_rupture` | `article` | `article.id` | `prestataire`, `site`, `source` (`vendeur` \| `coursier` \| `admin`), `automatique` (booléen — `true` si masquage par seuil de signalements), `acteur` (`null` si automatique) |
| `article.remis_en_vente` | `article` | `article.id` | `prestataire`, `site`, `source` (`vendeur` \| `admin`), `automatique` (booléen — toujours `false` : une remise n'est jamais automatique dans le MVP ; champ partagé avec `article.mis_en_rupture` via le même émetteur), `acteur` |
| `signalement_rupture.recu` | `signalement_rupture` | `signalement_rupture.id` | `prestataire`, `article`, `site`, `coursier`, `deja_en_rupture` (booléen) |

**Ce qui n'émet PAS d'événement outbox** (specs/005 research R3, R10) :

- les ÉCHÉANCES — pause arrivée à terme, « fermé pour la journée » au jour
  suivant : l'état effectif est dérivé à la lecture, aucune transaction ne
  s'ouvre ; l'événement de mise en pause porte `pause_fin`, ce qui suffit à
  reconstituer la durée de fermeture ;
- les signalements coursier REFUSÉS (précondition de commande active non
  satisfaite) — « comptés nulle part » (FR-038) ;
- les rejeux idempotents (même `Idempotency-Key`) — ni double ligne, ni double
  événement ;
- le verrouillage d'un prix (`figer_prix`) — les événements de commande du
  cycle CMD couvriront ce parcours ;
- les seeds — chargement initial, pas une transition (patron des cycles 002/003).

### Événements du cycle QRC (006 — plaque QR, scan et collecte)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que la transition
(constitution VI ; specs/006 research R12). Le registre est posé AVANT
l'implémentation (FR-051, Definition of Done §0.4 point 4).

**Identification des entités.** L'état EN_LIVRAISON est logistique : il vit sur
le composant `livraison`, jamais sur le tronc `commande` (constitution II,
research R8). Les événements de plaque portent `entite_id` = `prestataire.id`
(la plaque n'a pas d'entité propre — son identité EST le prestataire).

**Minimisation (ARTCI).** AUCUN payload ne porte de position GPS brute : la
géo-proximité est réduite à un booléen `gps_ok` (ou une `distance_m` arrondie),
jamais un couple lat/lng. `acteur` est un UUID de compte (le coursier ou
l'admin), jamais un nominatif. Le **téléchargement** admin du PDF n'est pas une
transition durable : il n'émet rien (métrique produit, cycle MET). Les **rejeux
idempotents** (même `uuid_client`) n'émettent RIEN ; seuls les rejets métier
émettent `arret.collecte_rejetee`.

| Type | `entite_type` | `entite_id` | Payload spécifique (en plus des propriétés standard) |
|---|---|---|---|
| `plaque.generee` | `plaque` | `prestataire.id` | `prestataire`, `format` (`pdf`), `regeneration` (booléen — `true` si le PDF existait déjà), `acteur` |
| `arret.collecte` | `arret` | `arret.id` | `commande`, `livraison`, `segment`, `prestataire`, `mode` (`scan_qr` \| `code_secours`), `avec_photo` (booléen), `gps_ok` (booléen), `montant_avance` (unités mineures), `devise`, `acteur` |
| `livraison.mise_en_livraison` | `livraison` | `livraison.id` | `commande`, `nb_arrets`, `acteur` |
| `plaque.remplacement_requis` | `plaque` | `prestataire.id` | `prestataire`, `origine` (`qr_illisible`), `commande`, `arret`, `automatique` (`true`), `acteur` |
| `arret.collecte_rejetee` | `arret` | `arret.id` | `commande`, `mode`, `motif` (`jeton_revoque` \| `hors_zone` \| `etat_incompatible` \| `code_epuise`), `horodatage_client`, `acteur` |

**Ce qui n'émet PAS d'événement outbox** (specs/006 research R12) :

- le TÉLÉCHARGEMENT admin du PDF de plaque — lecture, pas une transition
  durable (la génération, elle, émet `plaque.generee`) ;
- les rejeux idempotents (même `uuid_client`) — ni double collecte, ni double
  événement (registre `qr.action_traitee`) ;
- les échecs de saisie du code de secours en deçà de l'épuisement — seul
  l'incident du 1er passage (`plaque.remplacement_requis`) et l'épuisement
  final (`arret.collecte_rejetee`, motif `code_epuise`) sont journalisés ;
- les seeds — chargement initial (patron des cycles 002/003/005).

Le crate `metriques` reste un **stub** : QRC ne fait qu'ALIMENTER l'outbox
(matière première des métriques MET-01/02/03, cycles ultérieurs).

### Événements du cycle TRF (007 — tarification, routage, grille d'effort)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que l'opération
(constitution VI ; specs/007 research R10). Registre posé AVANT l'implémentation
(Definition of Done §0.4 point 4).

**Le simulateur est MUET.** Rejouer un brouillon est un *dry run* (research
R11) : aucune de ces trois lignes n'est écrite en simulation, sans quoi les
métriques MET compteraient des essais d'admin comme des courses réelles.

**Identification des entités.** Une grille tarifaire est une entité durable
(`tarification.grille`) : `grille.publiee` porte son `id`. Un **devis** n'est en
revanche pas persisté par TRF ce cycle (CMD le verrouillera) : `routage.degrade`
et `effort.calcule` portent en `entite_id` l'identifiant de la **zone** évaluée
— la seule entité durable en jeu au moment du calcul. Ces deux événements sont
des faits de calcul agrégeables par zone, pas des transitions d'état.

**Minimisation (ARTCI).** AUCUN payload ne porte de coordonnée brute : les
positions des retraits et de la destination restent dans la requête et n'entrent
jamais dans l'outbox. Seules des **distances arrondies** (mètres, entiers) et des
**montants en unités mineures** sont journalisés. `acteur` est un UUID de compte
admin, jamais un nominatif.

| Type | `entite_type` | `entite_id` | Payload spécifique (en plus des propriétés standard) |
|---|---|---|---|
| `grille.publiee` | `grille` | `grille.id` | `zone`, `grille`, `version`, `effet_le`, `version_precedente` (entier \| null — la grille passée à l'historique), `nb_regles`, `acteur` |
| `routage.degrade` | `devis` | `zone.id` | `zone`, `transport`, `nb_points`, `distance_m` (**arrondie**, vol d'oiseau × facteur), `facteur` (ex. `1.4`), `motif` (`routage_indisponible`) |
| `effort.calcule` | `devis` | `zone.id` | `zone`, `transport`, `montant_effort`, `paliers`, `attente`, `arrets` (unités mineures), `nb_articles`, `nb_arrets`, `facture` (`false` — journalisé non facturé pendant la promo), `devise` |

**Ce qui n'émet PAS d'événement outbox** (specs/007 research R10/R11) :

- la **simulation** d'un brouillon — dry run, aucune trace (elle pose seulement
  `simulee_le`/`simulee_empreinte` sur le brouillon, garde de publication) ;
- l'**édition** d'une règle de brouillon — le brouillon n'a aucun effet
  tarifaire tant qu'il n'est pas publié ; seule la publication est une
  transition (`grille.publiee`) ;
- une **évaluation nominale** — pas de `devis.calcule` : le volume serait élevé
  pour une valeur métrique nulle (le devis vivra dans la commande, cycle CMD) ;
- un **effort FACTURÉ** (drapeaux de promo OFF) — `effort.calcule` ne journalise
  que le cas « calculé mais non facturé », qui est précisément celui qu'aucune
  ligne de paiement ne tracerait ;
- les **seeds** — chargement initial, pas une transition (patron 002/003/005/006).

### Événements du cycle CMD (008 — cycle de vie complet d'une commande)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que la transition
(constitution VI ; specs/008 data-model §7). Registre posé AVANT l'implémentation
(Definition of Done §0.4 point 4). **27 événements** : 25 nouveaux ci-dessous +
`arret.collecte` et `livraison.mise_en_livraison`, hérités du cycle QRC 006 et
**inchangés** (leur payload ne bouge pas — le type d'arrêt n'y entre pas).

**Identification des entités.** Le tronc `commande`, la `livraison`, l'`arret`,
la `substitution` et l'`issue_echec` sont des entités durables portant leur `id`.
`panier.scission_proposee` fait exception : **aucun panier n'existe côté serveur**
(research R8) — l'événement porte en `entite_id` l'identifiant du **compte
client**, la seule entité durable en jeu, et reste une métrique de proposition,
jamais une transition d'état. `sanction.posee` porte `entite_id` = `compte.id`
(la restriction vit sur des colonnes de `comptes.compte`, écrites par le crate
`comptes` — research R12).

**Minimisation (ARTCI).** AUCUN payload ne porte de coordonnée brute : ni le
lieu de prestation, ni la position du coursier, ni celle d'un site. Les
distances sont **arrondies** en mètres, les montants sont des **entiers en
unités mineures** accompagnés de leur devise. Aucun numéro de téléphone
n'entre dans `appel.intention` — seules l'intention, sa direction et son motif
sont journalisées. Aucun nom de client, de vendeur ni de coursier : uniquement
des UUID. Les **codes et jetons de remise** ne sont JAMAIS journalisés, pas même
sous forme d'empreinte.

**Trois contrats sans consommateur** ce cycle, émis pour que le cycle
propriétaire s'y branche sans modifier CMD : `commande.prete_a_dispatcher`
(DSP), `litige.ouvert` (AVI-04) et `indemnisation.due` (CRS-06).

| Type | `entite_type` | `entite_id` | Payload spécifique (en plus des propriétés standard) |
|---|---|---|---|
| `commande.creee` | `commande` | `commande.id` | `zone`, `categorie`, `nb_vendeurs`, `nb_articles`, `montant_articles`, `total`, `devise`, `mode_paiement`, `mono_vendeur` (booléen), `acteur` |
| `commande.paiement_requis` | `commande` | `commande.id` | `motif` (`plafond` \| `prepaiement_impose` \| `restauration_sans_historique`), `total`, `devise`, `plafond` |
| `commande.prete_a_dispatcher` | `commande` | `commande.id` | `zone`, `nb_arrets`, `montant_a_avancer`, `devise`, `transport_requis` (slug) — **consommé par DSP** |
| `commande.paiement_confirme` | `commande` | `commande.id` | `mode` (`mobile_money`), `total`, `devise` — le tronc repasse `nouvelle` |
| `commande.mise_en_attente_coursier` | `commande` | `commande.id` | `zone`, `motif` (`aucun_coursier_eligible`), `age_s` |
| `commande.attente_coursier_escaladee` | `commande` | `commande.id` | `zone`, `age_s`, `seuil_s` (paramètre de zone franchi), `chemin` (`file` \| `pipeline`) — **amendé par le cycle DSP 009**, voir ci-dessous |
| `commande.assignee` | `commande` | `commande.id` | `livraison`, `coursier`, `depuis_attente` (booléen — reprise FIFO) |
| `commande.terminee` | `commande` | `commande.id` | `mode_remise` (`qr` \| `code` \| `depot`), `duree_totale_s`, `total_encaisse`, `devise` |
| `remise.code_epuise` | `commande` | `commande.id` | `livraison`, `essais` (= le plafond de zone atteint), `acteur` (coursier) — **aucun code, jamais** : le publier dans un événement le sortirait du seul canal qui doit le porter (client ↔ coursier, R6) |
| `commande.annulee` | `commande` | `commande.id` | `par` (`client` \| `admin` \| `systeme`), `motif_cle`, `sans_frais` (booléen), `part_coursier_due` (unités mineures), `remboursement_du` (booléen), `devise` |
| `commande.echec_declare` | `commande` | `commande.id` | `type_issue`, `preuves_ok` (booléen — toujours `true` : sans preuves, l'écriture est refusée) |
| `panier.scission_proposee` | `commande` (virtuel) | `compte.id` (client) | `zone`, `categorie`, `cause` (`categorie_non_mixable` \| `plafond_eclatement`), `nb_commandes` — **métrique SC-006** |
| `livraison.creee` | `livraison` | `livraison.id` | `commande`, `nb_arrets`, `devis_prix_client`, `devis_part_coursier`, `devise`, `degraded` (booléen) |
| `livraison.affectee` | `livraison` | `livraison.id` | `commande`, `coursier`, `delai_assignation_s` |
| `livraison.mise_en_collecte` | `livraison` | `livraison.id` | `commande`, `arret` (celui qui a déclenché), `acteur` |
| `livraison.livree` | `livraison` | `livraison.id` | `commande`, `mode_remise`, `essais_code` (entier) |
| `arret.en_route` | `arret` | `arret.id` | `commande`, `livraison`, `ordre`, `acteur` |
| `arret.arrive` | `arret` | `arret.id` | `commande`, `livraison`, `ordre`, `attente_depuis_s` — **base de la prime d'attente TRF-06** |
| `arret.indisponible` | `arret` | `arret.id` | `commande`, `livraison`, `nb_lignes_retirees`, `motif` (`vendeur_ferme` \| `toutes_lignes_retirees`), `acteur` |
| `substitution.proposee` | `substitution` | `substitution.id` | `commande`, `ligne`, `arret`, `ecart_pourcent` (entier signé), `echeance_s`, `acteur` |
| `substitution.decidee` | `substitution` | `substitution.id` | `commande`, `issue` (`acceptee` \| `refusee` \| `expiree_appel` \| `retiree`), `delai_reponse_s`, `acteur` (`null` si expiration automatique) |
| `ligne.retiree` | `ligne_commande` | `ligne_commande.id` | `commande`, `motif` (`preference` \| `expiration` \| `refus` \| `arret_indisponible`), `montant_retire`, `devise` |
| `appel.intention` | `commande` | `commande.id` | `de` (`client` \| `coursier` \| `systeme`), `vers` (`client` \| `coursier`), `motif` (`suivi` \| `substitution` \| `expiration`) — **aucun numéro** |
| `echec.issue_enregistree` | `issue_echec` | `issue_echec.id` | `commande`, `arret` (`null` = à la remise), `type_issue`, `detenteur_argent`, `detenteur_marchandise`, `montant_en_jeu`, `devise`, `motif_cle`, `acteur` |
| `litige.ouvert` | `issue_echec` | `issue_echec.id` | `commande`, `type_issue`, `arret` — **contrat pour AVI-04** (sans consommateur) |
| `indemnisation.due` | `issue_echec` | `issue_echec.id` | `commande`, `coursier`, `montant`, `devise` — **contrat pour CRS-06** (sans consommateur) |
| `sanction.posee` | `compte` | `compte.id` | `sanction` (`prepaiement_impose` \| `bloque`), `motif_cle`, `rang` (1 = 1ᵉʳ refus périssable, 2 = 2ᵉ) |

**Ce qui n'émet PAS d'événement outbox** (specs/008 research R8, R7, R10) :

- le **devis de panier** (`POST /paniers/devis`) — aucune écriture, aucune ligne,
  aucun événement autre que `panier.scission_proposee` lorsqu'une proposition est
  effectivement formulée (**P4** du plan) ;
- les **rejeux idempotents** — même `Idempotency-Key` de création, même
  `uuid_client` de transition ou de décision : ni double ligne, ni second
  événement ;
- la **résolution d'une échéance à la lecture** tant qu'elle ne change rien —
  seule l'expiration effectivement écrite émet `substitution.decidee` ;
- les **transitions refusées** (hors séquence, non-propriétaire, état terminal) —
  un refus n'est pas une transition ;
- les **seeds** — chargement initial (patron des cycles 002/003/005/006/007).

### Événements du cycle DSP (009 — dispatch automatique)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que la transition
(constitution VI ; specs/009 data-model §7). Registre posé AVANT
l'implémentation. **12 nouveaux** ci-dessous, plus **1 amendé** :
`commande.attente_coursier_escaladee` gagne `chemin` (`file` \| `pipeline`),
parce que DSP-06 escalade *toute* commande non assignée — celles qui attendent
dans la file FIFO comme celles dont la cascade n'a trouvé personne. Son
`NOT EXISTS` sur l'outbox **reste** le marqueur d'idempotence : c'est lui qui
livre « exactement une alerte par commande, quel que soit le chemin » (FR-066,
research R14) sans colonne supplémentaire qui pourrait s'en désynchroniser.

| Événement | `entite_type` | `entite_id` | Payload spécifique |
|---|---|---|---|
| `coursier.disponibilite_changee` | `coursier` | `compte.id` | `zone`, `en_ligne` (booléen), `capacites` (slugs), `motif` (`manuel` \| `ttl_expire`) |
| `coursier.plafond_jour_declare` | `coursier` | `compte.id` | `zone`, `plafond_declare_unites`, `plafond_retenu_unites`, `devise`, `palier_note` |
| `dispatch.evaluation_faite` | `commande` | `commande.id` | `zone`, `nb_eligibles`, `nb_ecartes`, `motifs` (objet motif→compte), `degraded` (booléen), `mesure` (`duree` \| `distance`) |
| `dispatch.offre_emise` | `offre` | `offre.id` | `commande`, `coursier`, `mode` (`cascade` \| `broadcast`), `rang`, `score`, `montant_a_avancer`, `devise`, `timer_s` |
| `dispatch.offre_acceptee` | `offre` | `offre.id` | `commande`, `coursier`, `livraison`, `delai_reponse_s` |
| `dispatch.offre_refusee` | `offre` | `offre.id` | `commande`, `coursier`, `delai_reponse_s` |
| `dispatch.offre_non_repondue` | `offre` | `offre.id` | `commande`, `coursier`, `franche` (booléen), `rang_du_jour` |
| `dispatch.offre_deja_prise` | `offre` | `offre.id` | `commande`, `coursier` — **sans pénalité**, le coursier reste dans le pool (FR-049) |
| `dispatch.broadcast_ouvert` | `commande` | `commande.id` | `zone`, `nb_destinataires`, `cause` (`candidats_epuises` \| `delai`) |
| `dispatch.bascule_prepaiement` | `commande` | `commande.id` | `zone`, `montant_a_avancer`, `plafond_max_constate`, `devise` |
| `dispatch.reassignation` | `livraison` | `livraison.id` | `commande`, `coursier_retire`, `motif` (`sans_mouvement` \| `sans_scan`), `distance_m` (arrondie), `stagnation_s`, `acteur` (`systeme` \| `admin`) |
| `dispatch.course_bloquee_escaladee` | `livraison` | `livraison.id` | `commande`, `coursier`, `motif`, `nb_arrets_collectes` — **jamais** de reprise automatique quand un arrêt est collecté (FR-075) |

**Minimisation (ARTCI).** AUCUN payload de ce cycle ne porte de coordonnée : ni
la position du coursier, ni celle d'un site, ni le lieu de prestation. Les
distances sont **arrondies en mètres entiers**, les montants sont des **entiers
en unités mineures** accompagnés de leur devise, et aucun numéro de téléphone
n'entre nulle part. `coursier.disponibilite_changee` dit *qu'*un coursier est
entré ou sorti du pool, jamais *où* il est. Un test dédié parcourt tous les
événements du module et échoue sur la présence d'une clé interdite (SC-011).

**Le classement détaillé ne va PAS dans l'outbox.** `dispatch.evaluation_faite`
en porte l'agrégat ; le détail par candidat (composantes, score, rang, motifs
d'écart) part dans les **logs structurés** avec l'identifiant de corrélation
(constitution VII). Émettre le vivier complet à chaque relance gonflerait
l'outbox sans servir de KPI.

**Déjà émis par `commandes`, non redéfinis ici** : `commande.prete_a_dispatcher`
(désormais **consommé** — DSP est le premier consommateur outbox réel du
produit), `commande.paiement_confirme` (consommé aussi : il reprend le pipeline
après la bascule prépaiement), `commande.mise_en_attente_coursier`,
`commande.assignee`, `livraison.affectee` et `commande.paiement_requis`.

**Qualification produit vs opérations (MET-01).** Tous les événements ci-dessus
sont des événements d'**opérations** (dérivés de l'outbox), sauf
`coursier.disponibilite_changee` et `coursier.plafond_jour_declare`, qui sont des
événements **produit** : ce sont des actions délibérées de Yao dans l'app. KPIs
directement dérivables : délai création → assignation, taux de refus, taux de
non-réponse, part de broadcasts, taux d'escalade, taux de réassignation, part de
dégradé routier.

**Ce qui n'émet PAS d'événement dans ce cycle** :

- une **publication de position** — c'est un fait éphémère, écrit en Redis et
  rejoué toutes les 30 s ; l'émettre noierait l'outbox et porterait une
  coordonnée, ce que la minimisation interdit ;
- une **sortie de pool par expiration** tant que personne ne la constate — le
  motif `ttl_expire` n'est journalisé qu'au passage qui la constate ;
- une **offre échue lue avant le tic** — la lecture respecte l'échéance
  persistée ; seule l'expiration effectivement écrite émet
  `dispatch.offre_non_repondue` (patron du cycle 008) ;
- un **rejeu idempotent** d'acceptation, de refus ou de position — même
  `uuid_client`, ni seconde ligne ni second événement ;
- le **seed** des 18 paramètres — un chargement n'est pas une transition.

### Événements du cycle CRS (010 — app coursier : course active, cash, hors-ligne)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que la transition
(constitution VI ; specs/010 `contracts/ports-coursier.md` §3). Registre posé
**avant** l'implémentation (Definition of Done §0.4 point 4). **7 nouveaux**
ci-dessous, plus **deux existants qui changent de statut sans changer de forme** :

- `appel.intention` (cycle CMD 008) gagne son **premier émetteur `de: coursier`**.
  Sa forme ne bouge pas — la taxonomie prévoyait déjà cette valeur, personne ne
  l'avait encore écrite. Le motif `client_absent` s'ajoute à l'énumération déjà
  publiée (`suivi` | `substitution` | `expiration`) : c'est le seul motif compté
  par la preuve d'échec (FR-035).
- `remise.code_epuise` (cycle CMD 008) gagne enfin **un consommateur** :
  `GET /admin/remises/bloquees` (FR-044). L'événement était émis depuis le cycle
  008 sans que rien ne s'y abonne — le `tracing::warn!` qui l'accompagnait ne
  s'abonnait pas non plus.

**Minimisation (ARTCI).** AUCUN payload de ce cycle ne porte de secret ni de
donnée personnelle : ni le code de remise à 4 chiffres, ni le jeton de réception,
ni le code de secours vendeur, **pas même sous forme d'empreinte** ; aucun numéro
de téléphone, alors même que ce cycle en sert **deux** dans le
pré-provisionnement (client et vendeur, R6) ; aucune coordonnée brute — la
présence est réduite à une **durée en secondes** et les relevés à des
**distances arrondies** (patron `distance_scan_m` du cycle 006). Les montants
sont des **entiers en unités mineures** accompagnés de leur devise. `acteur` est
un UUID de compte. Un test transverse balaye les charges utiles du module et
échoue sur la présence d'une clé interdite (SC-015, T085).

| Type | `entite_type` | `entite_id` | Payload spécifique (en plus des propriétés standard) |
|---|---|---|---|
| `preuves_echec.reunies` | `livraison` | `livraison.id` | `commande`, `appels_retenus` (entier — motif `client_absent` uniquement), `presence_s` (durée retenue, trous exclus), `photos` (entier), `delai_depuis_arrivee_s` — l'**issue déclarée** des appels n'y figure pas : elle n'est pas un critère (R19) |
| `caisse.mouvement` | `ecriture_caisse` | `ecriture_caisse.id` | `coursier`, `type` (`avance` \| `remboursement` \| `indemnisation` \| `correction`), `montant` (**signé**, unités mineures), `devise`, `commande`, `arret`, `source` (`outbox` \| `admin`) |
| `indemnisation.validee` | `indemnisation` | `indemnisation.id` | `coursier`, `commande`, `montant`, `devise`, `litige` (`null` tant qu'AVI-04 n'existe pas), `acteur` |
| `indemnisation.refusee` | `indemnisation` | `indemnisation.id` | `coursier`, `commande`, `montant`, `devise`, `motif_cle` (REQUIS), `acteur` |
| `remise.code_debloque` | `commande` | `commande.id` | `livraison`, `essais_avant` (compteur au moment du blocage), `motif_cle` (REQUIS), `acteur` — **aucun code** |
| `depot.autorise` | `commande` | `commande.id` | `livraison`, `autorise` (booléen — l'événement porte aussi la **fermeture**), `motif_cle` (REQUIS), `acteur` |
| `coursier.action_reconciliee` | `livraison` | `livraison.id` | `commande`, `coursier`, `action` (`collecte` \| `transition` \| `remise` \| `echec`), `issue` (`rejouee` \| `refusee_definitivement`), `motif_cle`, `age_local_s` (âge de l'action dans la file, en secondes) |

**Qualification produit vs opérations (MET-01).** `preuves_echec.reunies`,
`caisse.mouvement`, `indemnisation.validee`, `indemnisation.refusee`,
`remise.code_debloque` et `depot.autorise` sont des événements **produit** — des
faits métier dont dépendent de l'argent et une décision d'exploitation.
`coursier.action_reconciliee` est un événement d'**opérations** : il mesure la
santé de la file hors-ligne, pas le parcours de Yao.

**Aucun KPI manuel** (constitution VI) : le taux d'échec avec preuves, la durée
moyenne de présence avant échec, l'exposition cash moyenne, le taux de remise
hors ligne et le taux de refus définitif au rejeu se dérivent tous de ces
événements et de ceux du cycle 008.

**Ce qui n'émet PAS d'événement dans ce cycle** :

- la **coche d'un article** de la checklist — c'est un aide-mémoire d'achat
  strictement local à l'appareil, jamais un fait métier (R11) ;
- un **relevé de présence** isolé — seul le franchissement du seuil émet
  (`preuves_echec.reunies`) ; journaliser chaque échantillon noierait l'outbox
  d'un fait qui n'intéresse personne à l'unité ;
- une **lecture** de caisse, de journée ou de preuves — aucune transition ;
- un **rejeu idempotent** (même `uuid_client` d'appel, de présence, de photo, de
  remise ou d'échec) — ni seconde ligne, ni second événement. Un rejeu **refusé
  définitivement**, lui, émet `coursier.action_reconciliee` : c'est précisément
  le cas qu'il faut voir passer ;
- une **demande** d'indemnisation créée par consommation de `indemnisation.due` —
  l'événement source existe déjà (cycle 008) ; le redoubler à la consommation
  compterait deux fois la même demande. Seules la **validation** et le **refus**
  émettent ;
- les **seeds** — chargement initial (patron des cycles 002 → 009).

## Taxonomie produit (MET-01) — déclarations en attente d'ingestion

Événements PRODUIT émis par les apps (cadrage §10.9), distincts du journal
outbox. L'ingestion (`/events`, MET-02) n'existe pas encore : ce cycle DÉCLARE
les événements du parcours vendeur V1/V2 (Definition of Done §0.4 point 4,
FR-053) ; leur émission arrivera avec le cycle MET. Propriétés standard :
`zone`, `categorie`, `role`, `version_app`, `plateforme`.

| Événement produit | Parcours | Propriétés spécifiques |
|---|---|---|
| `vendeur_boutique_bascule` | V1 — interrupteur ouvrir/fermer | `action` (`ouvrir` \| `fermer`) |
| `vendeur_pause_demarree` | V1 — mise en pause | `duree_minutes` (30 \| 60 \| 120) |
| `vendeur_pause_prolongee` | V1 — prolongation / fermeture journée | `action` (`prolonger` \| `fermer_journee`) |
| `vendeur_article_bascule_dispo` | V2 — bascule En stock / Rupture | `vers` (`rupture` \| `en_vente`) |
| `vendeur_article_cree` | V2 — ajout d'article | `avec_photo`, `avec_prix_barre` (booléens) |
| `vendeur_prix_modifie` | V2 — fiche article | `avec_prix_barre` (booléen) |

*(Les autres événements produit — `commande.*`, `livraison.*`, `paiement.*`… —
sont ajoutés à ce registre par les cycles qui les émettent, avec leurs parcours.)*
