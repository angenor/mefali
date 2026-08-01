# Contrat — surface HTTP du module paiements (cycle PAY 011)

Routes annotées `#[utoipa::path]`, auto-collectées par `utoipa-actix-web` (patron
`commandes_http` / `coursier_http`). Erreurs rendues `{ code, message_cle }` —
**clés i18n fr**, jamais de texte en dur. Les clients `clients/dart` et
`clients/ts` sont **régénérés** depuis `openapi.json` (constitution I).

Trois modules nouveaux : `paiements_http` (client), `paiements_webhook_http`
(fournisseur, **non authentifié**), `admin_paiements_http` (admin). Trois modules
existants sont **ajustés** : `commandes_http` (le suivi porte l'état de paiement),
`coursier_http` (la caisse porte trois positions), `vendeur_http` +
`admin_prestataires_http` (offre de livraison).

**Garde double partout sauf le webhook** : rôle **et** propriété. Awa ne voit que
ses commandes ; Yao que sa caisse ; un vendeur que ses arrêts. Le webhook n'a pas
de porteur — sa garde est cryptographique (research R6, R20).

---

## 1. Endpoints client — `paiements_http.rs` (rôle `Client`)

| Méthode | Chemin | Objet | FR |
|---|---|---|---|
| `POST` | `/commandes/{id}/paiement` | Ouvre **ou renvoie** la session de paiement | FR-010, FR-015, FR-018 |
| `GET` | `/commandes/{id}/paiement` | État de la session + temps restant | FR-016, FR-017 |
| `GET` | `/commandes/{id}/recu` | Reçu client | FR-070, FR-073 |

### 1.1 `POST /commandes/{id}/paiement`

**Idempotent** : rappelé tant que la session vit, il renvoie la même session sans
rien rouvrir chez le fournisseur (FR-015). L'identifiant de commande **est** la
clé — aucun en-tête d'idempotence supplémentaire, patron du cycle 008.

```jsonc
// 200 — session vivante (créée ou retrouvée)
{
  "transaction_id": "0199…",
  "etat": "ouverte",
  "montant_unites": 12500,
  "devise": "XOF",
  "acces_paiement": "https://…",     // à ouvrir dans le navigateur système (R17)
  "expire_le": "2026-08-01T10:15:00Z",
  "restant_s": 873
}
```

| Code | Cas | `code` |
|---|---|---|
| `403` | la commande n'appartient pas à l'appelant | `commande_interdite` |
| `409` | la commande n'est pas en attente de paiement (cash, déjà réglée, annulée) | `paiement_non_requis` |
| `502` | fournisseur injoignable ou en erreur — la commande reste intacte (FR-018) | `fournisseur_indisponible` |

`acces_paiement` n'apparaît **jamais** dans un événement outbox ni dans un log
(FR-006, FR-103).

### 1.2 `GET /commandes/{id}/paiement`

Même corps que ci-dessus, `acces_paiement` mis à `null` dès que l'état quitte
`ouverte`. `restant_s` vaut `0` sur une session échue — **le serveur ne se fie
pas à l'horloge de l'app** pour dire qu'une session vit encore.

`404` si aucune transaction n'existe pour cette commande (commande cash).

### 1.3 `GET /commandes/{id}/recu`

```jsonc
{
  "commande_id": "0199…", "devise": "XOF",
  "lignes": [ { "libelle": "Attiéké poisson", "quantite": 2, "prix_unitaire": 1500,
                "statut": "vivante" } ],
  "montant_articles_unites": 3000,
  "frais_livraison_unites": 500,
  "retenue_vendeur_unites": 0,          // > 0 si la livraison est offerte (FR-070)
  "total_du_unites": 3500,
  "mode_paiement": "mobile_money",
  "moyen": "wave",                       // `null` tant que le fournisseur ne l'a pas dit
  "deja_regle": true,                    // FR-073
  "montant_a_remettre_au_coursier_unites": 0
}
```

Les lignes retirées apparaissent avec `statut: "retiree"` et **ne comptent pas**
dans les montants : le reçu explique pourquoi le total a bougé plutôt que de le
faire bouger en silence.

---

## 2. Endpoint fournisseur — `paiements_webhook_http.rs` (**non authentifié**)

| Méthode | Chemin | Objet | FR |
|---|---|---|---|
| `POST` | `/paiements/notifications/{fournisseur}` | Notification signée du fournisseur | FR-020 → FR-027 |

- Corps reçu **brut** (`web::Bytes`), plafonné à **64 Kio**, jamais désérialisé
  avant vérification de la signature (research R6).
- `200 {"traite": true}` — effet appliqué. `200 {"traite": false, "motif": "rejeu"}`
  — notification déjà vue, **aucun** effet (FR-021).
- `401` — signature absente, invalide ou périmée : une ligne
  `notification_recue(signature_valide = false)` est écrite, rien d'autre (FR-020).
- `409` jamais rendu : une notification concurrente perdante répond `200`
  « rejeu » — un fournisseur qui reçoit une erreur retente en boucle (FR-022).
- Limitation de débit par IP (patron OTP du cycle 003), et exclusion de Swagger UI
  en production (constitution VIII).

Le segment `{fournisseur}` sélectionne l'implémentation à laquelle déléguer la
vérification : c'est **le point d'accroche du routage de phase 2+** (FR-043), et
il ne porte aucune règle aujourd'hui — un fournisseur inconnu répond `404`.

---

## 3. Endpoints vendeur — `vendeur_http.rs` (ajusté, rôle `Vendeur`)

| Méthode | Chemin | Objet | FR |
|---|---|---|---|
| `PUT` | `/vendeur/prestataires/{id}/offre-livraison` | Déclare l'offre de livraison | FR-046 |
| `GET` | `/vendeur/arrets/{arret_id}/recu` | Reçu vendeur d'un arrêt collecté | FR-071 |

### 3.1 `PUT /vendeur/prestataires/{id}/offre-livraison`

```jsonc
// requête
{ "offre": "au_dela", "seuil_unites": 5000 }   // "jamais" | "toujours" | "au_dela"
```

`400 offre_seuil_manquant` si `au_dela` sans seuil > 0. Aucune commande existante
n'est retarifée (FR-048) — la réponse le rappelle en clair via `message_cle`.

Miroir admin : `PUT /admin/prestataires/{id}/offre-livraison`, même corps, rôle
`Admin` (FR-046, l'exploitation configure pour un vendeur sans app).

### 3.2 `GET /vendeur/arrets/{arret_id}/recu`

```jsonc
{
  "arret_id": "0199…", "prestataire_id": "0199…", "devise": "XOF",
  "collecte_le": "2026-08-01T09:41:12Z",
  "lignes": [ … ],
  "montant_articles_unites": 3000,
  "retenue_livraison_offerte_unites": 500,   // les MÊMES chiffres que le reçu client (FR-053)
  "net_verse_unites": 2500,
  "motif_retenue_cle": "recu.retenue.livraison_offerte_vendeur"
}
```

`403` si l'arrêt n'appartient pas à un prestataire rattaché à l'appelant.

---

## 4. Endpoints coursier — `coursier_http.rs` (ajusté, rôle `Coursier`)

`GET /moi/caisse` gagne trois positions et la liste des créances — **champs
additifs**, l'app livrée continue de fonctionner pendant la transition :

```jsonc
{
  "devise": "XOF",
  "avances_ouvertes_unites": 4200,        // existant
  "historique": [ … ],                    // existant, gagne les nouveaux types
  "indemnisations": [ … ],                // existant
  // ── nouveau (FR-060, FR-094) ──
  "positions": {
    "avance_non_recuperee_unites": 4200,
    "du_par_mefali_unites": 5100,
    "detenu_pour_mefali_unites": 0        // marge, nulle au MVP
  },
  "creances": [
    { "id": "0199…", "commande_id": "0199…", "nature": "avance_prepayee",
      "montant_unites": 4200, "etat": "due", "cree_le": "2026-08-01T09:55:00Z" },
    { "id": "0199…", "commande_id": "0199…", "nature": "part_course",
      "montant_unites": 900, "etat": "due", "cree_le": "2026-08-01T09:55:00Z" }
  ]
}
```

`GET /courses/active` : `remise.montant_a_encaisser_unites` vaut **0** quand
`remise.mode_paiement` n'est pas `cash` (FR-057, FR-093, research R11), et
chaque arrêt gagne `montant_articles_unites` / `retenue_appliquee_unites` pour
que K3 affiche le net **et** son explication (FR-092).

---

## 5. Endpoints admin — `admin_paiements_http.rs` (rôle `Admin`)

| Méthode | Chemin | Objet | FR |
|---|---|---|---|
| `GET` | `/admin/paiements/transactions` | Registre filtrable (`etat`, `moyen`, `zone`, `depuis`, `jusqu_a`) | FR-080, FR-081 |
| `GET` | `/admin/paiements/dossiers` | File des anomalies d'argent (`etat`, `type`) | FR-082 |
| `POST` | `/admin/paiements/dossiers/{id}/clore` | Clôt un dossier avec motif obligatoire | FR-082 |
| `GET` | `/admin/creances` | Créances de coursiers (`etat`, `coursier_id`) + total dû | FR-065, FR-083 |
| `POST` | `/admin/creances/{id}/regler` | Marque le versement effectué | FR-067 |

### 5.1 `POST /admin/creances/{id}/regler`

```jsonc
// requête
{ "motif_cle": "creance.reglement.virement_agence" }
// 200
{ "id": "0199…", "etat": "reglee", "ecriture_id": "0199…",
  "regle_par": "0199…", "regle_le": "2026-08-01T18:02:00Z" }
```

Écrit la créance **et** son écriture de caisse `reglement` dans la même
transaction (research R12). `409 creance_deja_reglee` au second appel — le
marquage n'est pas une bascule, il ne s'annule pas : une erreur se corrige par une
écriture **inverse** (FR-064).

### 5.2 `GET /admin/paiements/transactions`

Chaque ligne porte `reference_fournisseur` et `commande_id` — le rapprochement
dans les deux sens de FR-081 se lit sans jointure manuelle. Les orphelines
(`commande_id` nul, ou commande annulée avec transaction `payee_hors_delai`) sont
marquées `"orpheline": true`.

---

## 6. Ce que ce contrat NE contient PAS

| Absent | Pourquoi |
|---|---|
| Tout endpoint de **remboursement** | PAY-04, P1 — `refund` existe dans le trait, aucune route ne l'appelle (FR-041, FR-111) |
| Tout endpoint de **paiement sur place** | PAY-03, P1 (FR-110) |
| Tout endpoint de **commission vendeur** | PAY-06, P2 (FR-112) |
| Toute route de **routage par moyen** | phase 2+ ; le segment `{fournisseur}` du webhook est le seul point d'accroche, sans règle (FR-043, FR-113) |
| Toute page `/admin/**` Nuxt | ADM-01→06, stories distinctes (FR-084) |
| Tout endpoint de **badge livraison gratuite** | reste de VND-08 (FR-049, FR-114) |
