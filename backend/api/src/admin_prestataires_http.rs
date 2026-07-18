//! Administration des prestataires (FR-012 — les ÉCRANS arrivent au cycle
//! ADM, tranche T3 ; ici l'API, protégée par le rôle admin et journalisée).
//!
//! Toute décision passe par les méthodes de domaine qui journalisent (colonnes
//! `statut_*`, auteur, source) et émettent l'événement outbox dans la MÊME
//! transaction (constitution VI). Cette surface sert AUSSI le contact
//! téléphonique, les coordonnées GPS du site, la charte présignée et
//! l'identité de plaque — données que la consultation publique ne sert JAMAIS
//! (SC-013).

use actix_multipart::form::{bytes::Bytes as ChampFichier, text::Text, MultipartForm};
use actix_web::{delete, get, post, put, web, HttpResponse};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::Role;
use prestataires::{
    ModificationPrestataire, NouveauPrestataire, PgPrestataires, Prestataire,
};

use crate::auth_http::{Auth, ErreurApiDto};
use crate::prestataires_http::{
    sql, ErreurPresta, HorairesSemaineDto, StatutBoutiqueDto, StatutPrestataireDto, PRESIGNEE_TTL,
};

// ── DTO ────────────────────────────────────────────────────────────────────

/// Création d'une fiche (statut initial : prospect).
#[derive(Debug, Deserialize, ToSchema)]
pub struct CreerPrestataireDto {
    /// Nom public.
    #[schema(min_length = 1, max_length = 120)]
    pub nom: String,
    /// Slug de la catégorie de service (référentiel ZON).
    pub categorie_slug: String,
    /// Ville de rattachement — type `ville` exigé (FR-002).
    pub ville_id: Uuid,
    /// Contact téléphonique (servi à l'admin seulement).
    pub contact_telephone: String,
    /// Délai de préparation moyen déclaré (minutes).
    #[schema(minimum = 0)]
    pub delai_preparation_min: i32,
}

/// Modification partielle de la fiche.
#[derive(Debug, Deserialize, ToSchema)]
pub struct ModifierPrestataireDto {
    /// Nouveau nom.
    #[schema(min_length = 1, max_length = 120)]
    pub nom: Option<String>,
    /// Nouveau contact.
    pub contact_telephone: Option<String>,
    /// Nouveau délai (minutes).
    #[schema(minimum = 0)]
    pub delai_preparation_min: Option<i32>,
}

/// Résumé admin d'un prestataire.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PrestataireAdmin)]
pub struct PrestataireAdminDto {
    /// Identifiant.
    pub id: Uuid,
    /// Nom public.
    pub nom: String,
    /// Slug de la catégorie de service.
    pub categorie: String,
    /// Ville de rattachement.
    pub ville_id: Uuid,
    /// Cycle de vie.
    pub statut: StatutPrestataireDto,
    /// Contact téléphonique — surface ADMIN uniquement.
    pub contact_telephone: String,
    /// Délai de préparation (minutes).
    pub delai_preparation_min: i32,
    /// FR-028, dérivé à la lecture.
    pub commandable: bool,
}

/// Photo de fiche, présignée pour l'admin.
#[derive(Debug, Serialize, ToSchema)]
pub struct PhotoAdminDto {
    /// Identifiant (pour la suppression).
    pub id: Uuid,
    /// URL présignée (TTL 10 min).
    pub url: String,
    /// Ordre d'affichage.
    pub position: i32,
}

/// Charte signée, présignée pour l'admin (pièce contractuelle — FR-003).
#[derive(Debug, Serialize, ToSchema)]
pub struct CharteAdminDto {
    /// Identifiant.
    pub id: Uuid,
    /// Version de charte en vigueur à la signature.
    pub version_charte: String,
    /// Date de signature manuscrite.
    pub signee_le: NaiveDate,
    /// Dépôt du scan.
    pub deposee_le: DateTime<Utc>,
    /// URL présignée de lecture (TTL 10 min).
    pub url: String,
}

/// LE site unique, vue admin (GPS compris — jamais servi en public).
#[derive(Debug, Serialize, ToSchema)]
pub struct SiteAdminVueDto {
    /// Latitude relevée sur place.
    pub position_lat: f64,
    /// Longitude.
    pub position_lng: f64,
    /// Statut DÉCLARÉ de la boutique.
    pub statut_boutique: StatutBoutiqueDto,
    /// Échéance de pause, le cas échéant.
    pub pause_fin: Option<DateTime<Utc>>,
    /// Horaires hebdomadaires.
    pub horaires: HorairesSemaineDto,
}

/// Rattachement compte ↔ prestataire.
#[derive(Debug, Serialize, ToSchema)]
pub struct RattachementDto {
    /// Compte rattaché.
    pub compte_id: Uuid,
    /// Depuis quand.
    pub rattache_le: DateTime<Utc>,
}

/// Fiche COMPLÈTE, vue admin.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PrestataireAdminDetail)]
pub struct PrestataireAdminDetailDto {
    /// Résumé.
    #[serde(flatten)]
    pub resume: PrestataireAdminDto,
    /// Auteur de la dernière décision de cycle de vie.
    pub statut_decide_par: Option<Uuid>,
    /// Horodatage de la dernière décision.
    pub statut_decide_le: Option<DateTime<Utc>>,
    /// Motif de la dernière décision (suspension).
    pub statut_motif: Option<String>,
    /// Jeton de plaque (posé au premier agrément, stable — FR-013).
    pub jeton_plaque: Option<String>,
    /// Code de secours — AUCUNE recherche par ce code n'existe (FR-014).
    pub code_secours: Option<String>,
    /// Photos présignées.
    pub photos: Vec<PhotoAdminDto>,
    /// Chartes déposées, la plus récente d'abord.
    pub chartes: Vec<CharteAdminDto>,
    /// LE site unique, s'il est créé.
    pub site: Option<SiteAdminVueDto>,
    /// Comptes rattachés.
    pub rattachements: Vec<RattachementDto>,
}

/// Corps de `PUT /admin/prestataires/{id}/site` — upsert du site UNIQUE
/// (FR-019 : aucune sélection de site n'existe nulle part).
#[derive(Debug, Deserialize, ToSchema)]
pub struct SiteAdminDto {
    /// Latitude relevée sur place.
    pub position_lat: f64,
    /// Longitude.
    pub position_lng: f64,
    /// Horaires hebdomadaires (remplacement complet).
    pub horaires: HorairesSemaineDto,
    /// Statut initial — à la CRÉATION seulement (`ouvert` par défaut ;
    /// `en_pause`/`ferme_journee` refusés).
    pub statut_initial: Option<StatutBoutiqueDto>,
}

/// Filtres de la liste admin (lus en texte — la `QueryConfig` unique de l'app
/// appartient à `zones_http`, patron du cycle 003).
#[derive(Debug, Deserialize)]
pub struct FiltrePrestataires {
    /// `prospect` | `agree` | `suspendu`.
    pub statut: Option<String>,
    /// Ville de rattachement.
    pub ville: Option<Uuid>,
    /// Slug de catégorie.
    pub categorie: Option<String>,
}

// ── Assemblage des vues ────────────────────────────────────────────────────

async fn resume(
    depot: &PgPrestataires,
    p: &Prestataire,
) -> Result<PrestataireAdminDto, ErreurPresta> {
    let commandable = depot.commandabilite(p.id).await?.commandable();
    Ok(PrestataireAdminDto {
        id: p.id,
        nom: p.nom.clone(),
        categorie: p.categorie_slug.clone(),
        ville_id: p.ville_id,
        statut: p.statut.into(),
        contact_telephone: p.contact_telephone.clone(),
        delai_preparation_min: p.delai_preparation_min,
        commandable,
    })
}

async fn detail(
    depot: &PgPrestataires,
    prestataire: Uuid,
) -> Result<PrestataireAdminDetailDto, ErreurPresta> {
    let p = depot.prestataire(prestataire).await?;
    let resume = resume(depot, &p).await?;

    let mut photos = Vec::new();
    for photo in depot.photos(prestataire).await? {
        let url = depot
            .objets()
            .presigner_get(&photo.cle_objet, PRESIGNEE_TTL)
            .await
            .map_err(prestataires::ErreurPrestataires::from)?
            .url;
        photos.push(PhotoAdminDto {
            id: photo.id,
            url,
            position: photo.position,
        });
    }
    let mut chartes = Vec::new();
    for charte in depot.chartes(prestataire).await? {
        let url = depot
            .objets()
            .presigner_get(&charte.cle_objet, PRESIGNEE_TTL)
            .await
            .map_err(prestataires::ErreurPrestataires::from)?
            .url;
        chartes.push(CharteAdminDto {
            id: charte.id,
            version_charte: charte.version_charte,
            signee_le: charte.signee_le,
            deposee_le: charte.deposee_le,
            url,
        });
    }
    let site = depot
        .boutique(prestataire)
        .await?
        .map(|(site, horaires, _)| SiteAdminVueDto {
            position_lat: site.position_lat,
            position_lng: site.position_lng,
            statut_boutique: site.statut_boutique.into(),
            pause_fin: site.pause_fin,
            horaires: HorairesSemaineDto::from(&horaires),
        });
    let rattachements = depot
        .rattachements(prestataire)
        .await?
        .into_iter()
        .map(|r| RattachementDto {
            compte_id: r.compte_id,
            rattache_le: r.rattache_le,
        })
        .collect();

    Ok(PrestataireAdminDetailDto {
        resume,
        statut_decide_par: p.statut_decide_par,
        statut_decide_le: p.statut_decide_le,
        statut_motif: p.statut_motif,
        jeton_plaque: p.jeton_plaque,
        code_secours: p.code_secours,
        photos,
        chartes,
        site,
        rattachements,
    })
}

// ── Fiche (FR-002, FR-012) ─────────────────────────────────────────────────

/// Crée un prestataire (prospect) — ville de type `ville` uniquement.
#[utoipa::path(
    post,
    path = "/admin/prestataires",
    tag = "admin",
    request_body = CreerPrestataireDto,
    responses(
        (status = 201, description = "Fiche créée à l'état prospect, extension vendeur et plan \
         « gratuit » posés. Émet `prestataire.cree`.", body = PrestataireAdminDto),
        (status = 422, description = "Zone qui n'est pas une ville, catégorie inconnue, champ \
         vide.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/prestataires")]
pub async fn creer_prestataire(
    auth: Auth,
    corps: web::Json<CreerPrestataireDto>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let corps = corps.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let p = depot
        .creer_prestataire(
            &mut tx,
            &NouveauPrestataire {
                nom: corps.nom,
                categorie_slug: corps.categorie_slug,
                ville_id: corps.ville_id,
                contact_telephone: corps.contact_telephone,
                delai_preparation_min: corps.delai_preparation_min,
            },
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;

    Ok(HttpResponse::Created().json(resume(&depot, &p).await?))
}

/// Liste les prestataires (filtres statut / ville / catégorie).
#[utoipa::path(
    get,
    path = "/admin/prestataires",
    tag = "admin",
    params(
        ("statut" = Option<String>, Query, description = "prospect | agree | suspendu."),
        ("ville" = Option<Uuid>, Query, description = "Ville de rattachement."),
        ("categorie" = Option<String>, Query, description = "Slug de catégorie."),
    ),
    responses(
        (status = 200, description = "Prestataires, plus anciens d'abord.",
         body = [PrestataireAdminDto]),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/prestataires")]
pub async fn lister_prestataires(
    auth: Auth,
    filtre: web::Query<FiltrePrestataires>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let statut = match filtre.statut.as_deref() {
        None => None,
        Some(s) => Some(s.parse().map_err(|_| ErreurPresta::CorpsInvalide)?),
    };
    let lignes = depot
        .lister(statut, filtre.ville, filtre.categorie.as_deref())
        .await?;
    let mut sortie = Vec::with_capacity(lignes.len());
    for p in &lignes {
        sortie.push(resume(&depot, p).await?);
    }
    Ok(HttpResponse::Ok().json(sortie))
}

/// Fiche complète (contact, GPS, plaque, chartes présignées, rattachements).
#[utoipa::path(
    get,
    path = "/admin/prestataires/{id}",
    tag = "admin",
    params(("id" = Uuid, Path, description = "Prestataire.")),
    responses(
        (status = 200, description = "Vue admin complète — la SEULE surface qui serve le \
         contact et les coordonnées du site (SC-013).", body = PrestataireAdminDetailDto),
        (status = 404, description = "Prestataire inconnu.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/prestataires/{id}")]
pub async fn consulter_prestataire_admin(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    Ok(HttpResponse::Ok().json(detail(&depot, chemin.into_inner()).await?))
}

/// Modifie la fiche (nom, contact, délai) — administrable à tout statut.
#[utoipa::path(
    put,
    path = "/admin/prestataires/{id}",
    tag = "admin",
    params(("id" = Uuid, Path, description = "Prestataire.")),
    request_body = ModifierPrestataireDto,
    responses(
        (status = 200, description = "Fiche mise à jour. Émet `prestataire.modifie` (noms de \
         champs seulement — FR-052).", body = PrestataireAdminDto),
        (status = 404, description = "Prestataire inconnu.", body = ErreurApiDto),
        (status = 422, description = "Champ invalide.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[put("/admin/prestataires/{id}")]
pub async fn modifier_prestataire(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<ModifierPrestataireDto>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let corps = corps.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let p = depot
        .modifier_prestataire(
            &mut tx,
            chemin.into_inner(),
            &ModificationPrestataire {
                nom: corps.nom,
                contact_telephone: corps.contact_telephone,
                delai_preparation_min: corps.delai_preparation_min,
            },
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok().json(resume(&depot, &p).await?))
}

// ── Photos de fiche (FR-025/026) ───────────────────────────────────────────

/// Photo envoyée en multipart (≤ 5 Mo, jpeg/png/webp).
#[derive(Debug, ToSchema)]
#[schema(as = DepotPhoto)]
#[allow(dead_code)] // vu par utoipa seulement — jamais construit
pub struct DepotPhotoDto {
    /// La photo.
    #[schema(value_type = String, format = Binary)]
    pub fichier: Vec<u8>,
}

/// Corps multipart réellement analysé.
#[derive(Debug, MultipartForm)]
pub struct PhotoForm {
    #[multipart(limit = "5MB")]
    fichier: ChampFichier,
}

impl PhotoForm {
    /// Octets + type MIME déclaré (chaîne vide si absent — refusé au domaine).
    pub(crate) fn contenu(self) -> (Vec<u8>, String) {
        let mime = self
            .fichier
            .content_type
            .as_ref()
            .map(|m| m.to_string())
            .unwrap_or_default();
        (self.fichier.data.to_vec(), mime)
    }
}

/// Ajoute une photo de fiche.
#[utoipa::path(
    post,
    path = "/admin/prestataires/{id}/photos",
    tag = "admin",
    params(("id" = Uuid, Path, description = "Prestataire.")),
    request_body(content = DepotPhotoDto, content_type = "multipart/form-data"),
    responses(
        (status = 201, description = "Photo déposée (clé S3 neuve), en dernière position.",
         body = PhotoAdminDto),
        (status = 404, description = "Prestataire inconnu.", body = ErreurApiDto),
        (status = 422, description = "Type refusé ou fichier trop volumineux.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/prestataires/{id}/photos")]
pub async fn ajouter_photo(
    auth: Auth,
    chemin: web::Path<Uuid>,
    MultipartForm(form): MultipartForm<PhotoForm>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let mime = form
        .fichier
        .content_type
        .as_ref()
        .map(|m| m.to_string())
        .unwrap_or_default();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let photo = depot
        .ajouter_photo(
            &mut tx,
            chemin.into_inner(),
            form.fichier.data.to_vec(),
            &mime,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;

    let url = depot
        .objets()
        .presigner_get(&photo.cle_objet, PRESIGNEE_TTL)
        .await
        .map_err(prestataires::ErreurPrestataires::from)?
        .url;
    Ok(HttpResponse::Created().json(PhotoAdminDto {
        id: photo.id,
        url,
        position: photo.position,
    }))
}

/// Supprime une photo de fiche (objet S3 purgé APRÈS commit — FR-026).
#[utoipa::path(
    delete,
    path = "/admin/prestataires/{id}/photos/{photo_id}",
    tag = "admin",
    params(
        ("id" = Uuid, Path, description = "Prestataire."),
        ("photo_id" = Uuid, Path, description = "Photo à supprimer."),
    ),
    responses(
        (status = 204, description = "Supprimée — l'objet S3 est purgé après le commit."),
        (status = 404, description = "Photo ou prestataire inconnus.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[delete("/admin/prestataires/{id}/photos/{photo_id}")]
pub async fn supprimer_photo(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let (prestataire, photo) = chemin.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let cle_orpheline = depot
        .supprimer_photo(&mut tx, prestataire, photo, auth.compte_id)
        .await?;
    tx.commit().await.map_err(sql)?;

    // APRÈS le commit seulement — avant, un rollback ferait pointer la ligne
    // vers un objet absent (patron du cycle 003).
    if let Err(e) = depot.objets().supprimer(&cle_orpheline).await {
        tracing::warn!(cle = %cle_orpheline, erreur = %e,
            "photo déréférencée en base, objet non supprimé — à rattraper");
    }
    Ok(HttpResponse::NoContent().finish())
}

// ── Charte signée (FR-003) ─────────────────────────────────────────────────

/// Scan de charte signée + métadonnées de signature.
#[derive(Debug, ToSchema)]
#[schema(as = DeposerCharte)]
#[allow(dead_code)] // vu par utoipa seulement — jamais construit
pub struct DeposerCharteDto {
    /// Le scan — ≤ 10 Mo, jpeg/png/webp/pdf.
    #[schema(value_type = String, format = Binary)]
    pub fichier: Vec<u8>,
    /// Version de charte en vigueur à la signature.
    pub version_charte: String,
    /// Date de signature (AAAA-MM-JJ).
    #[schema(value_type = String, format = Date)]
    pub signee_le: String,
}

/// Corps multipart réellement analysé.
#[derive(Debug, MultipartForm)]
pub struct CharteForm {
    #[multipart(limit = "10MB")]
    fichier: ChampFichier,
    version_charte: Text<String>,
    signee_le: Text<String>,
}

/// Dépose la charte signée scannée — condition NÉCESSAIRE de l'agrément.
#[utoipa::path(
    post,
    path = "/admin/prestataires/{id}/charte",
    tag = "admin",
    params(("id" = Uuid, Path, description = "Prestataire.")),
    request_body(content = DeposerCharteDto, content_type = "multipart/form-data"),
    responses(
        (status = 201, description = "Charte déposée (0..n par prestataire — une re-signature \
         n'écrase jamais). Émet `charte.deposee`.", body = CharteAdminDto),
        (status = 404, description = "Prestataire inconnu.", body = ErreurApiDto),
        (status = 422, description = "Type refusé, fichier trop volumineux, version vide ou \
         date illisible.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/prestataires/{id}/charte")]
pub async fn deposer_charte(
    auth: Auth,
    chemin: web::Path<Uuid>,
    MultipartForm(form): MultipartForm<CharteForm>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let signee_le: NaiveDate = form
        .signee_le
        .parse()
        .map_err(|_| ErreurPresta::CorpsInvalide)?;
    let mime = form
        .fichier
        .content_type
        .as_ref()
        .map(|m| m.to_string())
        .unwrap_or_default();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let charte = depot
        .deposer_charte(
            &mut tx,
            chemin.into_inner(),
            form.fichier.data.to_vec(),
            &mime,
            &form.version_charte,
            signee_le,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;

    let url = depot
        .objets()
        .presigner_get(&charte.cle_objet, PRESIGNEE_TTL)
        .await
        .map_err(prestataires::ErreurPrestataires::from)?
        .url;
    Ok(HttpResponse::Created().json(CharteAdminDto {
        id: charte.id,
        version_charte: charte.version_charte,
        signee_le: charte.signee_le,
        deposee_le: charte.deposee_le,
        url,
    }))
}

// ── Agrément (FR-004/005, VND-01) ──────────────────────────────────────────

/// Agrée un prospect : la fiche devient servie et commandable, l'identité de
/// plaque est créée au premier passage, l'activation de catégorie recalculée.
#[utoipa::path(
    post,
    path = "/admin/prestataires/{id}/agrement",
    tag = "admin",
    params(("id" = Uuid, Path, description = "Prestataire (prospect).")),
    responses(
        (status = 200, description = "Agréé — jeton de plaque + code de secours posés au \
         PREMIER agrément (FR-013), compteur de la catégorie recalculé dans la même \
         transaction (SC-010). Émet `prestataire.agree`.", body = PrestataireAdminDetailDto),
        (status = 409, description = "Transition interdite (déjà agréé, suspendu — FR-004).",
         body = ErreurApiDto),
        (status = 422, description = "Agrément incomplet — le corps porte `manques` \
         (identifiants stables : `photo`, `charte_signee`, `site`, `horaires` — FR-005).",
         body = ErreurApiDto),
        (status = 404, description = "Prestataire inconnu.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/prestataires/{id}/agrement")]
pub async fn agreer_prestataire(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let prestataire = chemin.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    depot.agreer(&mut tx, prestataire, auth.compte_id).await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok().json(detail(&depot, prestataire).await?))
}

// ── Rattachements (FR-006..008) ────────────────────────────────────────────

/// Corps du rattachement.
#[derive(Debug, Deserialize, ToSchema)]
pub struct RattacherCompteDto {
    /// Compte vérifié à rattacher.
    pub compte_id: Uuid,
}

/// Rattache un compte vérifié — attribue le rôle vendeur si absent,
/// IDEMPOTENT (FR-007, research R11).
#[utoipa::path(
    post,
    path = "/admin/prestataires/{id}/rattachements",
    tag = "admin",
    params(("id" = Uuid, Path, description = "Prestataire AGRÉÉ.")),
    request_body = RattacherCompteDto,
    responses(
        (status = 200, description = "Rattaché (ou déjà rattaché — même réponse, rien rejoué). \
         Le rôle vendeur est attribué si le compte n'en portait aucun : l'agrément vaut \
         validation.", body = PrestataireAdminDetailDto),
        (status = 409, description = "Prestataire non agréé — le rattachement exige l'état \
         agree (FR-007, analyse A1).", body = ErreurApiDto),
        (status = 404, description = "Prestataire ou compte inconnus.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/prestataires/{id}/rattachements")]
pub async fn rattacher_compte(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<RattacherCompteDto>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let prestataire = chemin.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let issue = depot
        .rattacher_compte(&mut tx, prestataire, corps.compte_id, auth.compte_id)
        .await;
    match issue {
        Ok(()) => {}
        // FR-007 (A1) : 409 — l'état du prestataire, pas un refus de rôle.
        Err(prestataires::ErreurPrestataires::PrestataireNonAgree(_)) => {
            return Err(ErreurPresta::TransitionInvalide);
        }
        Err(e) => return Err(e.into()),
    }
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok().json(detail(&depot, prestataire).await?))
}

/// Détache un compte — le rôle vendeur du compte ne bouge JAMAIS (FR-008).
#[utoipa::path(
    delete,
    path = "/admin/prestataires/{id}/rattachements/{compte_id}",
    tag = "admin",
    params(
        ("id" = Uuid, Path, description = "Prestataire."),
        ("compte_id" = Uuid, Path, description = "Compte à détacher."),
    ),
    responses(
        (status = 204, description = "Détaché. Émet `rattachement.supprime` — le rôle du \
         compte est INTACT (aucune cascade)."),
        (status = 404, description = "Rattachement inconnu.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[delete("/admin/prestataires/{id}/rattachements/{compte_id}")]
pub async fn detacher_compte(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let (prestataire, compte) = chemin.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    depot
        .detacher_compte(&mut tx, prestataire, compte, auth.compte_id)
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::NoContent().finish())
}

// ── Site unique (FR-018/019) ───────────────────────────────────────────────

/// Crée ou met à jour LE site (position GPS, horaires, statut initial).
#[utoipa::path(
    put,
    path = "/admin/prestataires/{id}/site",
    tag = "admin",
    params(("id" = Uuid, Path, description = "Prestataire.")),
    request_body = SiteAdminDto,
    responses(
        (status = 200, description = "Site en place. Un changement d'horaires émet \
         `site.horaires_modifies` (source admin — FR-036).", body = PrestataireAdminDetailDto),
        (status = 404, description = "Prestataire inconnu.", body = ErreurApiDto),
        (status = 422, description = "Horaires invalides ou statut initial illégal.",
         body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[put("/admin/prestataires/{id}/site")]
pub async fn definir_site(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<SiteAdminDto>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let prestataire = chemin.into_inner();
    let corps = corps.into_inner();
    let horaires = corps.horaires.vers_domaine()?;

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    depot
        .definir_site(
            &mut tx,
            prestataire,
            corps.position_lat,
            corps.position_lng,
            &horaires,
            corps.statut_initial.map(Into::into),
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok().json(detail(&depot, prestataire).await?))
}

// ── Catalogue côté ADMIN (US2 — saisie pendant la visite d'agrément) ───────
// Mêmes méthodes de domaine que /vendeur, source = admin (research R12) —
// c'est ainsi que le catalogue de Tantie Affoué, sans app, est tenu.

/// Crée un article pour le compte du prestataire (source admin).
#[utoipa::path(
    post,
    path = "/admin/prestataires/{id}/articles",
    tag = "admin",
    params(("id" = Uuid, Path, description = "Prestataire.")),
    request_body = crate::prestataires_http::CreerArticleDto,
    responses(
        (status = 201, description = "Article créé (source admin). Émet `article.cree`.",
         body = crate::prestataires_http::ArticleVendeurDto),
        (status = 422, description = "Prix barré ≤ prix, montant négatif, nom vide.",
         body = ErreurApiDto),
        (status = 404, description = "Prestataire inconnu.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/prestataires/{id}/articles")]
pub async fn creer_article_admin(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<crate::prestataires_http::CreerArticleDto>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let prestataire = chemin.into_inner();
    let corps = corps.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let article = depot
        .creer_article(
            &mut tx,
            prestataire,
            &prestataires::NouvelArticle {
                nom: corps.nom,
                prix_unites: corps.prix_unites,
                prix_barre_unites: corps.prix_barre_unites,
                categorie_interne: corps.categorie_interne,
            },
            prestataires::SourceBascule::Admin,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Created()
        .json(crate::prestataires_http::article_vendeur_dto(&depot, article).await?))
}

/// Modifie un article (source admin).
#[utoipa::path(
    put,
    path = "/admin/prestataires/{id}/articles/{article_id}",
    tag = "admin",
    params(
        ("id" = Uuid, Path, description = "Prestataire."),
        ("article_id" = Uuid, Path, description = "Article."),
    ),
    request_body = crate::prestataires_http::ModifierArticleDto,
    responses(
        (status = 200, description = "Modifié. Émet `article.modifie`.",
         body = crate::prestataires_http::ArticleVendeurDto),
        (status = 422, description = "Prix barré qui deviendrait ≤ prix : échec explicite.",
         body = ErreurApiDto),
        (status = 404, description = "Article inconnu ou retiré.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[put("/admin/prestataires/{id}/articles/{article_id}")]
pub async fn modifier_article_admin(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    corps: web::Json<crate::prestataires_http::ModifierArticleDto>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let (prestataire, article) = chemin.into_inner();
    let corps = corps.into_inner();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let article = depot
        .modifier_article(
            &mut tx,
            prestataire,
            article,
            &prestataires::ModificationArticle {
                nom: corps.nom,
                prix_unites: corps.prix_unites,
                // `retirer_prix_barre` ≡ `prix_barre_unites: null` (clients
                // générés — built_value ne sérialise pas un null explicite).
                prix_barre_unites: if corps.retirer_prix_barre.unwrap_or(false) {
                    Some(None)
                } else {
                    corps.prix_barre_unites
                },
                categorie_interne: corps.categorie_interne,
            },
            prestataires::SourceBascule::Admin,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok()
        .json(crate::prestataires_http::article_vendeur_dto(&depot, article).await?))
}

/// Photo d'article (source admin).
#[utoipa::path(
    post,
    path = "/admin/prestataires/{id}/articles/{article_id}/photo",
    tag = "admin",
    params(
        ("id" = Uuid, Path, description = "Prestataire."),
        ("article_id" = Uuid, Path, description = "Article."),
    ),
    request_body(content = DepotPhotoDto, content_type = "multipart/form-data"),
    responses(
        (status = 200, description = "Photo remplacée.",
         body = crate::prestataires_http::ArticleVendeurDto),
        (status = 422, description = "Type refusé ou fichier trop volumineux.", body = ErreurApiDto),
        (status = 404, description = "Article inconnu ou retiré.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/prestataires/{id}/articles/{article_id}/photo")]
pub async fn photo_article_admin(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    MultipartForm(form): MultipartForm<PhotoForm>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let (prestataire, article) = chemin.into_inner();
    let (octets, mime) = form.contenu();

    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let (article, orpheline) = depot
        .photo_article(
            &mut tx,
            prestataire,
            article,
            octets,
            &mime,
            prestataires::SourceBascule::Admin,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    if let Some(cle) = orpheline {
        if let Err(e) = depot.objets().supprimer(&cle).await {
            tracing::warn!(cle = %cle, erreur = %e, "photo d'article remplacée non purgée");
        }
    }
    Ok(HttpResponse::Ok()
        .json(crate::prestataires_http::article_vendeur_dto(&depot, article).await?))
}

/// Retire un article du catalogue (source admin — FR-055).
#[utoipa::path(
    post,
    path = "/admin/prestataires/{id}/articles/{article_id}/retrait",
    tag = "admin",
    params(
        ("id" = Uuid, Path, description = "Prestataire."),
        ("article_id" = Uuid, Path, description = "Article."),
    ),
    responses(
        (status = 200, description = "Retiré (réversible). Émet `article.retire_du_catalogue`.",
         body = crate::prestataires_http::ArticleVendeurDto),
        (status = 404, description = "Article inconnu.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/prestataires/{id}/articles/{article_id}/retrait")]
pub async fn retirer_article_admin(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let (prestataire, article) = chemin.into_inner();
    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let article = depot
        .retirer_article(
            &mut tx,
            prestataire,
            article,
            prestataires::SourceBascule::Admin,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok()
        .json(crate::prestataires_http::article_vendeur_dto(&depot, article).await?))
}

/// Remet un article retiré au catalogue (source admin — FR-055).
#[utoipa::path(
    post,
    path = "/admin/prestataires/{id}/articles/{article_id}/remise",
    tag = "admin",
    params(
        ("id" = Uuid, Path, description = "Prestataire."),
        ("article_id" = Uuid, Path, description = "Article."),
    ),
    responses(
        (status = 200, description = "Remis au catalogue. Émet `article.remis_au_catalogue`.",
         body = crate::prestataires_http::ArticleVendeurDto),
        (status = 404, description = "Article inconnu.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/prestataires/{id}/articles/{article_id}/remise")]
pub async fn remettre_article_admin(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    auth.exiger_role(Role::Admin).map_err(ErreurPresta::from)?;
    let (prestataire, article) = chemin.into_inner();
    let mut tx = depot.pool().begin().await.map_err(sql)?;
    let article = depot
        .remettre_article(
            &mut tx,
            prestataire,
            article,
            prestataires::SourceBascule::Admin,
            auth.compte_id,
        )
        .await?;
    tx.commit().await.map_err(sql)?;
    Ok(HttpResponse::Ok()
        .json(crate::prestataires_http::article_vendeur_dto(&depot, article).await?))
}
