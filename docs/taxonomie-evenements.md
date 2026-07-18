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
| `adresse.enregistree` | `adresse` | `adresse.id` | `zone`, `compte`, `a_repere_texte`, `a_repere_vocal`, `livraison_origine` (`null` tant que CMD/CRS ne le posent pas — PROVISION) |
| `adresse.modifiee` | `adresse` | `adresse.id` | `zone`, `compte`, `champs` (noms des champs modifiés : `libelle`, `repere_texte`, `repere_vocal`) |
| `adresse.supprimee` | `adresse` | `adresse.id` | `zone`, `compte` |
| `adresse.repere_vocal_purge` | `adresse` | `adresse.id` | `zone`, `compte`, `retention_jours` (paramètre de zone appliqué), `derniere_utilisation_le` |

**Ce qui n'émet PAS d'événement outbox** (research R10) :

- les demandes et vérifications d'OTP — aucune entité durable ne transitionne ;
  l'entonnoir d'inscription relèvera de la taxonomie produit du cycle MET ;
- la rotation du refresh — ce n'est pas une transition d'état (data-model §4) ;
  seule la révocation qu'une réutilisation déclenche en émet une ;
- les seeds — chargement initial, pas une transition (patron du cycle 002).

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
| `article.remis_en_vente` | `article` | `article.id` | `prestataire`, `site`, `source` (`vendeur` \| `admin`), `acteur` |
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
