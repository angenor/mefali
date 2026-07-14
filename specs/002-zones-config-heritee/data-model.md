# Data Model — Arbre de zones et configuration héritée (002)

Schéma Postgres dédié `zones` (constitution II — un schéma par module),
créé par la migration `backend/migrations/0002_zones.sql` (nouvelle
migration, jamais de modification de 0001 — constitution I). Identifiants et
commentaires en français, conventions du socle 001 (research R10).

## 1. Types énumérés

| Type | Valeurs | Usage |
|---|---|---|
| `zones.type_zone` | `pays`, `region`, `ville`, `commune`, `village`, `quartier` | ZON-01 — `village`/`quartier` = PROVISION (données seulement) |
| `zones.politique_photo` | `obligatoire`, `facultative`, `desactivee` | ZON-02 (cadrage §4) |
| `zones.forcage_categorie` | `automatique`, `force_actif`, `force_inactif` | clarification « forçage à trois états » |

## 2. Tables

### `zones.zone` — l'arbre (FR-001..004)

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `id` | uuid | PK | UUIDv7 côté backend ; UUID fixes pour les seeds |
| `parent_id` | uuid | FK → `zones.zone(id)` ON DELETE RESTRICT, NULL = racine | index `idx_zone_parent` |
| `type` | `zones.type_zone` | NOT NULL | aucun ordre de types imposé (profondeur variable — spec, Assumptions) |
| `nom` | text | NOT NULL | nom administratif (pas une chaîne UI) |
| `cree_le`, `modifie_le` | timestamptz | NOT NULL DEFAULT now() | |

- **Anti-cycle (FR-002)** : double garde — validation applicative dans
  `PgZones` (erreur explicite) + trigger plpgsql `zone_sans_cycle` sur
  INSERT/UPDATE de `parent_id` (remonte la chaîne, RAISE EXCEPTION) —
  défense en profondeur, le re-parentage reste permis (edge case spec).
- **Suppression** : refusée si enfants ou références (RESTRICT partout).

### `zones.parametre_zone` — configuration locale partielle (FR-005, FR-009, FR-011 ; research R1)

| Colonne | Type | Contraintes |
|---|---|---|
| `zone_id` | uuid | FK → zone, ON DELETE RESTRICT |
| `cle` | text | namespacée (voir registre des clés §4) |
| `valeur` | jsonb | NOT NULL (un `false`/`""`/`0` est DÉFINI ; l'absence de ligne est l'absence) |
| `modifie_le` | timestamptz | NOT NULL DEFAULT now() |
| | | PK (`zone_id`, `cle`) |

### `zones.type_transport` — référentiel (FR-017)

| Colonne | Type | Contraintes |
|---|---|---|
| `id` | uuid | PK (UUID fixes au seed) |
| `slug` | text | UNIQUE — `a_pied`, `velo`, `moto`, `tricycle_taxi`, `tricycle_cargo`, `voiture`, `camionnette`, `camion` |
| `nom_cle` | text | clé i18n fr (`transport.<slug>.nom`) — aucune chaîne UI en dur (constitution VII) |
| `ordre` | smallint | NOT NULL — tri d'affichage (à pied → camion) |

L'ACTIVATION par zone n'est pas ici : c'est le paramètre hérité
`transport.actifs` (liste de slugs, surcharge en bloc — research R1).

### `zones.categorie` — catégories par configuration (FR-012)

| Colonne | Type | Contraintes / Notes |
|---|---|---|
| `id` | uuid | PK (UUID fixes au seed) |
| `slug` | text | UNIQUE — `restauration`, `boutique_superette`, `marche`, `pharmacie`, `gaz`, `quincaillerie` |
| `nom_cle` | text | clé i18n fr (`categorie.<slug>.nom`) |
| `champs_fiche` | jsonb | NOT NULL DEFAULT `'[]'` — descripteur des champs de fiche vendeur (consommé par VND) |
| `politique_photo` | `zones.politique_photo` | NOT NULL DEFAULT `facultative` |
| `workflow_vendeur` | text | NOT NULL — clé opaque ce cycle, consommée par `ServiceWorkflow` (cycles CMD/VND) |
| `vehicule_minimal` | uuid | FK → `type_transport(id)`, NULL = sans exigence |
| `cree_le`, `modifie_le` | timestamptz | |

`seuil_activation` et `mixable` ne sont PAS des colonnes : ce sont des
paramètres de zone hérités (`categorie.<slug>.seuil_activation`,
`categorie.<slug>.mixable`) — une seule source de vérité (research R1,
constitution I).

### `zones.activation_categorie` — état par ville (FR-013..016 ; research R6)

| Colonne | Type | Contraintes / Notes |
|---|---|---|
| `id` | uuid | PK (surrogate — `entite_id` des événements outbox) |
| `zone_id` | uuid | FK → zone ; UNIQUE (`zone_id`, `categorie_id`) |
| `categorie_id` | uuid | FK → categorie |
| `forcage` | `zones.forcage_categorie` | NOT NULL DEFAULT `automatique` |
| `actif_auto` | boolean | NOT NULL DEFAULT false — dernier état calculé par la règle du seuil |
| `actif` | boolean | GENERATED ALWAYS AS (CASE `forcage` WHEN `force_actif` → true, `force_inactif` → false, sinon `actif_auto`) STORED — l'état EFFECTIF, une seule définition |
| `modifie_le` | timestamptz | NOT NULL DEFAULT now() |

## 3. Transitions d'état (tests d'intégration obligatoires — constitution VII)

### `actif_auto` (règle du seuil, `recalculer_activation`)

```
false ──(nb_vendeurs_agrees ≥ seuil résolu)──► true
true  ──(quoi qu'il arrive)────────────────► true   # JAMAIS de désactivation auto (FR-015)
```

- Seuil résolu par héritage à la ville ; seuil ABSENT → la règle ne fait
  rien (pas d'activation auto ; le forçage reste possible) — FR-009/R6.

### `forcage` (admin, endpoint unique du cycle)

```
automatique ◄──► force_actif
automatique ◄──► force_inactif
force_actif ◄──► force_inactif
```

Toute transition émet `categorie.forcage_change` ; si l'état EFFECTIF
(`actif`) change, `categorie.activation_changee` est émis EN PLUS — les deux
dans la MÊME transaction que l'UPDATE (constitution VI, via
`socle::ecrire_evenement`).

### Événements (registre à ajouter à `docs/taxonomie-evenements.md` — research R9)

| Type | `entite_type` / `entite_id` | Payload spécifique (+ propriétés standard `zone`, `role`) |
|---|---|---|
| `zone.parametre_modifie` | `zone` / id zone | `cle`, `avant` (null si création), `apres`, `acteur` |
| `categorie.forcage_change` | `activation_categorie` / id ligne | `zone`, `categorie` (slug), `avant`, `apres`, `acteur` |
| `categorie.activation_changee` | `activation_categorie` / id ligne | `zone`, `categorie` (slug), `avant`, `apres`, `origine` (`seuil` \| `forcage`), `nb_vendeurs` (si origine seuil), `seuil` |

## 4. Registre des clés de `parametre_zone` (ce cycle)

| Clé | Type JSON | Validée à l'écriture (`definir_parametre`) | Servie par `/config` |
|---|---|---|---|
| `devise.code` | string | ISO 4217, 3 lettres majuscules | oui (`devise`) |
| `devise.decimales` | number | entier 0..4 | oui (`devise`) |
| `drapeau.<cle>` | bool | booléen | oui (`drapeaux`) |
| `transport.actifs` | array<string> | slugs existants dans `type_transport` | oui (`transports_actifs`) |
| `categorie.<slug>.seuil_activation` | number | entier ≥ 1, slug existant | non (interne) |
| `categorie.<slug>.mixable` | bool | booléen, slug existant | oui (via `categories[].mixable`) |
| `texte.<cle>` | string | libre | oui (`textes`) |
| `client.<cle>` | tout | libre | oui (`parametres`) |
| autres namespaces (`dispatch.*`, …) | tout | libres (cycles futurs, FR-011) | NON — liste blanche R4 |

**Résolution (rappel R2)** : pour chaque clé, valeur de l'ancêtre le plus
proche qui possède la ligne, zone elle-même en tête ; `ConfigurationEffective`
mémorise la provenance (id de la zone définissante) pour chaque clé.

## 5. Structures Rust exposées (crate `zones`, consommées par les autres crates)

- `Zone { id, parent_id, type_zone, nom }`
- `Devise { code: String, decimales: u8 }` — jamais de float (constitution III)
- `ConfigurationEffective { zone: Uuid, valeurs: BTreeMap<String, ValeurProvenance> }`
  avec `ValeurProvenance { valeur: serde_json::Value, provenance: Uuid }`
- `CategorieActive { slug, nom_cle, mixable }`
- trait `ConfigurationZones` (lecture — signature exacte en research R2) ;
  écritures = méthodes inhérentes de `PgZones` : `creer_zone`,
  `definir_parametre`, `forcer_categorie`, `recalculer_activation`
  (toutes sur `&mut PgTransaction`, événements outbox inclus)
- `ErreurZones` (thiserror) : `ZoneInconnue`, `CycleDetecte`,
  `DeviseIrresolvable`, `CategorieInconnue`, `ValeurInvalide`, `Sql(...)`

## 6. Seeds — `backend/seeds/10_zones_tiassale.sql` (FR-022..026)

Rejouable : `INSERT … ON CONFLICT (id|PK) DO UPDATE` partout ; UUID FIXES
(déterminisme SC-008, bootstrap apps R7). Aucun événement outbox (chargement
initial — research R9).

| Donnée | Valeurs |
|---|---|
| Zone Côte d'Ivoire | `01900000-0000-7000-8000-000000000001`, type `pays`, racine |
| Zone Tiassalé | `01900000-0000-7000-8000-000000000002`, type `ville`, parent CI — **constante de bootstrap des apps** |
| Paramètres sur CI (hérités) | `devise.code = "XOF"`, `devise.decimales = 0` ; `categorie.<slug>.mixable` : `restauration=false`, les 5 « courses » `=true` (nature de catégorie → niveau pays) |
| Paramètres sur Tiassalé | `drapeau.livraison_offerte_mefali=true`, `drapeau.gratuite_commissions=true`, `drapeau.pluie=false` ; `transport.actifs=["a_pied","velo","moto"]` ; `categorie.<slug>.seuil_activation` : restauration 8, boutique_superette 3, marche 3, pharmacie 1, gaz 2, quincaillerie 2 (« par ville ») |
| `type_transport` | 8 lignes, UUID fixes `…-000000000201`→`…208`, ordre 1..8 |
| `categorie` | 6 lignes, UUID fixes `…-000000000101`→`…106` ; `politique_photo=facultative` (défaut sûr, éditable — cadrage §4) ; `workflow_vendeur` : restauration→`restauration`, boutique_superette/pharmacie/quincaillerie→`coursier_acheteur`, marche→`marche_etals`, gaz→`echange_contenant` (clés opaques ce cycle) ; `vehicule_minimal` : gaz→moto (cadrage §4), quincaillerie→NULL (« véhicule calculé par la commande »), autres NULL |
| `activation_categorie` | 6 lignes Tiassalé, `forcage=automatique`, `actif_auto=false` — l'état découle de la règle appliquée aux vendeurs en base : aucun vendeur au cycle ZON (le seed vendeurs du cycle VND appellera `recalculer_activation`) |

La démonstration de l'héritage est structurelle : devise et mixable au
niveau pays, drapeaux/seuils/transports au niveau ville — SC-003 vérifie la
résolution complète à Tiassalé en une consultation.
