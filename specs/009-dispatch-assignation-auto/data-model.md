# Phase 1 — Modèle de données : dispatch automatique (cycle 009)

Trois lieux, trois natures, et la frontière entre eux est la garantie de
robustesse du cycle : **Postgres** porte la vérité, **Redis** porte l'index
éphémère, la **configuration de zone** porte les réglages. Rien de métier ne vit
en Redis (constitution II) ; rien de paramétrable ne vit en dur (constitution I).

---

## 1. Migrations à créer

**Trois** fichiers, et le découpage n'est pas cosmétique.

- La séparation `0010` / `0011` vient de la leçon du cycle 008 : PostgreSQL
  interdit d'**utiliser** une valeur d'énum dans la transaction qui l'ajoute, et
  sqlx exécute chaque fichier dans **une** transaction. Un fichier unique
  échouerait au **déploiement**, pas en développement.
- La séparation `0011` / `0012` vient de la lisibilité de l'historique : le nom
  d'un fichier de migration doit dire **quel schéma** il touche. Une table
  `commandes` cachée dans un fichier nommé `dispatch` rendrait l'histoire du
  schéma `commandes` introuvable sous son nom.

Les migrations `0001→0009` restent **intouchées** (constitution I).

### `0010_dispatch_enums.sql` — types seuls, aucune structure

```sql
CREATE SCHEMA IF NOT EXISTS dispatch;

-- Mode d'émission d'une offre (DSP-04 vs DSP-05).
CREATE TYPE dispatch.mode_offre AS ENUM ('cascade', 'broadcast');

-- Issue d'une offre. `deja_prise` n'est PAS un refus : aucune pénalité, et le
-- coursier reste dans le pool (FR-049).
CREATE TYPE dispatch.issue_offre AS ENUM (
    'en_vol', 'acceptee', 'refusee', 'non_repondue', 'deja_prise', 'annulee'
);

-- Motif d'écart d'éligibilité — un par critère de DSP-02, pour que chaque
-- motif ait son test (SC-013) et que la bascule prépaiement soit décidable
-- (FR-026 : « la capacité d'avance est le SEUL critère bloquant »).
CREATE TYPE dispatch.motif_ecart AS ENUM (
    'hors_ligne', 'course_active', 'capacite_non_couverte', 'hors_rayon',
    'capacite_avance', 'paire_bloquee', 'compte_indisponible', 'offre_en_vol'
);

-- Motif de reprise automatique (DSP-07) — deux CRITÈRES distincts, R13.
CREATE TYPE dispatch.motif_reassignation AS ENUM ('sans_mouvement', 'sans_scan');
```

### `0011_dispatch_tables.sql` — tables, index, contraintes du schéma `dispatch`

Quatre tables, **rien d'autre** : ce fichier ne touche que le schéma `dispatch`.

```sql
-- ── 1. Offres ──────────────────────────────────────────────────────────────
-- Le REGISTRE des offres. Le verrou Redis est le dispositif de concurrence ;
-- cette table est la mémoire : elle porte l'échéance (donc le compte à rebours
-- survit à un redémarrage, R1) et l'issue (donc le taux d'acceptation et les
-- non-réponses franches se calculent sans agrégat à resynchroniser, R11).
CREATE TABLE dispatch.offre (
    id                 uuid        PRIMARY KEY,          -- UUIDv7 = jeton du verrou
    commande_id        uuid        NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    coursier_id        uuid        NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    zone_id            uuid        NOT NULL REFERENCES zones.zone (id) ON DELETE RESTRICT,
    mode               dispatch.mode_offre  NOT NULL,
    rang               smallint    NOT NULL,             -- rang dans la cascade (0 en broadcast)
    score              integer     NOT NULL,             -- entier, R6 — trace de la décision
    montant_a_avancer  bigint      NOT NULL CHECK (montant_a_avancer >= 0),
    devise             text        NOT NULL,
    emise_le           timestamptz NOT NULL DEFAULT now(),
    echeance_le        timestamptz NOT NULL,             -- PERSISTÉE (R1) — autorité du timer
    issue              dispatch.issue_offre NOT NULL DEFAULT 'en_vol',
    repondue_le        timestamptz,
    franche            boolean     NOT NULL DEFAULT false, -- non-réponse non pénalisée (FR-052)
    CHECK (echeance_le > emise_le),
    CHECK ((issue = 'en_vol') = (repondue_le IS NULL))
);

-- UNE seule offre en vol par commande, et UNE par coursier : les deux verrous
-- Redis (R3) ont ici leur filet Postgres. Un index UNIQUE partiel rend
-- l'invariant vrai même si Redis a disparu.
CREATE UNIQUE INDEX offre_en_vol_par_commande ON dispatch.offre (commande_id)
    WHERE issue = 'en_vol';
CREATE UNIQUE INDEX offre_en_vol_par_coursier ON dispatch.offre (coursier_id)
    WHERE issue = 'en_vol';

-- Échéances à résoudre par le tic (R1) : le plus urgent d'abord.
CREATE INDEX offre_echeances ON dispatch.offre (echeance_le)
    WHERE issue = 'en_vol';
-- Taux d'acceptation sur fenêtre + non-réponses du jour (FR-038, FR-052).
CREATE INDEX offre_par_coursier_date ON dispatch.offre (coursier_id, emise_le DESC);
-- Ne jamais re-solliciter pour la MÊME commande (FR-051, FR-074) — aucune
-- colonne dédiée : l'historique des offres EST la mémoire.
CREATE INDEX offre_par_commande ON dispatch.offre (commande_id, coursier_id);

-- ── 2. Plafond d'avance déclaré du jour ────────────────────────────────────
-- Journalier et jamais reporté (FR-011) : la clé primaire porte la DATE. Le
-- plafond RETENU est min(déclaré, grille par note) et n'est pas stocké — il se
-- recalcule, parce que la note peut changer entre deux offres.
CREATE TABLE dispatch.plafond_jour (
    coursier_id     uuid   NOT NULL REFERENCES comptes.compte (id) ON DELETE CASCADE,
    jour            date   NOT NULL,                    -- jour civil de la zone
    plafond_unites  bigint NOT NULL CHECK (plafond_unites >= 0),
    devise          text   NOT NULL,
    declare_le      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (coursier_id, jour)
);

-- ── 3. Incidents de réassignation ──────────────────────────────────────────
-- Tracé (FR-073), lu plus tard par la caisse coursier (CRS-06) et les incidents
-- de dossier (ADM-04). PROVISION sans FK vers un litige : AVI n'existe pas.
CREATE TABLE dispatch.incident_reassignation (
    id                 uuid        PRIMARY KEY,
    commande_id        uuid        NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    livraison_id       uuid        NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    coursier_retire_id uuid        NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    motif              dispatch.motif_reassignation NOT NULL,
    constate_le        timestamptz NOT NULL DEFAULT now()
);
-- Pas de reprise en boucle pour le même motif (FR-076).
CREATE UNIQUE INDEX incident_unique_par_motif
    ON dispatch.incident_reassignation (livraison_id, coursier_retire_id, motif);

-- ── 4. Progression observée d'une course assignée ──────────────────────────
-- Redis ne garde que la DERNIÈRE position : il n'y a aucun historique pour dire
-- « il ne s'est pas rapproché depuis 5 minutes » (R13). Et la décision retire
-- une course à quelqu'un — elle ne peut pas dépendre d'un service éphémère.
CREATE TABLE dispatch.suivi_progression (
    livraison_id      uuid        PRIMARY KEY REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    -- Distance ROUTIÈRE au premier arrêt non résolu, en mètres ENTIERS.
    distance_m        bigint      NOT NULL CHECK (distance_m >= 0),
    -- Meilleure (plus petite) distance observée depuis la dernière remise à zéro :
    -- c'est CONTRE ELLE que le rapprochement se mesure, sinon un aller-retour
    -- passerait pour une progression.
    distance_min_m    bigint      NOT NULL CHECK (distance_min_m >= 0),
    observe_le        timestamptz NOT NULL,
    -- Horodatage du dernier rapprochement SIGNIFICATIF (≥ seuil de zone).
    progresse_le      timestamptz NOT NULL,
    degraded          boolean     NOT NULL DEFAULT false  -- constitution IV
);
CREATE INDEX suivi_progression_stagnation ON dispatch.suivi_progression (progresse_le);
```

### `0012_commandes_capacites.sql` — extensions du schéma `commandes` (R9)

Deux objets et un rétro-remplissage, dans un fichier qui **porte le nom du schéma
qu'il touche**. Écrit par le crate `commandes` (constitution II : l'appartenance
des schémas ne bouge pas), lu par `dispatch` à travers un port.

```sql
-- CAPACITÉS REQUISES : sur la LIVRAISON, jamais sur le tronc (constitution II —
-- « le tronc ne contient AUCUN champ logistique » ; quel véhicule il faut EST
-- logistique). Table (famille, valeur) et non colonne : FR-018 exige que
-- l'ajout d'une famille (qualification d'artisan, phase N) ne coûte ni
-- migration ni réécriture du filtre.
CREATE TABLE commandes.capacite_requise (
    livraison_id uuid NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    famille      text NOT NULL,   -- MVP : 'transport'
    valeur       text NOT NULL,   -- MVP : slug de zones.type_transport
    PRIMARY KEY (livraison_id, famille, valeur)
);

-- Base de la composante d'INACTIVITÉ (FR-036) : dernière course livrée d'un
-- coursier. L'index partiel `livraison_coursier_active` du cycle 008 ne sert
-- pas — il filtre sur les états de TRAVAIL, pas sur `livree`.
CREATE INDEX livraison_coursier_livree ON commandes.livraison (coursier_id, livree_le DESC)
    WHERE etat = 'livree';
```

**Rétro-remplissage.** La migration copie la capacité requise des livraisons
existantes depuis la charge utile déjà écrite de `commande.prete_a_dispatcher`
(`payload->>'transport_requis'`) : les commandes du cycle 008 restent
dispatchables, et rien n'est perdu ni deviné.

---

## 2. Clés Redis (éphémère, reconstructible — constitution II)

| Clé | Type | Écrite par | Expiration | Contenu |
|---|---|---|---|---|
| `coursier:pos:{coursier}` | string | publication de position | `EX dispatch.pool_ttl_s` | `lat:lon:epoch_s` — **format du cycle 008, inchangé** (lu par le suivi client) |
| `dispatch:etat:{coursier}` | hash | publication de position | `EXPIRE dispatch.pool_ttl_s` | `zone`, `statut`, `capacites` (CSV de slugs), `note_centiemes`, `plafond_unites`, `devise`, `course_active` |
| `dispatch:pool:{zone}` | GEO (zset) | publication de position | — (élagage `ZREM`) | membre = `{coursier}` |
| `dispatch:offre:cmd:{commande}` | string | script Lua de pose | `EX dispatch.verrou_offre_s` | jeton = `offre.id` |
| `dispatch:offre:crs:{coursier}` | string | script Lua de pose | `EX dispatch.verrou_offre_s` | jeton = `offre.id` |

**Invariant.** « Être dans le pool » = le hash `dispatch:etat:{coursier}` existe.
L'index GEO n'a pas d'expiration par membre (limite de Redis) : un membre
fantôme est élagué paresseusement dès qu'on constate l'absence de son hash, et
par le tic. Un fantôme ne peut jamais recevoir d'offre — l'éligibilité lit le hash
**puis** confirme en Postgres (R12).

**Perte totale (FR-008, SC-004).** Les cinq clés se réécrivent : les trois
premières à la publication suivante, les deux dernières par le tic qui relit les
offres `en_vol` échues en base. Aucune commande n'est perdue, aucune n'est
doublement assignée (R4).

---

## 3. Machine à états — deux lignes ajoutées à une table **fermée**

`commandes::etats::TRANSITIONS` est déclarative : une transition absente est
refusée. Le cycle ajoute exactement deux lignes, niveau `Commande`, acteur
`Systeme` :

| Depuis | Vers | Pourquoi | FR |
|---|---|---|---|
| `nouvelle` | `en_attente_paiement` | capacité d'avance seule bloquante → prépaiement exigé | FR-026 |
| `en_cours` | `en_attente_coursier` | retrait du coursier par réassignation → retour au pipeline | FR-073 |

Rien d'autre. Les sorties existent déjà : `en_attente_paiement → nouvelle`
(paiement confirmé, `Systeme`), `en_attente_paiement → annulee`,
`en_attente_coursier → en_cours` (reprise FIFO). La boucle se ferme sans
inventer d'état.

**Niveau `Livraison` : aucune transition nouvelle.** Une livraison en cours de
réassignation reste `assignee` avec `coursier_id = NULL` — sémantique **déjà
documentée** par la migration du cycle 006 : « `coursier_id` est POSÉ par DSP
(affectation) — NULL tant que non assignée ». L'index partiel
`livraison_coursier_active` reste juste : une livraison sans coursier n'y figure
pas.

**Conséquence de test (SC-013).** Deux lignes = deux tests d'intégration de
transition, plus les refus symétriques (`en_cours → en_attente_paiement` doit
rester refusé : on ne remet pas une course en paiement une fois lancée).

---

## 4. Paramètres de zone — 18 créés, 3 réutilisés

Seeds dans **`backend/seeds/70_dispatch_parametres.sql`**, rejouable
(`ON CONFLICT … DO UPDATE`), aucun événement (un seed n'est pas une transition).

### Niveau PAYS (Côte d'Ivoire) — règles qui ne dépendent pas du marché local

| Clé | Défaut | FR | Pourquoi ce niveau |
|---|---|---|---|
| `dispatch.pool_ttl_s` | `90` | FR-003 | trois périodes de position manquées ; dérive d'une constante nationale |
| `dispatch.timer_offre_s` | `40` | FR-033 | temps de décision humain, pas un choix de ville |
| `dispatch.verrou_offre_s` | `45` | FR-045 | **doit** rester > `timer_offre_s` (vérifié au chargement) |
| `dispatch.timeouts_francs_par_jour` | `3` | FR-052 | politique d'équité nationale |
| `dispatch.acceptation_fenetre_jours` | `7` | FR-038 | fenêtre de mesure, pas un réglage de marché |
| `dispatch.note_composante_neutre_millimes` | `500` | FR-037 | « neutre » est une définition, pas un curseur |
| `dispatch.reassignation_deplacement_min_m` | `150` | FR-071 | bruit GPS = physique, non négociable par ville |

### Niveau VILLE (Tiassalé) — choix de marché

| Clé | Défaut | FR | Pourquoi ce niveau |
|---|---|---|---|
| `dispatch.rayon_m` | `4000` | FR-021 | Récapitulatif des paramètres de zone |
| `dispatch.grille_avance_par_note` | `[{"note_max_centiemes":400,"plafond_unites":5000},{"note_max_centiemes":450,"plafond_unites":10000},{"note_max_centiemes":null,"plafond_unites":15000}]` | FR-023 | grille ADM-04 ; **un seul** paramètre, comme `transport.actifs` |
| `dispatch.poids_proximite` | `40` | FR-034 | pondération en centièmes (R6) |
| `dispatch.poids_inactivite` | `30` | FR-034 | |
| `dispatch.poids_note` | `20` | FR-034 | |
| `dispatch.poids_acceptation` | `10` | FR-034 | somme = 100, vérifiée au chargement |
| `dispatch.inactivite_plafond_s` | `1800` | FR-036 | dépend de la densité de coursiers |
| `dispatch.broadcast_apres_candidats` | `3` | FR-058 | Récapitulatif |
| `dispatch.broadcast_apres_s` | `120` | FR-058 | Récapitulatif |
| `dispatch.reassignation_sans_mouvement_s` | `300` | FR-071 | Récapitulatif (« sans mouvement : 5 min ») |
| `dispatch.reassignation_sans_scan_marge_s` | `600` | FR-072 | Récapitulatif (« prépa + 10 min ») |

### Réutilisés — jamais dupliqués (constitution I)

| Clé | Valeur seedée | Propriétaire | Usage ici |
|---|---|---|---|
| `suivi.position_periode_s` | `30` (pays) | cycle 008 | période de publication ; `pool_ttl_s` en dérive |
| `commande.escalade_attente_coursier_s` | `300` (ville) | cycle 008 | seuil d'escalade DSP-06 (R14) |
| `transport.actifs` | `["a_pied","velo","moto"]` (ville) | cycle 002 | référentiel des capacités actives |

Devise : résolue par `ConfigurationZones::devise`, jamais écrite en dur.

---

## 5. Entités du domaine (crate `dispatch`)

Types purs, sans I/O. Les montants sont des `i64` en unités mineures + `String`
ISO 4217 (constitution III) ; les scores et distances des entiers (R6).

| Type | Rôle |
|---|---|
| `InscriptionPool { coursier, zone, lat, lon, statut, capacites: Vec<Capacite>, note_centiemes: Option<i32>, plafond_unites: i64, devise, course_active: Option<Uuid>, age_s }` | ce que le pool sait d'un coursier |
| `Capacite { famille: String, valeur: String }` | exigence **générique** (MVP : `transport`) |
| `Candidat { coursier, composantes: Composantes, score: i32, rang: u16 }` | un éligible classé |
| `Composantes { proximite: i32, inactivite: i32, note: i32, acceptation: i32 }` | millièmes, avant pondération |
| `EcartEligibilite { coursier, motifs: Vec<MotifEcart> }` | pourquoi un coursier est écarté — **la liste**, pas le premier motif : FR-026 en dépend |
| `Evaluation { candidats, ecarts, degraded, mesure_par: MesureProximite }` | résultat d'un passage de pipeline |
| `MesureProximite { Duree, Distance }` | ETA routière ou distance (FR-035) |
| `Offre { id, commande, coursier, mode, rang, score, montant_a_avancer, devise, emise_le, echeance_le, issue }` | image de la ligne `dispatch.offre` |
| `IssueOffre { EnVol, Acceptee, Refusee, NonRepondue, DejaPrise, Annulee }` | `DejaPrise` n'est **pas** un refus |
| `DecisionPipeline { OffreEmise(Offre), BroadcastOuvert{..}, BasculePrepaiement{..}, MiseEnFile{..}, RienAFaire }` | ce qu'un passage a décidé — un seul point de sortie, donc un seul endroit à tester |
| `Reprise { livraison, coursier_retire, motif }` | réassignation décidée |

---

## 6. Ports (traits) — offerts et consommés

### Offerts par `dispatch`

| Trait | Consommateur prévu | Signature essentielle |
|---|---|---|
| `PoolCoursiers` | `api` (Redis), tests (`MemoirePool`) | `publier(InscriptionPool, ttl)`, `retirer(coursier)`, `dans_rayon(zone, lat, lon, rayon_m) -> Vec<Uuid>`, `etat(coursier) -> Option<InscriptionPool>`, `elaguer(zone)` |
| `VerrouOffre` | `api` (Lua), tests | `poser(commande, coursier, jeton, ttl) -> PoseVerrou`, `liberer(commande, coursier, jeton)` |

`PoseVerrou { Obtenu, CommandeDejaOfferte, CoursierDejaPorteur }` — trois issues
distinctes, parce que les deux refus ne conduisent pas au même comportement
(FR-057 : passer au candidat suivant vs abandonner ce passage).

### Consommés par `dispatch`

| Trait | Implémenté par | Double de test | Pourquoi un port |
|---|---|---|---|
| `ConfigurationZones` (existant) | `zones::PgZones` | — | paramètres hérités |
| `CommandesADispatcher` (existant, **étendu**) | `commandes::PgCommandes` | — | file FIFO, affectation, + `course_active`, `fin_derniere_course`, `arrets_collectes`, `capacites_requises`, `preparation_s` |
| `EtatCoursier` (**nouveau**) | `comptes::PgComptes` | `CoursierFixe` | rôle valide, compte non bloqué, véhicules déclarés — DSP ne cite jamais `comptes.*` |
| `NotePrestataire` (**nouveau**) | *personne* (AVI) | `NoteAbsente` | R7 |
| `PairesBloquees` (**nouveau**) | *personne* (CRS-07) | `PairesSimulees` | R8 |
| `ProximiteRoutiere` (**nouveau**) | `api`, au-dessus de `tarification::routage::matrice_ou_degrade` | `ProximiteFixe` | R5 — une matrice par évaluation, jamais un appel par candidat |
| `NotificationsDispatch` (**nouveau**) | *personne* (NTF-01) | `NotificationsCollectees` | FR-094 — le **contrat d'émission** : trois destinataires (coursier, cliente, exploitation), trois canaux, des clés i18n et **aucun** transport. NTF-01 s'y branche sans changer le contrat ; d'ici là l'app **va chercher** son offre |

**Aucune dépendance inverse.** `commandes` ne dépendra jamais de `dispatch`
(R19) — c'est pourquoi le contrat vit dans `commandes::ports` depuis le cycle 008.

---

## 7. Événements outbox — 12 nouveaux, 1 amendé

À **déclarer dans `docs/taxonomie-evenements.md` avant implémentation**
(constitution VI). Minimisation ARTCI : aucune coordonnée, aucun numéro, aucun
nom ; distances **arrondies en mètres**, montants entiers + devise (FR-088).

| Type | `entite_type` | `entite_id` | Payload spécifique |
|---|---|---|---|
| `coursier.disponibilite_changee` | `coursier` | `compte.id` | `zone`, `en_ligne` (bool), `capacites` (slugs), `motif` (`manuel` \| `ttl_expire`) |
| `coursier.plafond_jour_declare` | `coursier` | `compte.id` | `zone`, `plafond_declare_unites`, `plafond_retenu_unites`, `devise`, `palier_note` |
| `dispatch.evaluation_faite` | `commande` | `commande.id` | `zone`, `nb_eligibles`, `nb_ecartes`, `motifs` (objet motif→compte), `degraded`, `mesure` (`duree` \| `distance`) |
| `dispatch.offre_emise` | `offre` | `offre.id` | `commande`, `coursier`, `mode`, `rang`, `score`, `montant_a_avancer`, `devise`, `timer_s` |
| `dispatch.offre_acceptee` | `offre` | `offre.id` | `commande`, `coursier`, `livraison`, `delai_reponse_s` |
| `dispatch.offre_refusee` | `offre` | `offre.id` | `commande`, `coursier`, `delai_reponse_s` |
| `dispatch.offre_non_repondue` | `offre` | `offre.id` | `commande`, `coursier`, `franche` (bool), `rang_du_jour` |
| `dispatch.offre_deja_prise` | `offre` | `offre.id` | `commande`, `coursier` — **sans pénalité**, le coursier reste dans le pool |
| `dispatch.broadcast_ouvert` | `commande` | `commande.id` | `zone`, `nb_destinataires`, `cause` (`candidats_epuises` \| `delai`) |
| `dispatch.bascule_prepaiement` | `commande` | `commande.id` | `zone`, `montant_a_avancer`, `plafond_max_constate`, `devise` |
| `dispatch.reassignation` | `livraison` | `livraison.id` | `commande`, `coursier_retire`, `motif`, `distance_m` (arrondie), `stagnation_s` |
| `dispatch.course_bloquee_escaladee` | `livraison` | `livraison.id` | `commande`, `coursier`, `motif`, `nb_arrets_collectes` — **jamais** de reprise automatique (FR-075) |

**Amendé** : `commande.attente_coursier_escaladee` gagne `chemin`
(`file` \| `pipeline`). Son `NOT EXISTS` sur l'outbox **reste** le marqueur
d'idempotence — c'est lui qui livre « exactement une alerte par commande, quel que
soit le chemin » (FR-066, R14) sans colonne supplémentaire.

**Déjà émis par `commandes`, non redéfinis** : `commande.prete_a_dispatcher`
(désormais **consommé**), `commande.mise_en_attente_coursier`,
`commande.assignee`, `livraison.affectee`, `commande.paiement_requis`.

**Le classement détaillé ne va pas dans l'outbox** : `dispatch.evaluation_faite`
en porte l'agrégat, et le détail par candidat (composantes, score, rang) part dans
les **logs structurés** avec l'identifiant de corrélation (constitution VII).
Émettre le vivier complet à chaque relance gonflerait l'outbox sans servir de KPI.

**Métriques (MET-01).** Tous les événements ci-dessus sont des événements
d'**opérations** (dérivés de l'outbox), sauf `coursier.disponibilite_changee` et
`coursier.plafond_jour_declare`, qui sont des événements **produit** (action
délibérée de Yao dans l'app). KPIs directement dérivables : délai
création → assignation, taux de refus, taux de non-réponse, part de broadcasts,
taux d'escalade, taux de réassignation, part de dégradé routier.

---

## 8. Invariants à tester (traçabilité vers les SC)

| Invariant | Où il est garanti | SC |
|---|---|---|
| Jamais deux coursiers sur une commande | `FOR UPDATE` + table fermée (R4) **et** `offre_en_vol_par_commande` | SC-001 |
| Jamais deux offres à un coursier | Lua tout-ou-rien (R3) **et** `offre_en_vol_par_coursier` | SC-014 |
| Un muet ne reçoit rien | TTL du hash + confirmation Postgres | SC-003 |
| Perte du pool sans perte métier | rien de métier en Redis + échéances persistées | SC-004 |
| Verrou > compte à rebours | vérifié au chargement des paramètres | SC-005 |
| Une seule escalade par commande | `NOT EXISTS` sur l'outbox | SC-006 |
| Équité | composante d'inactivité + `inactivite_plafond_s` | SC-007 |
| Aucun paramètre en dur | 18 clés de zone | SC-008 |
| 3 non-réponses franches | `offre.franche` + `timeouts_francs_par_jour` | SC-009 |
| Pas de reprise après collecte | `EXISTS (arret collecté)` → escalade | SC-010 |
| Aucune coordonnée en événement | revue de charge utile + test dédié | SC-011 |
| Bascule prépaiement sans paiement partiel | motif unique `[CapaciteAvance]` + un seul montant | SC-012 |
| Un coursier qui se rapproche n'est pas repris | `distance_min_m` + seuil de zone | SC-015 |
