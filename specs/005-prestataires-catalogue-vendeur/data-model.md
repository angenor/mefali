# Data Model — Prestataires agréés et catalogue vendeur (cycle 005)

**Branch**: `005-prestataires-catalogue-vendeur` | **Date**: 2026-07-18

Migration : `backend/migrations/0004_prestataires.sql` — nouveau schéma Postgres
`prestataires` (un schéma par module, tables toujours qualifiées, pas de
`search_path` — précédent 0002/0003). Après ajout : `cargo build -p api --bin api`
(migrations embarquées) puis `cargo sqlx prepare`.

## 1. Vue d'ensemble

```
zones.zone (ville) ◄──── prestataires.prestataire ────► zones.categorie
                              │  (statut, plaque, plan)
        ┌─────────────────────┼──────────────────────────────┐
        │                     │                              │
  charte_signee (0..n)   site (1..n, MVP 1)          rattachement_compte (0..n)
  photo_prestataire           │  (GPS, statut boutique)      │ ──► comptes.compte
        │               horaire_site (0..n plages)           │     (rôle vendeur, cycle 003)
        │                     │
   [Garage S3]          disponibilite_article ◄──── article ◄──── vendeur (extension 1:0..1)
                              │                        │              │
                     signalement_rupture          prix_fige        plan / plan_caracteristique
                     (fenêtre glissante)         (CMD-03 à venir)  (PROVISION VND-07)
```

Le prestataire est l'entité générale ; `vendeur` est l'extension MVP qui porte le
catalogue. La position GPS, les horaires, le statut de boutique et la
disponibilité des articles sont portés par le SITE, jamais par le prestataire
(FR-018). Aucune table de ce schéma ne référence le tronc commande.

## 2. Types énumérés

```sql
CREATE TYPE prestataires.statut_prestataire AS ENUM ('prospect', 'agree', 'suspendu');
CREATE TYPE prestataires.statut_boutique    AS ENUM ('ouvert', 'ferme', 'ferme_journee', 'en_pause');
CREATE TYPE prestataires.source_bascule     AS ENUM ('vendeur', 'coursier', 'admin');
```

## 3. Tables

### 3.1 `prestataires.plan` et `prestataires.plan_caracteristique` — PROVISION VND-07

```sql
CREATE TABLE prestataires.plan (
    id       uuid PRIMARY KEY,
    code     text NOT NULL UNIQUE,          -- 'gratuit'
    nom_cle  text NOT NULL,                 -- clé i18n
    cree_le  timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE prestataires.plan_caracteristique (
    plan_id  uuid NOT NULL REFERENCES prestataires.plan(id) ON DELETE CASCADE,
    cle      text NOT NULL,
    valeur   jsonb NOT NULL,
    PRIMARY KEY (plan_id, cle)
);
```

Tables UNIQUEMENT : aucune UI, aucune logique ne les lit ni ne les écrit au MVP
(FR-048). Seed : un plan `gratuit`, aucune caractéristique.

### 3.2 `prestataires.prestataire`

```sql
CREATE TABLE prestataires.prestataire (
    id                      uuid PRIMARY KEY,                  -- UUIDv7
    nom                     text NOT NULL,
    categorie_id            uuid NOT NULL REFERENCES zones.categorie(id) ON DELETE RESTRICT,
    ville_id                uuid NOT NULL REFERENCES zones.zone(id)      ON DELETE RESTRICT,
    contact_telephone       text NOT NULL,                     -- servi UNIQUEMENT à l'admin
    delai_preparation_min   integer NOT NULL CHECK (delai_preparation_min >= 0),
    statut                  prestataires.statut_prestataire NOT NULL DEFAULT 'prospect',
    statut_decide_par       uuid REFERENCES comptes.compte(id) ON DELETE RESTRICT,
    statut_decide_le        timestamptz,
    statut_motif            text,                              -- REQUIS pour la suspension
    jeton_plaque            text UNIQUE,                       -- NULL avant agrément, STABLE ensuite
    code_secours            text CHECK (code_secours ~ '^[0-9]{4}$'),  -- idem ; non unique (FR-014)
    plan_id                 uuid NOT NULL REFERENCES prestataires.plan(id) ON DELETE RESTRICT,
    cree_le                 timestamptz NOT NULL DEFAULT now(),
    modifie_le              timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT plaque_complete CHECK ((jeton_plaque IS NULL) = (code_secours IS NULL))
);
CREATE INDEX idx_prestataire_comptage
    ON prestataires.prestataire (ville_id, categorie_id) WHERE statut = 'agree';
```

- `ville_id` DOIT être une zone de type `ville` — vérifié en code à la création et
  à la correction (FR-002) ; toute autre profondeur est refusée.
- Journal de la dernière décision dans les colonnes `statut_*` ; l'historique
  complet vit dans les événements (précédent `attribution_role`, pas de table
  d'audit parallèle).
- `jeton_plaque`/`code_secours` posés à l'AGRÉMENT (premier passage à `agree`),
  jamais modifiés ensuite — la suspension ne les touche pas (SC-003, research R2).

### 3.3 `prestataires.photo_prestataire`

```sql
CREATE TABLE prestataires.photo_prestataire (
    id              uuid PRIMARY KEY,
    prestataire_id  uuid NOT NULL REFERENCES prestataires.prestataire(id) ON DELETE CASCADE,
    cle_objet       text NOT NULL,          -- prestataires/fiches/{prestataire_id}/{uuidv7}
    position        integer NOT NULL DEFAULT 0,
    cree_le         timestamptz NOT NULL DEFAULT now()
);
```

Clé S3 toujours NEUVE au dépôt ; l'objet déréférencé est supprimé APRÈS commit
(patron `supprimer_objet_orphelin` du cycle 003). Purge à la suppression de la
photo ou de la fiche (FR-026) — aucune purge périodique.

### 3.4 `prestataires.charte_signee`

```sql
CREATE TABLE prestataires.charte_signee (
    id              uuid PRIMARY KEY,
    prestataire_id  uuid NOT NULL REFERENCES prestataires.prestataire(id) ON DELETE RESTRICT,
    cle_objet       text NOT NULL,          -- prestataires/chartes/{prestataire_id}/{uuidv7}
    version_charte  text NOT NULL,          -- version en vigueur À LA SIGNATURE
    signee_le       date NOT NULL,
    deposee_le      timestamptz NOT NULL DEFAULT now()
);
```

0..n par prestataire (une re-signature n'écrase jamais) ; l'agrément exige AU
MOINS une charte (FR-003, FR-005). Un changement de version de charte n'invalide
aucun agrément existant — aucune logique ne recompare les versions. Pièce
contractuelle conservée tant que dure la relation, puis
`charte.conservation_post_relation_annees` (zone, seed 5 ans) ; lecture admin
seulement, par URL présignée.

### 3.5 `prestataires.site` et `prestataires.horaire_site`

```sql
CREATE TABLE prestataires.site (
    id                uuid PRIMARY KEY,
    prestataire_id    uuid NOT NULL REFERENCES prestataires.prestataire(id) ON DELETE CASCADE,
    position_lat      double precision NOT NULL,
    position_lng      double precision NOT NULL,
    statut_boutique   prestataires.statut_boutique NOT NULL DEFAULT 'ouvert',
    pause_fin         timestamptz,            -- échéance quand statut = en_pause
    ferme_journee_le  date,                   -- date locale couverte quand statut = ferme_journee
    statut_change_par uuid REFERENCES comptes.compte(id) ON DELETE RESTRICT,
    statut_change_le  timestamptz,
    cree_le           timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pause_coherente CHECK (statut_boutique <> 'en_pause' OR pause_fin IS NOT NULL),
    CONSTRAINT journee_coherente CHECK (statut_boutique <> 'ferme_journee' OR ferme_journee_le IS NOT NULL)
);
CREATE TABLE prestataires.horaire_site (
    site_id  uuid NOT NULL REFERENCES prestataires.site(id) ON DELETE CASCADE,
    jour     smallint NOT NULL CHECK (jour BETWEEN 0 AND 6),   -- 0 = lundi
    debut    time NOT NULL,
    fin      time NOT NULL,
    PRIMARY KEY (site_id, jour, debut),
    CHECK (debut < fin)
);
```

- Modèle 1..n sites (provision VND-06) ; exactement UN site créé au MVP, aucune
  sélection de site proposée nulle part (FR-019). L'API admin manipule « le »
  site comme ressource singulière.
- Plusieurs plages par jour ; jour sans plage = jour de fermeture (FR-031).
  Heures interprétées dans le fuseau de la zone (`zone.fuseau_horaire`, research
  R8). Mise à jour des horaires = remplacement complet des lignes du site.
- Les coordonnées ne sortent JAMAIS par la consultation publique (SC-013).

### 3.6 `prestataires.rattachement_compte`

```sql
CREATE TABLE prestataires.rattachement_compte (
    prestataire_id  uuid NOT NULL REFERENCES prestataires.prestataire(id) ON DELETE CASCADE,
    compte_id       uuid NOT NULL REFERENCES comptes.compte(id)           ON DELETE CASCADE,
    rattache_par    uuid NOT NULL REFERENCES comptes.compte(id)           ON DELETE RESTRICT,
    rattache_le     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (prestataire_id, compte_id)
);
```

Lien optionnel et multiple dans les DEUX sens (Tantie Affoué : zéro compte ; le
patron et son gérant : deux comptes ; un gérant multi-boutiques : deux
prestataires). Le rattachement N'EST ACCEPTÉ que sur un prestataire à l'état
`agree` (FR-007 « à un prestataire agréé » — l'agrément vaut validation ; refus
409 sinon, aucun rôle attribué — analyse A1) et attribue le rôle vendeur si
absent (research R11) ; le détachement, possible à tout état, ne touche jamais
au rôle. Les capacités vendeur DÉRIVENT de
`rattachement EXISTS ∧ prestataire.statut = 'agree'` — jamais stockées.

### 3.7 `prestataires.vendeur` — extension de spécialisation

```sql
CREATE TABLE prestataires.vendeur (
    prestataire_id  uuid PRIMARY KEY REFERENCES prestataires.prestataire(id) ON DELETE CASCADE
);
```

Créée avec le prestataire au MVP (toutes les catégories de lancement vendent).
Un prestataire de phase N (plombier) n'aura PAS de ligne ici — et aucune règle du
tronc n'en suppose une (FR-001, research R14).

### 3.8 `prestataires.article`

```sql
CREATE TABLE prestataires.article (
    id                 uuid PRIMARY KEY,
    vendeur_id         uuid NOT NULL REFERENCES prestataires.vendeur(prestataire_id) ON DELETE CASCADE,
    nom                text NOT NULL,
    prix_unites        bigint NOT NULL CHECK (prix_unites >= 0),   -- unités mineures, JAMAIS de float
    devise             text NOT NULL,                              -- ISO 4217, posée par le serveur (zone)
    prix_barre_unites  bigint,
    photo_cle          text,                 -- prestataires/articles/{article_id}/{uuidv7}
    categorie_interne  text,                 -- étiquette LIBRE d'affichage (FR-021), lue par aucune règle
    retire_le          timestamptz,          -- NULL = au catalogue ; retrait RÉVERSIBLE (FR-055)
    cree_le            timestamptz NOT NULL DEFAULT now(),
    modifie_le         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT prix_barre_strictement_superieur
        CHECK (prix_barre_unites IS NULL OR prix_barre_unites > prix_unites)
);
CREATE INDEX idx_article_catalogue ON prestataires.article (vendeur_id) WHERE retire_le IS NULL;
```

- La contrainte `prix_barre_strictement_superieur` porte FR-023/SC-006 au niveau
  du schéma : refus par TOUT chemin d'écriture, y compris futurs.
- Retrait = `retire_le` posé (suppression logique, patron des adresses du cycle
  003) : l'article cesse d'être servi et commandable, la ligne subsiste pour les
  commandes passées et les agrégats, remise = `retire_le = NULL` (FR-055).
  Un article retiré ne peut recevoir AUCUN signalement.
- Rupture ≠ retrait : la rupture est un état de STOCK porté par site (§3.9).

### 3.9 `prestataires.disponibilite_article`

```sql
CREATE TABLE prestataires.disponibilite_article (
    article_id   uuid NOT NULL REFERENCES prestataires.article(id) ON DELETE CASCADE,
    site_id      uuid NOT NULL REFERENCES prestataires.site(id)    ON DELETE CASCADE,
    disponible   boolean NOT NULL DEFAULT true,
    source       prestataires.source_bascule,                      -- dernière bascule (FR-037)
    bascule_par  uuid REFERENCES comptes.compte(id) ON DELETE RESTRICT,  -- NULL si masquage automatique
    bascule_le   timestamptz,
    PRIMARY KEY (article_id, site_id)
);
```

- Une ligne créée par article × site à la création de l'article (`disponible =
  true` — FR : « disponible par défaut »). MVP : une seule ligne (site unique).
- Garde FR-041 : `source = 'admin' AND disponible = false` → seule une bascule de
  source `admin` peut remettre en vente.

### 3.10 `prestataires.signalement_rupture`

```sql
CREATE TABLE prestataires.signalement_rupture (
    id                   uuid PRIMARY KEY,       -- UUID GÉNÉRÉ CÔTÉ CLIENT (idempotence FR-039)
    article_id           uuid NOT NULL REFERENCES prestataires.article(id) ON DELETE CASCADE,
    site_id              uuid NOT NULL REFERENCES prestataires.site(id)    ON DELETE CASCADE,
    coursier_compte_id   uuid NOT NULL REFERENCES comptes.compte(id)       ON DELETE RESTRICT,
    commande_id          uuid,                   -- PROVISION sans FK (module commandes à venir,
                                                 -- patron livraison_origine du cycle 003)
    horodatage_local     timestamptz NOT NULL,   -- horloge de l'appareil (file hors-ligne)
    recu_le              timestamptz NOT NULL DEFAULT now()   -- la fenêtre glissante compte sur recu_le
);
CREATE INDEX idx_signalement_fenetre ON prestataires.signalement_rupture (article_id, recu_le);
```

Rejeu : `INSERT … ON CONFLICT (id) DO NOTHING` — un même identifiant ne compte
jamais deux fois (FR-039). Masquage automatique évalué à l'écriture (research
R10) : `count(DISTINCT coursier_compte_id)` sur la fenêtre ≥ seuil → bascule.
Les signalements restent comptés après une remise en vente (FR-041).

### 3.11 `prestataires.prix_fige`

```sql
CREATE TABLE prestataires.prix_fige (
    id                 uuid PRIMARY KEY,        -- UUIDv7
    article_id         uuid NOT NULL REFERENCES prestataires.article(id) ON DELETE RESTRICT,
    prix_unites        bigint NOT NULL CHECK (prix_unites >= 0),
    devise             text NOT NULL,
    prix_barre_unites  bigint,                  -- informatif, copié tel quel
    reference_externe  uuid,                    -- PROVISION sans FK : la commande qui verrouille (CMD-03)
    fige_le            timestamptz NOT NULL DEFAULT now()
);
```

Écrit UNIQUEMENT par `PgPrestataires::figer_prix` (research R6). Un montant figé
ne bouge JAMAIS, quelle que soit la suite des modifications de prix (SC-005) —
aucun UPDATE n'existe sur cette table.

## 4. Machines à états

### 4.1 Cycle de vie du prestataire (FR-004)

| Depuis | Action (rôle admin) | Vers | Conditions | Effets même transaction |
|---|---|---|---|---|
| — | créer | `prospect` | ville de type `ville` | ligne + extension `vendeur` + événement `prestataire.cree` |
| `prospect` | agréer | `agree` | fiche complète (FR-002) ∧ ≥ 1 charte (FR-003) ∧ exactement 1 site avec position + ≥ 1 plage d'horaires (FR-005, FR-019) | plaque générée (1er passage), recalcul activation (R7), `prestataire.agree` |
| `agree` | suspendre | `suspendu` | motif REQUIS | recalcul (sans effet à la baisse), `prestataire.suspendu` |
| `suspendu` | rétablir | `agree` | — | plaque INCHANGÉE, recalcul activation, `prestataire.retabli` |

Toute autre transition est REFUSÉE (`prospect → suspendu`, `agree → prospect`,
etc.). Fonction pure `transition(statut, action) -> Option<Statut>` testée
exhaustivement (patron `role.rs` du cycle 003). Dérivations d'état — AUCUNE
cascade, AUCUNE écriture :
- fiche servie / commandable ⟸ `statut = 'agree'` (FR-004, FR-028) ;
- jeton de plaque valide ⟸ `statut = 'agree'` (FR-015) ;
- actions vendeur d'un compte rattaché autorisées ⟸ `statut = 'agree'` (FR-008).

### 4.2 Statut de boutique (site) — transitions DÉCIDÉES

| Action (vendeur rattaché ou admin) | Écrit | Événement |
|---|---|---|
| ouvrir | `ouvert`, `pause_fin/ferme_journee_le = NULL` | `site.statut_boutique_change` |
| fermer | `ferme` | idem |
| mettre en pause (durée) | `en_pause`, `pause_fin = now() + durée` | idem (payload porte `pause_fin`) |
| prolonger la pause | `pause_fin = max(pause_fin, now()) + durée` | idem |
| fermer pour la journée | `ferme_journee`, `ferme_journee_le = date locale` | idem |

Les ÉCHÉANCES (pause échue, journée passée) ne sont PAS des transitions : l'état
effectif les absorbe à la lecture, AUCUN événement (FR-033, FR-036, research R3).
L'échéance ne force jamais l'ouverture contre les horaires. Un changement
d'horaires pendant une pause ne touche pas la pause (edge case de la spec).

### 4.3 État effectif et commandabilité (dérivés purs)

```
etat_effectif  = fermé si ¬agréé
               sinon fermé si maintenant ∉ horaires(jour)          -- prime sur tout statut
               sinon fermé si en_pause ∧ maintenant < pause_fin
               sinon fermé si ferme_journee ∧ aujourd'hui ≤ ferme_journee_le
               sinon fermé si statut = ferme
               sinon ouvert
commandable    = agréé ∧ categorie_active(ville, categorie) ∧ etat_effectif = ouvert   -- FR-028, SEULE définition
article cmd.   = commandable(prestataire) ∧ retire_le IS NULL ∧ disponible             -- SC-004
rappel_ouverture = statut = ferme ∧ maintenant ∈ horaires(jour)                        -- FR-035, research R4
```

## 5. Règles de validation (résumé opposable)

| Règle | Où elle est tenue |
|---|---|
| prix barré > prix courant | CHECK en base + validation API (message i18n) — FR-023 |
| montants entiers + devise de zone | colonnes `bigint` + `devise` posée serveur — FR-022, R13 |
| ville de rattachement de type `ville` | code (création + correction FR-056) — FR-002 |
| agrément ⟸ fiche + charte + 1 site complet | code, transaction d'agrément — FR-005 |
| motif requis pour suspendre | code (patron `motif_requis` du cycle 003) — FR-010 |
| signalement ⟸ coursier + commande active + article de la commande | port `CommandesActives` — FR-038, R5 |
| signalement idempotent | `ON CONFLICT (id) DO NOTHING` — FR-039 |
| remise en vente d'une rupture admin ⟸ admin | garde sur `source` — FR-041 |
| article retiré : ni servi, ni commandable, ni signalable | filtres `retire_le IS NULL` — FR-055 |
| aucune recherche par code de secours | aucun index, aucun endpoint — FR-014 |
| consultation publique sans contact/GPS/exploitation | DTO publics distincts des DTO admin — FR-027, SC-013 |

## 6. Événements outbox (18 types — à déclarer dans `docs/taxonomie-evenements.md` AVANT implémentation)

Tous écrits par `socle::ecrire_evenement` dans la MÊME transaction que la
mutation. Payloads : propriétés standard (`zone`, `categorie`, `role` quand
pertinents) + spécifiques ci-dessous. AUCUN nom, contact, ni GPS (FR-052,
SC-011) ; `acteur` est toujours un UUID de compte, `source` ∈ {vendeur, coursier,
admin}.

| Type | `entite_type` / `entite_id` | Payload spécifique |
|---|---|---|
| `prestataire.cree` | `prestataire` / id | `zone`, `categorie`, `acteur` |
| `prestataire.modifie` | `prestataire` / id | `champs` (noms seulement), `acteur` |
| `prestataire.agree` | `prestataire` / id | `zone`, `categorie`, `plaque_creee` (bool), `acteur` |
| `prestataire.suspendu` | `prestataire` / id | `zone`, `categorie`, `motif`, `acteur` |
| `prestataire.retabli` | `prestataire` / id | `zone`, `categorie`, `acteur` |
| `prestataire.corrige` | `prestataire` / id | `avant`/`apres` = {`categorie`, `zone`}, `acteur` — FR-056 |
| `charte.deposee` | `charte_signee` / id | `prestataire`, `version_charte`, `acteur` |
| `rattachement.cree` | `rattachement` / compte_id | `prestataire`, `compte`, `role_attribue` (bool), `acteur` |
| `rattachement.supprime` | `rattachement` / compte_id | `prestataire`, `compte`, `acteur` |
| `site.statut_boutique_change` | `site` / id | `prestataire`, `avant`, `apres`, `pause_fin?`, `source` (vendeur\|admin), `acteur` |
| `site.horaires_modifies` | `site` / id | `prestataire`, `avant`/`apres` (plages par jour), `source`, `acteur` |
| `article.cree` | `article` / id | `prestataire`, `prix`, `devise`, `prix_barre?`, `source`, `acteur` |
| `article.modifie` | `article` / id | `prestataire`, `champs`, `prix?`, `prix_barre?`, `source`, `acteur` |
| `article.retire_du_catalogue` | `article` / id | `prestataire`, `source`, `acteur` — FR-055 |
| `article.remis_au_catalogue` | `article` / id | `prestataire`, `source`, `acteur` — FR-055 |
| `article.mis_en_rupture` | `article` / id | `prestataire`, `site`, `source`, `automatique` (bool), `acteur?` — FR-043 |
| `article.remis_en_vente` | `article` / id | `prestataire`, `site`, `source`, `acteur` — consommé par VND-09 (T4) |
| `signalement_rupture.recu` | `signalement_rupture` / id | `prestataire`, `article`, `site`, `coursier`, `deja_en_rupture` (bool) |

N'émettent RIEN : les échéances (pause, journée — research R3), les seeds
(FR-054), les rejeux idempotents, les signalements REFUSÉS (FR-038 : « n'est
compté nulle part »), le dépôt de photo seul (couvert par
`prestataire.modifie`/`article.modifie`), `figer_prix` (les événements de
commande du cycle CMD couvriront le verrouillage).

**Taxonomie produit MET-01** (déclaration SEULE, aucune émission ce cycle —
research R16) : `vendeur_boutique_bascule`, `vendeur_pause_demarree`,
`vendeur_pause_prolongee`, `vendeur_article_bascule_dispo`,
`vendeur_article_cree`, `vendeur_prix_modifie`.

## 7. Paramètres de zone (héritage ZON-01 — le Récapitulatif fait foi)

| Clé | Type / valeurs | Seed | Usage |
|---|---|---|---|
| `rupture.masquage_seuil` | entier ≥ 1 | 2 | coursiers DISTINCTS requis — FR-040 |
| `rupture.masquage_fenetre_jours` | entier ≥ 1 | 7 | fenêtre glissante sur `recu_le` — FR-040 |
| `categorie.<slug>.affichage_rupture` | `"grise"` \| `"masque"` | `"grise"` ×6 | appliqué + servi par la consultation — FR-042, FR-050, R8 |
| `charte.conservation_post_relation_annees` | entier ≥ 0 | 5 | rétention post-relation — FR-026 |
| `zone.fuseau_horaire` | IANA tz | `"Africa/Abidjan"` | interprétation des horaires — R8 |

Le validateur `zones/src/parametre.rs` est étendu : `affichage_rupture` accepté
dans `categorie.<slug>.*` (valeurs énumérées) ; namespaces `rupture.*`,
`charte.*`, `zone.*` validés par type. Rien de tout cela n'entre dans `/config`.

## 8. Stockage objet (Garage S3 — port `socle::DepotObjets`, reprise R1)

| Usage | Clé | MIME | Lecture |
|---|---|---|---|
| Photos de fiche | `prestataires/fiches/{prestataire_id}/{uuidv7}` | jpeg/png/webp | présignée TTL 10 min, publique via consultation |
| Photos d'articles | `prestataires/articles/{article_id}/{uuidv7}` | jpeg/png/webp | idem |
| Charte signée | `prestataires/chartes/{prestataire_id}/{uuidv7}` | jpeg/png/webp/pdf | présignée, rôle ADMIN uniquement |

Dépôt = clé neuve, jamais d'écrasement ; remplacement → l'ancienne clé est
supprimée APRÈS commit (patron cycle 003). Purge des photos à la suppression de
l'objet porté ; AUCUNE purge périodique (FR-026).

## 9. Seeds (`backend/seeds/` — rejouables, AUCUN événement, FR-054, research R15)

- `10_zones_tiassale.sql` (complété) : les 5 clés de zone du §7.
- `30_prestataires.sql` : « Étal Tantie Affoué » (restauration, `agree`, AUCUN
  compte rattaché — cas nominal), « Boutique Kofi » (boutique_superette, `agree`,
  compte Kofi du seed 20 rattaché + rôle vendeur posé), un prospect complet
  (fiche + charte + site) prêt à agréer à la main. Sites, horaires 8 h–19 h
  lun–sam, jetons de plaque et codes de secours FIGÉS. Pose DIRECTEMENT
  `zones.activation_categorie.actif_auto = true` pour restauration et
  boutique_superette à Tiassalé (`ON CONFLICT … DO UPDATE SET actif_auto = true`).
- `35_articles.sql` : attiéké poisson 1 500, garba 1 000, jus de bissap 500
  (Tantie Affoué) ; quelques articles Kofi dont un en promotion (prix barré
  1 000 > prix 800) et un en rupture. Disponibilités posées par site.

Idempotence : UUID et horodatages LITTÉRAUX, `ON CONFLICT … DO UPDATE` ;
double exécution = état strictement identique, zéro événement, prestataires
commandables (SC-012).

## 10. Provisions de ce cycle (« prêt ≠ construit », principe IX)

| Provision | Matérialisation | Interdits |
|---|---|---|
| VND-06 multi-sites | `site` 1..n + disponibilité par site | aucune sélection de site, aucune UI, un seul site créé |
| VND-07 plans | `plan`, `plan_caracteristique`, FK `plan_id` (tous « gratuit ») | aucune règle ne lit/écrit le plan |
| Lien commandes | `signalement_rupture.commande_id`, `prix_fige.reference_externe` (sans FK) | aucune logique de commande |
| VND-05 / AVI notes | RIEN — aucune colonne inventée | — |
