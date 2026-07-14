# Data Model — Comptes, authentification OTP et rôles (cycle 003)

Migration : `backend/migrations/0003_comptes.sql` (les migrations 0001/0002 ne
sont jamais modifiées). Schéma Postgres dédié `comptes` (constitution II).
Identifiants : UUIDv7 générés applicativement (patron des cycles 001/002).
Toutes les chaînes destinées à l'UI sont des clés i18n (`*_cle`) ; les textes
saisis par l'utilisateur (libellé d'adresse, motif admin) sont du contenu, pas
des clés.

## 1. Types énumérés

```sql
CREATE SCHEMA comptes;

CREATE TYPE comptes.role AS ENUM ('client', 'coursier', 'vendeur', 'admin');

-- Une seule machine à états pour toutes les attributions (research R9).
CREATE TYPE comptes.statut_role AS ENUM ('en_attente', 'valide', 'refuse', 'suspendu');
```

## 2. Tables

### comptes.compte

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | uuid | PK | UUIDv7 |
| telephone_e164 | text | NOT NULL UNIQUE, CHECK `~ '^\+[1-9][0-9]{6,14}$'` | identité Mefali — AUCUNE donnée nominative (clarification « numéro seul ») |
| zone_id | uuid | NOT NULL REFERENCES zones.zone(id) | zone de rattachement (R13) |
| consentement_version | text | NOT NULL | version du texte ARTCI accepté (FR-006) |
| consentement_le | timestamptz | NOT NULL | horodatage du consentement |
| prepaiement_impose | boolean | NOT NULL DEFAULT false | **PROVISION CPT-06** — aucune logique ne la lit |
| bloque | boolean | NOT NULL DEFAULT false | **PROVISION CPT-06** — aucune logique ne la lit |
| cree_le | timestamptz | NOT NULL DEFAULT now() | |
| derniere_connexion_le | timestamptz | NULL | mise à jour à chaque vérification OTP réussie |

### comptes.session

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | uuid | PK | = claim `sid` du JWT |
| compte_id | uuid | NOT NULL REFERENCES comptes.compte(id) ON DELETE CASCADE | |
| refresh_hash | bytea | NOT NULL UNIQUE | SHA-256 du jeton opaque courant (R2) |
| refresh_precedent_hash | bytea | UNIQUE, NULL | hash du jeton précédent — détection de réutilisation (R2) |
| appareil_nom | text | NOT NULL | fourni par l'app (« Pixel 7 de poche ») |
| appareil_plateforme | text | NOT NULL CHECK IN ('android','ios') | |
| cree_le | timestamptz | NOT NULL DEFAULT now() | |
| derniere_activite_le | timestamptz | NOT NULL DEFAULT now() | mise à jour au rafraîchissement |
| revoquee_le | timestamptz | NULL | NULL = active ; la session n'expire JAMAIS d'elle-même (clarification) |

Index : `(compte_id) WHERE revoquee_le IS NULL` (liste des appareils actifs) ;
lookup par `refresh_hash`/`refresh_precedent_hash` via leurs UNIQUE.

### comptes.attribution_role

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| compte_id | uuid | NOT NULL REFERENCES comptes.compte(id) ON DELETE CASCADE | |
| role | comptes.role | NOT NULL | PK (compte_id, role) — 1..n rôles cumulables (FR-010) |
| statut | comptes.statut_role | NOT NULL | l'UNIQUE machine à états (R9) |
| motif | text | NULL | motif de la dernière décision admin (FR-014, FR-017) |
| decide_par | uuid | NULL REFERENCES comptes.compte(id) | admin décideur ; NULL = automatique (client à l'inscription) |
| decide_le | timestamptz | NULL | |
| demande_le | timestamptz | NOT NULL DEFAULT now() | |
| | | CHECK (role <> 'client' OR statut = 'valide') | le rôle client est toujours valide ce cycle |

### comptes.dossier_coursier

Contenu du dossier — le STATUT vit sur `attribution_role(compte_id,'coursier')`
(une seule source de vérité, R9). 1:1 avec le compte. Rejeu du POST de
soumission avec la même `Idempotency-Key` pendant `en_attente` → 200 état
courant (R14).

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| compte_id | uuid | PK REFERENCES comptes.compte(id) ON DELETE CASCADE | |
| piece_cle_objet | text | NOT NULL | clé S3 `comptes/pieces/{compte_id}/{uuidv7}` (R7) |
| piece_mime | text | NOT NULL | jpeg/png/webp/pdf, validé à l'upload |
| referent_nom | text | NOT NULL | référent local (« caution morale », §7.1) |
| referent_telephone_e164 | text | NOT NULL CHECK format E.164 | |
| soumis_le | timestamptz | NOT NULL DEFAULT now() | mis à jour à chaque re-soumission |

### comptes.vehicule_declare

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | uuid | PK | |
| compte_id | uuid | NOT NULL REFERENCES comptes.dossier_coursier(compte_id) ON DELETE CASCADE | |
| type_transport_id | uuid | NOT NULL REFERENCES zones.type_transport(id) ON DELETE RESTRICT | référentiel ZON-03 ; soumission par SLUG (source UI = `transport.actifs` de la config distante, analyze C2), résolu en id à la validation ; l'appartenance aux types ACTIFS de la zone est validée à la soumission (FR-015), pas par contrainte (un type désactivé ensuite reste déclaré — edge case de la spec) |
| | | UNIQUE (compte_id, type_transport_id) | |

### comptes.adresse

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| id | uuid | PK | = `Idempotency-Key` du POST (UUIDv7 client) — `ON CONFLICT DO NOTHING` + retour de l'existante, rejeu idempotent (R14) |
| compte_id | uuid | NOT NULL REFERENCES comptes.compte(id) ON DELETE CASCADE | |
| libelle | text | NOT NULL | « Maison », « Bureau » ou libre — contenu utilisateur |
| lat / lng | double precision | NOT NULL | pin GPS (§8.2) ; pas de PostGIS ce cycle |
| repere_texte | text | NULL | repère texte |
| repere_vocal_cle_objet | text | NULL | clé S3 `comptes/reperes/{compte_id}/{uuidv7}` ; NULL après purge (R8) |
| repere_vocal_duree_s | smallint | NULL | ≤ paramètre de zone `medias.note_vocale_duree_max_s` |
| zone_id | uuid | NOT NULL REFERENCES zones.zone(id) | |
| livraison_origine | uuid | NULL — **sans FK** | **PROVISION** : la table livraison naît aux cycles CMD/CRS (constitution II — aucune supposition sur la livraison) |
| cree_le | timestamptz | NOT NULL DEFAULT now() | |
| derniere_utilisation_le | timestamptz | NOT NULL DEFAULT now() | base de la purge (12 mois, paramètre de zone) ; mise à jour par `marquer_adresse_utilisee` (appelé par CMD plus tard) |
| supprimee_le | timestamptz | NULL | soft delete — les livraisons passées ne sont pas affectées (FR-021) |

Pas de CHECK « au moins un repère » : une adresse purgée reste utilisable et
redemande un repère à la prochaine utilisation (FR-022).

## 3. Données éphémères (Redis — jamais en Postgres)

| Clé | Contenu | TTL | Rôle |
|---|---|---|---|
| `otp:defi:{e164}` | HMAC du code, essais restants | 300 s | défi OTP — écrasé à chaque nouvelle demande (FR-002) |
| `otp:sms:{e164}` | compteur | 3600 s | plafond 3 SMS/h/numéro (FR-003) |
| `otp:ip:{ip}` | compteur | 3600 s | plafond 10 demandes/h/IP (R12) |
| `insc:{jeton}` | {e164, zone, appareil} | 600 s | jeton d'inscription post-OTP, usage unique (R3) — porte l'appareil capté à la vérification (session NOT NULL, analyze C1) |

Perte de Redis = re-demander un code : éphémère reconstructible
(constitution II).

## 4. Machines à états (chaque transition = test d'intégration + événement outbox)

### Attribution de rôle `coursier`

```
∅ ──soumission dossier──▶ en_attente ──admin valide──▶ valide
                              │  ▲                        │ ▲
                 admin refuse │  │ re-soumission          │ │ admin rétablit
                              ▼  │                        ▼ │
                            refuse                     suspendu
```

| Transition | Acteur | Événement outbox |
|---|---|---|
| ∅ → en_attente | coursier (soumission in-app) | `role.demande` + `dossier_coursier.soumis` |
| en_attente → valide | admin (motif optionnel) | `role.valide` |
| en_attente → refuse | admin (motif requis) | `role.refuse` |
| refuse → en_attente | coursier (re-soumission) | `role.demande` + `dossier_coursier.soumis` (drapeau re-soumission) |
| valide → suspendu | admin (motif requis) | `role.suspendu` |
| suspendu → valide | admin | `role.retabli` |

### Attribution de rôle `vendeur` (pas de demande in-app — §5.1)

| Transition | Acteur | Événement outbox |
|---|---|---|
| ∅ → valide | admin (à l'agrément) | `role.attribue` |
| valide → suspendu | admin (motif requis) | `role.suspendu` |
| suspendu → valide | admin | `role.retabli` |

### Attributions `client` et `admin`

| Transition | Acteur | Événement outbox |
|---|---|---|
| ∅ → valide (client) | automatique à l'inscription | inclus dans `compte.cree` |
| ∅ → valide (admin) | admin existant (FR-012) ou seed | `role.attribue` |

### Session

| Transition | Acteur | Événement outbox |
|---|---|---|
| ∅ → active | vérification OTP réussie / inscription | `session.creee` |
| rotation du refresh | l'appareil (rafraîchissement) | aucun (pas une transition d'état) |
| active → révoquée | locale, à distance, ou détection de réutilisation (R2) | `session.revoquee` (origine dans le payload) |

### Adresse

| Transition | Événement outbox |
|---|---|
| création (proposition post-livraison acceptée) | `adresse.enregistree` |
| renommage / nouveau repère | `adresse.modifiee` |
| soft delete | `adresse.supprimee` |
| purge du repère vocal (job R8) | `adresse.repere_vocal_purge` |

**Invariant transverse (SC-005)** : `coursier_autorise_en_ligne(compte)` ⇔
l'attribution `coursier` existe au statut `valide`. Aucun autre chemin.

## 5. API publique du crate `comptes` (consommée par les autres crates)

```rust
/// Lectures — trait public, impl PgComptes (patron ConfigurationZones).
#[async_trait]
pub trait Comptes {
    /// Rôles au statut `valide` uniquement.
    async fn roles_valides(&self, compte: Uuid) -> Result<Vec<Role>, ErreurComptes>;
    /// Porte de mise en ligne du coursier (cycle CRS) — SC-005.
    async fn coursier_autorise_en_ligne(&self, compte: Uuid) -> Result<bool, ErreurComptes>;
    /// Capacités de transport déclarées (filtre du dispatch, cycle DSP).
    async fn capacites_transport(&self, compte: Uuid) -> Result<Vec<TypeTransport>, ErreurComptes>;
}

/// Écritures — méthodes inhérentes de PgComptes sur &mut PgTransaction
/// (atomicité outbox incontournable, patron du cycle 002) :
///   creer_compte, creer_session, tourner_refresh, revoquer_session,
///   soumettre_dossier_coursier, decider_role (valide/refuse/suspend/retablit),
///   attribuer_role (vendeur/admin), enregistrer_adresse, modifier_adresse,
///   supprimer_adresse, marquer_adresse_utilisee (appelée par CMD plus tard),
///   purger_reperes_vocaux (job R8).
pub struct PgComptes { /* pool + Arc<dyn DepotEphemere> + Arc<dyn EnvoiSms> + Arc<dyn DepotObjets> + PgZones */ }

/// Ports (impls réelles dans la couche api, mémoire dans les tests) :
#[async_trait] pub trait DepotEphemere { /* defi OTP, compteurs, jeton d'inscription (R3) */ }
#[async_trait] pub trait EnvoiSms { async fn envoyer(&self, e164: &str, message_cle: &str, params: &Value) -> Result<(), ErreurSms>; }
#[async_trait] pub trait DepotObjets { /* put, presigner_get(ttl), supprimer (R7) */ }

pub enum Role { Client, Coursier, Vendeur, Admin }
pub enum StatutRole { EnAttente, Valide, Refuse, Suspendu }
pub enum ErreurComptes { CompteInconnu, RoleRequis, TransitionInvalide, DefiOtpInvalide,
    PlafondAtteint, ConsentementRequis, TelephoneInvalide, VehiculeHorsZone,
    DossierIncomplet, ObjetTropVolumineux, Sql(..), /* … */ }
```

Côté couche `api` : extracteur `Auth { compte_id, session_id, roles_valides }`
(+ `exiger_role(Role)`) exposé par `auth_http.rs` — consommé dès ce cycle par
`zones_http::forcer_categorie` en remplacement d'`AdminAuth` (R5).

## 6. Seed `backend/seeds/20_comptes.sql` (rejouable — UUID fixes + ON CONFLICT)

- Compte **premier admin** : UUID fixe, `telephone_e164` = numéro d'exploitation
  (placeholder seed), zone Tiassalé, consentement version seed ; attributions
  `client` + `admin` au statut `valide` (decide_par NULL, seed).
- Paramètres de zone (posés sur Côte d'Ivoire, hérités par Tiassalé —
  mécanisme ZON-01) : `telephone.indicatif_defaut = "+225"`,
  `adresse.retention_repere_vocal_jours = 365`,
  `medias.note_vocale_duree_max_s = 30`,
  `consentement.artci_version = "2026-07"` (version du texte servie aux apps
  par la config distante ZON-04 — renvoyée telle quelle à l'inscription).
- Comme au cycle 002 : le seed n'émet AUCUN événement outbox (chargement ≠
  transition) ; double exécution = état strictement identique.
