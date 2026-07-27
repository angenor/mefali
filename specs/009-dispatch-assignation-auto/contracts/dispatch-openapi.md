# Contrat — module dispatch (cycle DSP 009)

Surface HTTP annotée `#[utoipa::path]`, auto-collectée par `utoipa-actix-web`
(patron `course_http` / `admin_commandes_http`). Toute route sous `bearerAuth`.
Erreurs rendues `{ code, message_cle }` — **clés i18n fr**, jamais de texte en dur
(constitution VII). Les clients `clients/dart` et `clients/ts` sont **régénérés**
depuis `openapi.json` (constitution I).

Deux modules, un par rôle : `dispatch_http` (coursier), `admin_dispatch_http`
(admin). `course_http` du cycle 008 n'est pas touché.

**Minimisation (ARTCI).** Aucune réponse coursier ne porte de coordonnée du
client : la destination n'est décrite qu'avant acceptation par le **nom de la
zone** et une **distance arrondie**. L'adresse exacte n'arrive qu'après
acceptation, par le suivi de course du cycle 008 (`GET /commandes/{id}` côté
client, pré-provisionnement de course côté coursier).

---

## 1. Endpoints coursier — `dispatch_http.rs`

Tous `Role::Coursier`, tous gardés aussi par la **propriété** : un coursier ne
lit et n'écrit que sa propre disponibilité et sa propre offre.

| Méthode | Chemin | Objet | FR |
|---|---|---|---|
| `PUT` | `/moi/disponibilite` | Se mettre en ligne / hors ligne, déclarer le plafond d'avance du jour | FR-005, FR-010, FR-011 |
| `GET` | `/moi/disponibilite` | État courant : en ligne, plafond retenu et son palier, présence dans le pool, âge de la position | FR-004, FR-010 |
| `POST` | `/moi/position` | Publier la position (réinscription au pool, repousse la durée de vie) | FR-001, FR-002 |
| `GET` | `/courses/offre-courante` | Offre en vol pour ce coursier, ou `204` | FR-046, R16 |
| `POST` | `/courses/offres/{offre_id}/accepter` | Accepter — idempotent | FR-047, FR-048, FR-054 |
| `POST` | `/courses/offres/{offre_id}/refuser` | Refuser — passe au suivant sans attendre | FR-050 |

### 1.1 `PUT /moi/disponibilite`

```jsonc
// Requête
{ "en_ligne": true, "plafond_declare_unites": 15000 }

// Réponse 200
{
  "en_ligne": true,
  "plafond_declare_unites": 15000,
  "plafond_retenu_unites": 5000,          // min(déclaré, grille par note)
  "plafond_source": "grille_note",        // "grille_note" | "declaration"
  "palier_note_cle": "dispatch.palier.entree",
  "note_centiemes": null,                 // absente tant qu'AVI n'existe pas (R7)
  "devise": "XOF",
  "jour": "2026-07-26",
  "capacites": [{ "famille": "transport", "valeur": "moto" }],
  "dans_le_pool": false,                  // true seulement après une position publiée
  "periode_position_s": 30
}
```

Le **plafond retenu** est le minimum entre le déclaré et le palier de la grille
(FR-010) : Yao voit toujours **lequel s'applique** (`plafond_source`), et pourquoi
(`palier_note_cle`). Passer `en_ligne: false` retire du pool **immédiatement**,
sans attendre l'expiration (FR-005). Un plafond déclaré vaut pour le **jour civil
de la zone** et n'est jamais reporté (FR-011) : un nouveau jour renvoie
`plafond_declare_unites: null` et l'app le redemande.

Refus : `403 role_requis`, `409 dispatch.erreur.dossier_coursier_invalide`
(rôle non validé ou compte bloqué — FR-009),
`422 dispatch.erreur.capacite_non_declaree` (aucun véhicule déclaré),
`409 dispatch.erreur.course_active` (se mettre hors ligne avec une course en
cours n'est pas une sortie de pool, c'est un abandon — traité par CRS).

### 1.2 `POST /moi/position`

```jsonc
// Requête — UUID client + horodatage local (constitution V)
{ "uuid_client": "…", "horodatage_local": "2026-07-26T18:03:12Z",
  "lat": 5.8961, "lon": -4.8209, "precision_m": 12 }

// Réponse 200
{ "dans_le_pool": true, "ttl_s": 90, "prochaine_publication_s": 30 }
```

Écrit les **trois** clés éphémères (`data-model.md` §2) et met à jour
`dispatch.suivi_progression` si le coursier a une course assignée (R13).
`204` si le coursier est hors ligne (la position n'est pas refusée, elle est
ignorée — l'app peut être en retard d'un tic).

**Idempotence.** Une position rejouée avec le même `uuid_client` ne double aucun
événement ; elle repousse simplement la durée de vie. Le serveur écrit **son**
horodatage : `horodatage_local` est une observation (patron `ActionArretDto` du
cycle 008), jamais l'autorité (FR-055).

### 1.3 `GET /courses/offre-courante`

```jsonc
// Réponse 200 — chiffres de la maquette K2-1a
{
  "offre_id": "…",
  "commande_id": "…",
  "mode": "cascade",                       // "cascade" | "broadcast"
  "echeance_le": "2026-07-26T18:04:40Z",   // AUTORITÉ du compte à rebours
  "timer_s": 40,
  "restant_s": 31,
  "arrets": [
    { "ordre": 1, "prestataire_id": "…", "nom": "Étal Adjoua",  "distance_m": 800 },
    { "ordre": 2, "prestataire_id": "…", "nom": "Étal Konan",   "distance_m": 40  },
    { "ordre": 3, "prestataire_id": "…", "nom": "Boutique Yao", "distance_m": 60  }
  ],
  "destination": {                         // AVANT acceptation : jamais de coordonnée
    "zone_nom": "Tiassalé",
    "distance_m": 1800,
    "mention_cle": "dispatch.offre.adresse_apres_acceptation"
  },
  "gain": { "total_unites": 450, "deplacement_unites": 250, "arrets_unites": 50,
            "effort_unites": 100, "devise": "XOF" },
  "avance": { "montant_unites": 5550, "plafond_retenu_unites": 10000, "devise": "XOF" },
  "degraded": false                        // constitution IV — distances estimées
}
```

`204` quand aucune offre n'est en vol. Une offre **échue** rend `204` **même si le
tic n'a pas encore passé** : l'échéance persistée est l'autorité, le tic ne fait
qu'écrire ce que la lecture savait déjà (R1). Les distances sont **inter-arrêts**,
comme la maquette (`+ 40 m`, `+ 60 m`), dans l'ordre optimisé figé par le devis du
cycle 007.

**Écart assumé avec la maquette K2.** K2 affiche « quartier Sokoura ». Aucun
quartier n'existe en donnée : `TypeZone::Quartier` est une **PROVISION**
(« données seulement », constitution IX) et l'arbre seedé s'arrête à la ville. Le
contrat rend donc `zone_nom` + distance. Construire un libellé de quartier
exigerait soit d'activer la provision, soit un service de géocodage inverse —
aucun des deux n'est au périmètre. À reporter au produit.

### 1.4 `POST /courses/offres/{offre_id}/accepter`

```jsonc
// Requête
{ "uuid_client": "…", "horodatage_local": "2026-07-26T18:04:09Z" }

// Réponse 200
{ "commande_id": "…", "livraison_id": "…", "etat_livraison": "assignee" }
```

Chemin exact : verrou vérifié → `CommandesADispatcher::affecter` → livraison
`assignee`, tronc `en_cours`, événements `livraison.affectee` et
`commande.assignee` (déjà émis par `commandes`), puis `dispatch.offre_acceptee` et
libération des deux verrous.

| Refus | Statut | `message_cle` | Sens |
|---|---|---|---|
| Course déjà prise | `409` | `dispatch.erreur.deja_prise` | **sans pénalité**, le coursier reste dans le pool (FR-049) |
| Offre échue | `409` | `dispatch.erreur.offre_echue` | compte à rebours passé — non-réponse, franche ou non |
| Offre d'un autre coursier | `404` | `dispatch.erreur.offre_inconnue` | garde de propriété : une offre qui n'est pas la sienne n'existe pas |
| Course active | `409` | `dispatch.erreur.course_active` | pas de superposition au MVP (FR-007) |

**Idempotence (FR-054).** Un rejeu avec le même `uuid_client` rend le **même
`200`** et le même corps ; il ne crée ni seconde affectation ni second événement.
Un `409 deja_prise` n'est pas un échec technique : l'app l'affiche comme l'état
K2-1b, ton neutre, sans blâme.

**Non enfilé hors ligne.** L'acceptation **n'entre pas** dans la file d'actions
hors-ligne : CRS-08 en énumère limitativement le contenu (« scans, photos,
transitions, confirmations et appels »), et une offre acceptée deux minutes trop
tard n'a plus d'objet. L'idempotence couvre le double tap et la reprise réseau
immédiate, pas un drain différé.

### 1.5 `POST /courses/offres/{offre_id}/refuser`

Même corps. Réponse `200 { "issue": "refusee" }`. Le candidat suivant est
sollicité **immédiatement**, sans attendre la fin du compte à rebours (FR-050).
Un refus compte dans le taux d'acceptation ; il n'entraîne **aucune** sanction
(l'anti-abus DSP-08 est hors périmètre).

---

## 2. Endpoints admin — `admin_dispatch_http.rs`

Tous `Role::Admin`. Ce sont les **contrats** que l'écran d'opérations (ADM-02,
tranche T3) consommera ; aucun écran n'est construit ici (FR-096).

| Méthode | Chemin | Objet | FR |
|---|---|---|---|
| `GET` | `/admin/dispatch/alertes` | Commandes escaladées et courses bloquées, les plus anciennes d'abord | FR-064, FR-075 |
| `GET` | `/admin/dispatch/pool` | Coursiers du pool d'une zone (matière de la « carte des coursiers ») | FR-006 |
| `POST` | `/admin/dispatch/courses/{livraison_id}/reprendre` | Reprendre une course bloquée dont un arrêt est **déjà collecté** — motif obligatoire | FR-075 |

### 2.1 `GET /admin/dispatch/alertes`

```jsonc
// Réponse 200
{
  "escalades": [                             // commandes non assignées (FR-064)
    { "commande_id": "…", "zone_id": "…", "age_s": 372, "seuil_s": 300,
      "chemin": "pipeline",                  // "file" | "pipeline"
      "nb_offres_emises": 4, "etat": "nouvelle" }
  ],
  "courses_bloquees": [                      // assignées et sans progression (FR-075)
    { "commande_id": "…", "livraison_id": "…", "coursier_id": "…",
      "motif": "sans_mouvement", "stagnation_s": 410,
      "nb_arrets_collectes": 2,               // > 0 ⇒ AUCUNE reprise automatique
      "reprise_automatique_possible": false }
  ]
}
```

### 2.2 `POST /admin/dispatch/courses/{livraison_id}/reprendre`

```jsonc
// Requête — motif OBLIGATOIRE, journalisé avec son auteur
{ "motif": "coursier injoignable depuis 20 min, marchandise consignée au local" }

// Réponse 200
{ "commande_id": "…", "etat_commande": "en_attente_coursier", "incident_id": "…" }
```

C'est **la seule** voie de reprise d'une course dont au moins un arrêt est
collecté : l'automatisme s'y refuse par construction (FR-075), parce que le
coursier a engagé ses fonds propres. L'endpoint n'annule aucune dette et n'écrit
aucune caisse : il émet `dispatch.reassignation` avec `acteur: admin` et laisse la
caisse (CRS-06) et le litige (AVI-04) à leurs cycles. `422` si aucun arrêt n'est
collecté — dans ce cas l'automatisme suffit et une action manuelle masquerait un
défaut de pipeline.

---

## 3. Ce que le contrat **ne** rend pas

- **Aucun endpoint de push, d'abonnement ou de canal temps réel** : NTF-01
  (FR-094). L'app interroge `GET /courses/offre-courante`, et le jour où le push
  arrive il **réveille** l'app, qui appelle le même endpoint — aucun contrat à
  refaire.
- **Aucun endpoint de scoring ni de simulation de dispatch** : le classement est
  une décision interne, journalisée en logs structurés et agrégée dans
  `dispatch.evaluation_faite`. Un simulateur relève d'ADM.
- **Aucun endpoint d'édition de la grille des plafonds ni des poids** : ce sont
  des **paramètres de zone**, édités par ADM-05 via le contrat de zones existant.
  Ce cycle les **seede** et les **lit**.
- **Aucune modification des endpoints du cycle 008.** `POST /commandes` gagne un
  effet **interne** (écriture de `commandes.capacite_requise`, R9) sans changer
  son corps de requête ni de réponse — donc aucun diff de client généré sur ce
  chemin.
