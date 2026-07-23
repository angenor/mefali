# Contrat HTTP — QRC (crate `qr` + admin plaque)

Contrat auto-collecté par `utoipa-actix-web` (patron `prestataires_http`). Toute route sous `bearerAuth` (JWT, cycle 003). Erreurs rendues `{ code, message_cle }` (clés i18n fr). Monter chaque handler dans `api::api_openapi()` **et** `api::run()` (les deux listes de `.service(...)`).

---

## 1. Endpoints

### 1.1 `GET /admin/prestataires/{id}/plaque` — télécharger le PDF (Admin)

QRC-01. Génère (ou régénère) le PDF, le dépose (Garage), émet `plaque.generee`, renvoie une URL présignée.

```rust
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PlaqueUrl)]
pub struct PlaqueUrlDto {
    /// URL présignée de lecture (TTL 10 min).
    pub url: String,
    /// Expiration de l'URL.
    pub expire_le: DateTime<Utc>,
}

#[utoipa::path(
    get,
    path = "/admin/prestataires/{id}/plaque",
    tag = "qr",
    params(("id" = Uuid, Path, description = "Prestataire agréé porteur d'une identité de plaque.")),
    responses(
        (status = 200, description = "PDF (QR + nom + code) déposé ; URL présignée renvoyée.", body = PlaqueUrlDto),
        (status = 404, description = "Prestataire inconnu, ou jamais agréé (aucune identité de plaque, FR-011).", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/prestataires/{id}/plaque")]
pub async fn telecharger_plaque(
    auth: Auth, chemin: web::Path<Uuid>, qr: web::Data<PgQr>,
) -> Result<HttpResponse, ErreurQrHttp> {
    auth.exiger_role(Role::Admin).map_err(ErreurQrHttp::from)?;
    let url = qr.plaque_pdf(chemin.into_inner(), auth.compte_id()).await?;
    Ok(HttpResponse::Ok().json(PlaqueUrlDto { url: url.url, expire_le: url.expire_le }))
}
```

### 1.2 `GET /courses/active` — course active + pré-provisionnement (Coursier)

QRC-02 (offline). Renvoie la livraison active du coursier et ses arrêts avec **empreintes** (R6). Vide (`arrets: []`) tant qu'aucune course n'est assignée (pas de DSP → exact en prod ; simulé en test).

```rust
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ArretPreProvisionne)]
pub struct ArretPreProvisionneDto {
    pub arret_id: Uuid,
    pub prestataire_id: Uuid,
    /// base16(sha256(jeton)) — match hors-ligne du QR scanné.
    pub empreinte_jeton: String,
    /// base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
    pub empreinte_code: String,
    pub site_lat: f64,
    pub site_lon: f64,
    pub montant_avance: i64,
    pub devise: String,
    pub photo_exigee: bool,
}

#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CourseActive)]
pub struct CourseActiveDto {
    pub livraison_id: Option<Uuid>,
    pub arrets: Vec<ArretPreProvisionneDto>,
}

#[utoipa::path(
    get, path = "/courses/active", tag = "qr",
    responses(
        (status = 200, description = "Course active du coursier (vide si aucune assignée).", body = CourseActiveDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/courses/active")]
pub async fn course_active(auth: Auth, qr: web::Data<PgQr>) -> Result<HttpResponse, ErreurQrHttp> {
    auth.exiger_role(Role::Coursier).map_err(ErreurQrHttp::from)?;
    let arrets = qr.pre_provisionnement(auth.compte_id()).await?;
    Ok(HttpResponse::Ok().json(CourseActiveDto::from(arrets)))
}
```

### 1.3 `POST /courses/arrets/{arret_id}/collecte` — collecter un arrêt (Coursier)

QRC-02/03/04. **Multipart** quand la photo est exigée (partie `demande` JSON + partie `photo` binaire) ; sinon JSON. Idempotent par `uuid_client` (V). `mode=code_secours` crée l'incident au 1er passage (Q2).

```rust
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeCollecte)]
pub struct DemandeCollecteDto {
    pub mode: ModeCollecteDto,          // scan_qr | code_secours
    /// Jeton lu dans le QR (mode scan_qr).
    pub jeton: Option<String>,
    /// Code à 4 chiffres saisi (mode code_secours).
    pub code: Option<String>,
    pub position_lat: f64,
    pub position_lon: f64,
    /// Clé d'idempotence (UUIDv7 client, V).
    pub uuid_client: Uuid,
    pub horodatage_local: DateTime<Utc>,
}

#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ResultatCollecte)]
pub struct ResultatCollecteDto {
    pub arret_statut: String,           // collecte
    pub livraison_etat: String,         // en_collecte | en_livraison
    pub nb_collectes: i16,
    pub nb_arrets: i16,
    pub en_livraison: bool,
}

#[utoipa::path(
    post, path = "/courses/arrets/{arret_id}/collecte", tag = "qr",
    params(("arret_id" = Uuid, Path, description = "Arrêt à collecter de la course active.")),
    request_body(content = DemandeCollecteDto, description = "JSON, ou partie `demande` d'un multipart avec `photo`."),
    responses(
        (status = 200, description = "Arrêt COLLECTÉ (idempotent au rejeu du même uuid_client).", body = ResultatCollecteDto),
        (status = 409, description = "Arrêt déjà collecté par un autre uuid, ou état incompatible.", body = ErreurApiDto),
        (status = 422, description = "Refus métier : hors zone, jeton révoqué, plaque invalide, photo requise, code épuisé.", body = ErreurApiDto),
        (status = 404, description = "Arrêt inconnu ou hors course active du coursier (précondition, FR-012).", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/arrets/{arret_id}/collecte")]
pub async fn collecter(/* Auth, Path, Multipart|Json, Data<PgQr> */) -> Result<HttpResponse, ErreurQrHttp> { /* … */ }
```

> **Résolution du jeton (QRC-03)** : déjà exposée par 005 — `GET /prestataires/plaque/{jeton}` (session, sans rôle). QRC la **consomme** en interne (`resolution_plaque`) ; ne pas la redéfinir. La fiche publique / scan hors contexte restent au cycle WEB.

---

## 2. Clés d'erreur i18n (variantes `ErreurQr` → `{code, message_cle}`)

| Cas | HTTP | `code` / `message_cle` |
|---|---|---|
| Prestataire jamais agréé (pas de plaque) | 404 | `plaque_absente` |
| Rôle requis manquant | 403 | `role_requis` |
| Hors du rayon de scan (proximité) | 422 | `hors_zone` |
| Prestataire suspendu (jeton révoqué) | 422 | `prestataire_indisponible` |
| Jeton inconnu/forgé | 422 | `plaque_invalide` |
| Photo exigée non fournie | 422 | `photo_requise` |
| Code dégradé : 3 essais épuisés | 422 | `code_epuise` |
| Code dégradé ne correspond pas au prestataire de l'arrêt | 422 | `code_incorrect` |
| Arrêt déjà collecté / état incompatible | 409 | `arret_deja_collecte` / `etat_incompatible` |
| Arrêt hors course active du coursier | 404 | `arret_hors_course` |

---

## 3. Événements outbox émis

Voir [../research.md](../research.md) R12. Rappel : `plaque.generee`, `arret.collecte`, `livraison.mise_en_livraison`, `plaque.remplacement_requis`, `arret.collecte_rejetee`. Rejeu idempotent → **aucun** événement. Déclarer dans `docs/taxonomie-evenements.md` **avant** implémentation (constitution VI).

---

## 4. Montage (rappel)

Ajouter dans `backend/api/src/lib.rs`, aux **deux** chaînes `.service(...)` (`api_openapi()` et `run()`), et créer `pub mod qr_http;` :

```rust
.service(admin_prestataires_http::telecharger_plaque)  // ou qr_http::…
.service(qr_http::course_active)
.service(qr_http::collecter)
```

Câbler `PgQr` dans `run()` (racine de composition) à côté de `PgPrestataires` : pool + `PgCommandes` + `PgPrestataires` + port objets + port Redis + secret non requis (le jeton existe déjà). Exposer `web::Data<PgQr>`.
