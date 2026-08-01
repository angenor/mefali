# Contrat — surface HTTP du module coursier (cycle CRS 010)

Routes annotées `#[utoipa::path]`, auto-collectées par `utoipa-actix-web` (patron
`course_http` / `dispatch_http`). Toute route sous `bearerAuth`. Erreurs rendues
`{ code, message_cle }` — **clés i18n fr**, jamais de texte en dur. Les clients
`clients/dart` et `clients/ts` sont **régénérés** depuis `openapi.json`
(constitution I).

Deux modules nouveaux : `coursier_http` (rôle coursier) et `admin_coursier_http`
(rôle admin). Deux modules existants sont **ajustés** : `course_http` (idempotence
de la remise et de l'échec) et `qr_http` (l'endpoint de course active déménage).

**Garde double partout** : rôle **et** propriété. Un coursier ne lit et n'écrit
que sa propre course, sa propre caisse, ses propres preuves — y compris **au
rejeu** d'une action de la file (FR-006, dette relevée au cycle 008).

---

## 1. Endpoints coursier — `coursier_http.rs`

| Méthode | Chemin | Objet | FR |
|---|---|---|---|
| `GET` | `/courses/active` | Course active **complète** pré-provisionnée (déménage de `qr_http`) | FR-011, FR-028, FR-037 |
| `POST` | `/courses/{livraison_id}/appels` | Journalise un appel passé via l'app | FR-030, FR-031, FR-033 |
| `POST` | `/courses/{livraison_id}/presence` | Lot de relevés de présence | FR-061, FR-064 |
| `POST` | `/courses/{livraison_id}/preuves/photo` | Photo de preuve (multipart) | FR-056, FR-064 |
| `GET` | `/courses/{livraison_id}/preuves` | État des 3 preuves et ce qui manque | FR-058, FR-062 |
| `GET` | `/moi/caisse` | Avances en cours, historique du jour, indemnisations, litiges | FR-067 → FR-077 |
| `GET` | `/moi/journee` | Gains du jour, courses livrées, plafond et reste, taux d'acceptation | FR-091 → FR-095 |

### 1.1 `GET /courses/active`

Réponse `200` — structure détaillée dans [data-model.md §3](../data-model.md).
`204` si aucune course assignée. Champs **additifs** par rapport au cycle 006 :
l'app livrée continue de fonctionner pendant la transition.

```jsonc
{
  "livraison_id": "0199…", "commande_id": "0199…", "etat": "en_collecte",
  "devise": "XOF",
  "arrets": [{
    "arret_id": "0199…", "prestataire_id": "0199…", "nom": "Étal Adjoua",
    "site_lat": 5.898, "site_lon": -4.822, "distance_precedent_m": 800,
    "empreinte_jeton": "a1b2…", "empreinte_code": "c3d4…",
    "montant_avance": 1500, "photo_exigee": false, "distance_max_m": 100,
    "statut": "a_collecter", "telephone_vendeur": "+225…",
    "lignes": [
      { "ligne_id": "0199…", "libelle": "Tomates", "quantite": 2,
        "prix_unitaire_unites": 400, "preference_substitution": "appeler",
        "statut": "a_prendre" }
    ]
  }],
  "client": {
    "nom_usage": "Awa K.", "telephone": "+225…",
    "repere_texte": "Cour verte après la pharmacie",
    "repere_vocal_url": "https://…", "repere_vocal_duree_s": 12,
    "lieu_lat": 5.90, "lieu_lon": -4.83, "depot_autorise": false
  },
  "remise": {
    "empreinte_code": "e5f6…", "empreinte_jeton": "0789…",
    // essais_max vient du paramètre de zone EXISTANT `commande.essais_code_livraison`
    // (cycle 008) — ce cycle n'en crée pas un second (R5, FR-106)
    "essais_consommes": 0, "essais_max": 3, "code_bloque": false,
    "montant_a_encaisser_unites": 5800, "mode_paiement": "cash",
    "preuves": { "appels_min": 2, "espacement_s": 180, "presence_s": 600,
                 "rayon_m": 100, "photos_min": 1 }
  }
}
```

⚠ **Aucun secret** : ni le code à 4 chiffres, ni le jeton, ni le code de secours
vendeur — seulement leurs empreintes (FR-037). Les deux numéros de téléphone sont
la seule donnée personnelle servie, et uniquement après assignation (R6).

### 1.2 `POST /courses/{livraison_id}/appels`

```jsonc
// Requête
{ "uuid_client": "0199…", "vers": "client", "motif": "client_absent",
  "prestataire_id": null, "passe_le_local": "2026-07-28T15:02:11Z",
  "issue": "sans_reponse" }               // facultatif — défaut "inconnue"
// Réponse 201 — { "appel_id": "0199…", "compte_pour_preuve": true }
```

Idempotent par `uuid_client` (`200` au rejeu, même corps). `motif` vaut
`suivi` | `substitution` | `client_absent` — **seul `client_absent` compte** pour
la preuve d'échec (FR-035). `issue` vaut `inconnue` | `sans_reponse` | `repondu` :
elle est **déclarée** par le coursier (le serveur ne voit pas l'appel), sert
l'affichage de K4-1e (FR-036) et **n'est jamais un critère de preuve** (R19). Un
`PATCH` du même `uuid_client` met à jour la seule `issue`. Aucun numéro n'est
transmis ni journalisé.

### 1.3 `POST /courses/{livraison_id}/presence`

```jsonc
// Requête — lot (la file peut en avoir accumulé plusieurs minutes)
{ "releves": [
    { "uuid_client": "0199…", "distance_m": 12, "releve_le_local": "…:02:11Z" },
    { "uuid_client": "0199…", "distance_m": 15, "releve_le_local": "…:02:41Z" }
]}
// Réponse 200 — { "retenus": 2, "presence_s": 30, "requis_s": 600 }
```

L'app envoie une **distance**, jamais une position (R8). Le serveur recalcule
`presence_s` en ignorant tout intervalle supérieur au « trou » de zone.

### 1.4 `GET /courses/{livraison_id}/preuves`

```jsonc
{
  "appels":   { "faits": 2, "requis": 2, "espacement_ok": true,
                "horodatages": ["15:02", "15:06"], "issues": ["sans_reponse", "sans_reponse"],
                "ok": true },
  "presence": { "secondes": 360, "requis": 600, "ok": false,
                "motif_cle": "coursier.preuve.presence_en_cours" },
  "photos":   { "faites": 0, "requis": 1, "ok": false },
  "reunies":  false, "reunies_sur": 1, "total": 3
}
```

C'est **la même fonction** que celle qui garde `POST /courses/{id}/echec` :
l'écran et le serveur ne peuvent pas diverger (FR-059 / FR-060).

### 1.5 `GET /moi/caisse` et `GET /moi/journee`

```jsonc
// /moi/caisse
{ "avance_en_cours_unites": 5550, "courses_concernees": 1, "devise": "XOF",
  "avances_en_attente_reglement_unites": 0,          // commandes prépayées (R10)
  "historique_du_jour": [
    { "commande_id": "0199…", "reference": "#418", "libelle_cle": "…",
      "avance_unites": 5550, "rembourse_unites": 0, "gain_unites": 450,
      "etat": "en_cours", "heure": "14:32" }],
  "indemnisations": [
    { "id": "0199…", "commande_reference": "#398", "montant_unites": 200,
      "etat": "validee", "litige_id": null, "motif_cle": "…" }],
  "litiges_en_cours": [] }

// /moi/journee
{ "courses_livrees": 7, "gains_unites": 8400, "devise": "XOF",
  "plafond_retenu_unites": 10000, "reste_disponible_unites": 6500,
  "taux_acceptation_pourcent": 92, "note": null }    // note = null tant qu'AVI n'existe pas
```

`/moi/journee` est **composé dans le handler** à partir de deux dépôts —
`coursier` (courses livrées, gains, avances en cours) et `dispatch` (plafond
retenu, taux d'acceptation). Aucun des deux crates n'apprend l'existence de
l'autre (voir `ports-coursier.md` §2).

---

## 2. Endpoints existants ajustés — `course_http.rs`

| Méthode | Chemin | Ce qui change |
|---|---|---|
| `POST` | `/courses/{livraison_id}/remise` | passe en **`multipart/form-data`** (R18) ; `uuid_client` **obligatoire** (idempotence, R4) ; `essais_hors_ligne` et `hors_ligne` optionnels ; refus `422` si `mode = depot` sans `depot_autorise` |
| `POST` | `/courses/{livraison_id}/echec` | `uuid_client` **obligatoire** ; les preuves sont désormais vérifiées **réellement** (`PgCoursier`, plus `PreuvesFixes`) |

```jsonc
// POST /courses/{id}/remise — partie `demande` du multipart
{ "uuid_client": "0199…", "mode": "code", "code": "7341",
  "essais_hors_ligne": 1, "hors_ligne": true,
  "confirme_le_local": "2026-07-28T14:56:03Z" }
// + partie `photo` (binaire) — mode `depot` UNIQUEMENT
// + "depot_lat" / "depot_lon" dans `demande` pour le mode `depot`
```

**Pourquoi multipart** : la voie « dépôt » attendait jusqu'ici une `photo_cle`,
c'est-à-dire un objet **déjà déposé** — impossible sans réseau. La photo voyage
désormais **avec** la demande, donc dans la file, donc hors ligne (R18, FR-048b).
Le patron est celui de la collecte (cycle 006) et de la rupture (cycle 008) :
partie `demande` en JSON, partie `photo` binaire, schéma OpenAPI dédié pour que
le client généré produise un vrai multipart. `photo_cle` reste accepté en entrée
pour ne casser aucun appelant existant ; l'app coursier ne l'utilise jamais.

Codes de retour (inchangés sauf mention) : `200` validée · `403` course d'un
autre · `409` preuve incorrecte ou état incompatible · `422` demande mal formée
**ou dépôt non autorisé** (nouveau) · `423` code **épuisé** — l'app affiche K4-1d
et l'exploitation reçoit l'alerte.

Le serveur **revalide toujours** la preuve reçue par la file : une validation
locale n'est jamais décisive (FR-046).

---

## 3. Endpoints d'exploitation — `admin_coursier_http.rs`

Tous `Role::Admin`. **Aucun écran Nuxt** ce cycle : ils sont exercés par API
(patron du cycle 009), et ADM-02/04/07 les habilleront.

| Méthode | Chemin | Objet | FR |
|---|---|---|---|
| `GET` | `/admin/coursiers/exposition` | Σ avances par coursier et au total | FR-075 |
| `GET` | `/admin/indemnisations` | File des indemnisations, filtrable par état | FR-071 |
| `POST` | `/admin/indemnisations/{id}/valider` | Valide — écrit le mouvement de caisse | FR-072 |
| `POST` | `/admin/indemnisations/{id}/refuser` | Refuse — motif obligatoire | FR-072 |
| `GET` | `/admin/remises/bloquees` | Livraisons dont le code est épuisé | FR-044 |
| `POST` | `/admin/commandes/{id}/code/debloquer` | Lève le blocage — motif obligatoire | FR-055 |
| `POST` | `/admin/commandes/{id}/depot` | Ouvre (ou referme) le dépôt — motif obligatoire | FR-116 |
| `GET` | `/admin/livraisons/{id}/preuves` | Preuves attachées à un échec : appels (heures + issue), présence mesurée, photos | FR-063 |

```jsonc
// GET /admin/coursiers/exposition
{ "devise": "XOF", "total_unites": 12750, "au": "2026-07-28T15:04:00Z",
  "par_coursier": [ { "coursier_id": "0199…", "nom": "Yao K.",
                      "avance_unites": 5550, "courses": 1 } ] }

// POST /admin/commandes/{id}/depot
{ "autorise": true, "motif_cle": "depot.demande_client_par_telephone" }
```

Chaque écriture admin est **tracée** (qui, quand, motif) et émet son événement.

---

## 4. Ce que ce contrat NE fait PAS

| Absent | Pourquoi |
|---|---|
| Génération d'un lien de paiement sur place | **PAY-03**, P1, tranche T3 (FR-050) |
| Remboursement d'une avance sur commande prépayée | déféré à **PAY-01/02**, tranche T3 (FR-117, R10) |
| Solde et mouvements du **fonds d'incidents** | **ADM-07** (FR-072) |
| Seuil d'alerte sur l'exposition | **ADM-07** (FR-075) |
| Signaler / bloquer un client ou un vendeur | **CRS-07**, P1, tranche T4 (FR-110) |
| Émission du push d'offre | **NTF-01** — le contrat du cycle 009 est intact |
