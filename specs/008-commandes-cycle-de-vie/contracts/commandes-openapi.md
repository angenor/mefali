# Contrat — module commandes (cycle CMD 008)

Surface HTTP annotée `#[utoipa::path]`, auto-collectée par `utoipa-actix-web` (patron `prestataires_http` / `qr_http`). Toute route sous `bearerAuth`. Erreurs rendues `{ code, message_cle }` — **clés i18n fr**, jamais de texte en dur (constitution VII). Les clients `clients/dart` et `clients/ts` sont **régénérés** depuis `openapi.json` (constitution I).

Trois modules, un par rôle : `commandes_http` (client), `course_http` (coursier), `admin_commandes_http` (admin).

## 1. Endpoints client — `commandes_http.rs`

| Méthode | Chemin | Rôle | Objet |
|---|---|---|---|
| `POST` | `/paniers/devis` | `Client` | Devis de panier **sans effet de bord** : regroupement par vendeur, sous-totaux, frais détaillés, drapeaux de mixage et de scission |
| `POST` | `/commandes` | `Client` | Création (en-tête `Idempotency-Key` **obligatoire**) → commande + **code + jeton QR** |
| `GET` | `/moi/commandes` | `Client` | Liste des commandes du compte (en cours d'abord) |
| `GET` | `/commandes/{id}` | `Client` (propriétaire) | Suivi complet : état clair, progression par arrêt, position **et son âge**, code, jeton |
| `POST` | `/commandes/{id}/annuler` | `Client` (propriétaire) | Annulation — sans frais avant toute collecte |
| `POST` | `/commandes/{id}/substitutions/{sub}/decision` | `Client` (propriétaire) | Accepter / refuser un remplacement (fenêtre de 60 s) |
| `POST` | `/commandes/{id}/appel` | `Client` (propriétaire) | Journalise l'intention d'appel du coursier |

### 1.1 `POST /paniers/devis`

```jsonc
// Requête
{
  "zone_id": "…", "categorie_slug": "marche", "transport_slug": "moto",
  "lieu": { "lat": 5.898, "lon": -4.823 },
  "lignes": [
    { "prestataire_id": "…", "article_id": "…", "quantite": 2, "preference": "appeler" }
  ]
}
// Réponse 200
{
  "groupes": [                                  // regroupement par vendeur (maquette C3-3a)
    { "prestataire_id": "…", "nom": "Étal Adjoua", "nb_articles": 5,
      "sous_total_unites": 210000, "lignes": [ … ] }
  ],
  "montant_articles_unites": 555000,
  "devis": {
    "prix_client_unites": 25000, "part_coursier_unites": 25000, "marge_unites": 0,
    "devise": "XOF", "distance_m": 2400, "eta_s": 480, "degraded": false,
    "composantes": { "base": 20000, "km": 0, "supplements": 0,
                     "effort_paliers": 10000, "effort_attente": 0, "effort_arrets": 5000,
                     "arrondi": 0, "retenue_vendeur": 0 },
    "ordre_arrets": [1, 0, 2]
  },
  "total_unites": 590000,
  "paiement": { "cash_autorise": false, "motif_cle": "commande.cash.plafond_depasse",
                "plafond_unites": 1000000 },
  "scission": {                                  // null si aucune proposition
    "cause": "categorie_non_mixable",            // ou "plafond_eclatement"
    "message_cle": "panier.scission.restauration",
    "commandes_proposees": [ { "libelle_cle": "panier.scission.repas", "lignes": [ … ],
                               "total_estime_unites": 300000 } ]
  }
}
```

Aucune écriture, **aucun événement** (patron du simulateur admin du cycle 007). Le drapeau `scission` combine ses deux causes en une proposition unique (research R9) ; le serveur ne scinde **jamais** (FR-010).

### 1.2 `POST /commandes`

En-tête `Idempotency-Key: <uuidv7>` — **devient l'identifiant** de la commande (research R7). Rejeu → `200` avec le corps identique ; création → `201`.

```jsonc
// Requête : le panier validé + l'adresse + le mode de paiement
{
  "zone_id": "…", "categorie_slug": "marche", "transport_slug": "moto",
  "adresse_id": "…",                     // ou pin + repère fournis en clair
  "lieu": { "lat": 5.898, "lon": -4.823 },
  "repere_texte": "Près de la pharmacie Sainte-Marie",   // OU repere_vocal_cle
  "repere_vocal_cle": null,
  "lignes": [ { "prestataire_id": "…", "article_id": "…", "quantite": 2,
                "preference": "appeler" } ],
  "mode_paiement": "cash"
}
// Réponse 201
{
  "id": "…", "etat": "nouvelle", "etat_le": "…",
  "montant_articles_unites": 555000, "total_unites": 590000, "devise": "XOF",
  "paiement": { "mode": "cash", "etat": "du", "appoint_exact_unites": 590000 },
  "remise": { "code_livraison": "7341", "jeton_reception": "…" },   // CLIENT SEUL (R6)
  "livraison": { "id": "…", "etat": "assignee", "nb_arrets": 4, "devis": { … } }
}
```

Refus (`409` sauf mention) avec leur clé i18n :

| Code | Statut | Clé i18n | Cause |
|---|---|---|---|
| `compte_bloque` | 403 | `commande.refus.compte_bloque` | Drapeau `bloque` (FR-026) |
| `categorie_non_mixable` | 409 | `commande.refus.non_mixable` | Restauration mêlée aux courses (FR-009) |
| `repere_manquant` | 422 | `commande.refus.repere_requis` | Ni texte ≥ N, ni note vocale (FR-018) |
| `telephone_non_verifie` | 403 | `commande.refus.telephone` | FR-019 |
| `vendeur_indisponible` | 409 | `commande.refus.vendeur_ferme` | `Commandabilite` fausse (FR-029) |
| `article_indisponible` | 409 | `commande.refus.article` | Rupture entre panier et confirmation (FR-029) |
| `cash_indisponible` | 409 | `commande.refus.cash_plafond` | Plafond de zone ou prépaiement imposé (FR-024/025) |

### 1.3 `GET /commandes/{id}` — suivi

```jsonc
{
  "id": "…", "etat": "en_cours", "etat_cle": "suivi.etat.collecte_en_cours",
  "progression": { "collectes_faites": 2, "collectes_total": 3,
                   "arret_courant": { "prestataire_nom": "Boutique Yao", "ordre": 2 } },
  "coursier": { "id": "…", "prenom": "Yao", "note": 4.8, "appel_possible": true },
  "position": { "lat": 5.899, "lon": -4.821, "age_s": 12 },   // null si absente (R13)
  "remise": { "code_livraison": "7341", "jeton_reception": "…" },
  "substitution_en_attente": { "id": "…", "article_nom": "Tomates en boîte 400 g × 2",
                               "prix_unites": 60000, "ancien_prix_unites": 50000,
                               "photo_url": "…", "reste_s": 47 }
}
```

L'`age_s` est **toujours** renvoyé avec la position : l'app affiche « il y a 12 s » et n'invente jamais une position (FR-040, maquette C4-4d).

## 2. Endpoints coursier — `course_http.rs`

Rôle `Coursier`, **et** propriété : la livraison doit être assignée à l'appelant. Toute écriture porte `uuid_client` + `horodatage_local` (constitution V) et est **idempotente**.

| Méthode | Chemin | Objet |
|---|---|---|
| `POST` | `/courses/{livraison}/arrets/{arret}/en-route` | Départ vers l'arrêt |
| `POST` | `/courses/{livraison}/arrets/{arret}/arrive` | Arrivée géolocalisée (`arrive_le` → prime d'attente TRF-06) |
| `POST` | `/courses/{livraison}/arrets/{arret}/indisponible` | Arrêt entièrement indisponible (FR-051) |
| `POST` | `/courses/{livraison}/substitutions` | Proposer un remplacement (multipart : photo + prix) |
| `POST` | `/courses/{livraison}/remise` | Remise : `qr` \| `code` \| `depot` |
| `POST` | `/courses/{livraison}/echec` | Déclarer l'échec — **refusé sans preuves** |

> La collecte d'un arrêt (`POST /courses/arrets/{arret}/collecte`) **existe déjà** — livrée au cycle 006 dans `qr_http`. Elle n'est pas redéfinie ; seule sa garde d'état s'enrichit des nouveaux statuts.

`POST /courses/{livraison}/remise` vérifie le **jeton** ou le **code** contre la valeur stockée, incrémente `essais_code` et bloque au troisième échec (`code_epuise`, `423`) avec alerte admin. Le coursier ne reçoit **jamais** le code : le pré-provisionnement de CRS-04 lui livrera les **empreintes** (research R6).

`POST /courses/{livraison}/substitutions` refuse (`409`) si l'article proposé appartient à un **autre vendeur** (`substitution.refus.autre_vendeur`, FR-048) ou si l'écart dépasse le plafond de zone (`substitution.refus.ecart_prix`, FR-047).

`POST /courses/{livraison}/echec` renvoie `409 preuves_incompletes` (`echec.refus.preuves`) tant que `PreuvesEchec::preuves_reunies` est faux (FR-056).

## 3. Endpoints admin — `admin_commandes_http.rs`

Rôle `Admin`, journalisé (patron des cycles 002/003/005).

| Méthode | Chemin | Objet |
|---|---|---|
| `POST` | `/admin/commandes/{id}/annuler` | Annulation à tout moment, **motif obligatoire** (FR-054) |
| `POST` | `/admin/commandes/{id}/issues` | Enregistrer une issue de l'arbre §7.5 |
| `GET` | `/admin/commandes/attente` | File FIFO des commandes sans coursier (CMD-10, écran ADM futur) |

`POST /admin/commandes/{id}/issues` porte le type d'issue, l'arrêt éventuel, les deux détenteurs, la sanction et le motif (clé i18n). Il écrit `issue_echec` et émet `echec.issue_enregistree`, plus `litige.ouvert` / `indemnisation.due` / `sanction.posee` selon le cas — **sans** créer de dossier de litige ni d'écriture de caisse (frontière tranchée en spec, FR-062).

## 4. Traits offerts aux cycles suivants

| Trait | Consommateur | Signature |
|---|---|---|
| `CommandesADispatcher` | **DSP** | `en_attente_coursier(zone)` → file FIFO ; `affecter(commande, coursier)` |
| `ServiceWorkflow` | verticaux futurs | `slug()`, `valider_creation(panier)`, `details(panier)` |
| Empreintes de remise | **CRS-04** | exposées à l'assignation : `{ code_hash, jeton_hash }` — jamais les valeurs |

## 5. Événements

Voir [data-model.md §7](../data-model.md) — 25 événements, tous déclarés dans `docs/taxonomie-evenements.md` **avant** implémentation (constitution VI). Trois sont des **contrats sans consommateur** ce cycle : `commande.prete_a_dispatcher` (DSP), `litige.ouvert` (AVI-04), `indemnisation.due` (CRS-06).

## 6. Écrans Flutter — surfaces consommatrices

| Maquette | Écran | Endpoints consommés |
|---|---|---|
| C3-3a | Panier groupé par vendeur | `POST /paniers/devis` |
| C3-3a′ | Adresse et paiement | `GET /moi/adresses` (cycle 003), `POST /commandes` |
| C3-3b | Montant > plafond cash | `POST /paniers/devis` (drapeau `paiement.cash_autorise`) |
| C3-3c | Panier hors ligne | **aucun** — brouillon drift, envoi unique en file |
| C3-3d | Mixte restauration + courses | `POST /paniers/devis` (bloc `scission`) |
| C4-4a | Suivi, collecte en cours | `GET /commandes/{id}` |
| C4-4b | Recherche de coursier | `GET /commandes/{id}`, `POST /commandes/{id}/annuler` |
| C4-4c | Substitution proposée | `POST /commandes/{id}/substitutions/{sub}/decision` |
| C4-4d | Suivi hors ligne | **aucun** — `CommandeCache` drift (code + QR + dernier état) |
