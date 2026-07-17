//! Surface HTTP des adresses enregistrées (CPT-05, `/moi/adresses*`).
//!
//! Tout y est strictement personnel : l'adresse d'autrui est INTROUVABLE, pas
//! interdite — un 403 confirmerait à un curieux qu'il a visé juste. La
//! propriété est dans le `WHERE` du domaine, pas dans un contrôle après coup.

use actix_multipart::form::{bytes::Bytes as ChampFichier, text::Text, MultipartForm};
use actix_web::{delete, get, patch, post, web, HttpResponse};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::adresse::{ModificationAdresse, NoteVocale, NouvelleAdresse};
use comptes::{Adresse, PgComptes};

use crate::auth_http::{Auth, ErreurApi, ErreurApiDto};

/// Durée de vie des URLs présignées de repère vocal (research R7).
const PRESIGNEE_TTL: std::time::Duration = std::time::Duration::from_secs(10 * 60);

/// Adresse enregistrée (contrat).
///
/// ⚠ N'expose NI `compte_id` (implicite : c'est le vôtre), NI la clé S3 du
/// repère, NI `supprimee_le`, NI `livraison_origine` (provision CPT-06).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = Adresse)]
pub struct AdresseDto {
    /// Identifiant = `Idempotency-Key` du POST créateur (R14).
    pub id: Uuid,
    /// « Maison », « Bureau » ou libre.
    pub libelle: String,
    /// Latitude du pin GPS.
    pub lat: f64,
    /// Longitude du pin GPS.
    pub lng: f64,
    /// Repère écrit.
    pub repere_texte: Option<String>,
    /// `false` après purge (12 mois sans utilisation — FR-022).
    pub a_repere_vocal: bool,
    /// Durée du repère vocal.
    pub repere_vocal_duree_s: Option<i32>,
    /// Zone de l'adresse.
    pub zone_id: Uuid,
    /// Enregistrement.
    pub cree_le: DateTime<Utc>,
    /// Base de la purge.
    pub derniere_utilisation_le: DateTime<Utc>,
}

impl From<Adresse> for AdresseDto {
    fn from(a: Adresse) -> Self {
        AdresseDto {
            id: a.id,
            libelle: a.libelle,
            lat: a.lat,
            lng: a.lng,
            repere_texte: a.repere_texte,
            a_repere_vocal: a.repere_vocal_cle_objet.is_some(),
            // La colonne est un `smallint` (une note vocale dure des secondes,
            // pas des heures) ; le contrat, lui, parle d'un entier.
            repere_vocal_duree_s: a.repere_vocal_duree_s.map(i32::from),
            zone_id: a.zone_id,
            cree_le: a.cree_le,
            derniere_utilisation_le: a.derniere_utilisation_le,
        }
    }
}

/// URL présignée de lecture (contrat).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = UrlPresignee)]
pub struct UrlPresigneeDto {
    /// URL opaque, à durée courte.
    pub url: String,
    /// Expiration.
    pub expire_le: DateTime<Utc>,
}

// DTO de CONTRAT uniquement : le parsing passe par `NouvelleAdresseForm`, qui
// doit rester aligné champ pour champ.
/// Adresse à enregistrer après une livraison réussie (FR-019).
#[derive(Debug, ToSchema)]
#[schema(as = NouvelleAdresse)]
#[allow(dead_code)] // vu par utoipa seulement — jamais construit
pub struct NouvelleAdresseDto {
    /// « Maison », « Bureau » ou libre.
    #[schema(max_length = 60)]
    pub libelle: String,
    /// Latitude du pin GPS.
    pub lat: f64,
    /// Longitude du pin GPS.
    pub lng: f64,
    /// Repère écrit.
    #[schema(max_length = 500)]
    pub repere_texte: Option<String>,
    /// Repère parlé — ≤ 1,5 Mo, m4a/aac.
    #[schema(value_type = Option<String>, format = Binary)]
    pub note_vocale: Option<Vec<u8>>,
    /// Durée du repère parlé — bornée par le paramètre de zone
    /// `medias.note_vocale_duree_max_s`.
    pub duree_s: Option<i32>,
    /// PROVISION — posée par les cycles CMD/CRS ; aucune logique ne la lit.
    pub livraison_origine: Option<Uuid>,
}

/// Corps multipart réellement analysé.
#[derive(Debug, MultipartForm)]
pub struct NouvelleAdresseForm {
    libelle: Text<String>,
    lat: Text<f64>,
    lng: Text<f64>,
    repere_texte: Option<Text<String>>,
    #[multipart(limit = "1536KB")]
    note_vocale: Option<ChampFichier>,
    duree_s: Option<Text<i16>>,
    livraison_origine: Option<Text<Uuid>>,
}

// DTO de CONTRAT uniquement (même raison que ci-dessus).
/// Nouveau repère parlé pour une adresse existante.
#[derive(Debug, ToSchema)]
#[schema(as = RemplacementRepereVocal)]
#[allow(dead_code)] // vu par utoipa seulement — jamais construit
pub struct RemplacementRepereVocalDto {
    /// Repère parlé — ≤ 1,5 Mo, m4a/aac.
    #[schema(value_type = String, format = Binary)]
    pub note_vocale: Vec<u8>,
    /// Durée — bornée par le paramètre de zone `medias.note_vocale_duree_max_s`.
    pub duree_s: i32,
}

/// Corps multipart réellement analysé.
#[derive(Debug, MultipartForm)]
pub struct RepereVocalForm {
    #[multipart(limit = "1536KB")]
    note_vocale: ChampFichier,
    duree_s: Text<i16>,
}

/// Champs modifiables d'une adresse (contrat).
#[derive(Debug, Deserialize, ToSchema)]
pub struct ModifierAdresse {
    /// Nouveau libellé — absent = inchangé.
    #[schema(max_length = 60)]
    pub libelle: Option<String>,
    /// Nouveau repère écrit — absent = inchangé, `null` = effacé.
    ///
    /// Le double `Option` porte cette nuance : sans lui, « ne touche pas » et
    /// « efface » seraient le même corps JSON.
    #[serde(default, deserialize_with = "double_option")]
    #[schema(max_length = 500)]
    pub repere_texte: Option<Option<String>>,
}

/// Distingue un champ ABSENT (`None`) d'un champ à `null` (`Some(None)`).
fn double_option<'de, D>(d: D) -> Result<Option<Option<String>>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    Ok(Some(Option::<String>::deserialize(d)?))
}

/// Construit la note vocale du domaine à partir du multipart.
fn note_vocale(champ: ChampFichier, duree_s: i16) -> NoteVocale {
    NoteVocale {
        octets: champ.data.to_vec(),
        mime: champ
            .content_type
            .map(|m| m.to_string())
            .unwrap_or_default(),
        duree_s,
    }
}

/// Lit l'en-tête `Idempotency-Key` (REQUIS — R14). Il DEVIENT l'id de l'adresse.
fn idempotency_key(requete: &actix_web::HttpRequest) -> Result<Uuid, ErreurApi> {
    requete
        .headers()
        .get("idempotency-key")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse::<Uuid>().ok())
        .ok_or(ErreurApi::CorpsInvalide)
}

/// Adresses enregistrées du compte courant (FR-021).
#[utoipa::path(
    get,
    path = "/moi/adresses",
    tag = "moi",
    responses(
        (status = 200, description = "Adresses vivantes, la plus récemment utilisée d'abord.",
         body = Vec<AdresseDto>),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/moi/adresses")]
pub async fn mes_adresses(
    auth: Auth,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let adresses = depot.adresses(auth.compte_id).await?;
    let dtos: Vec<AdresseDto> = adresses.into_iter().map(AdresseDto::from).collect();
    Ok(HttpResponse::Ok().json(dtos))
}

/// Enregistre une adresse — proposition post-livraison acceptée (FR-019).
#[utoipa::path(
    post,
    path = "/moi/adresses",
    tag = "moi",
    params(
        ("Idempotency-Key" = Uuid, Header,
         description = "UUIDv7 généré par le client — DEVIENT l'id de l'adresse (R14)."),
    ),
    request_body(content = NouvelleAdresseDto, content_type = "multipart/form-data"),
    responses(
        (status = 201, description = "Adresse enregistrée — émet `adresse.enregistree`. \
         Un rejeu de la même clé rend l'adresse EXISTANTE, sans doublon (R14).",
         body = AdresseDto),
        (status = 422, description = "Libellé, repère, durée (> paramètre de zone) ou note \
         vocale invalides ; en-tête d'idempotence absent.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/moi/adresses")]
pub async fn enregistrer_adresse(
    auth: Auth,
    requete: actix_web::HttpRequest,
    MultipartForm(form): MultipartForm<NouvelleAdresseForm>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    // La clé DEVIENT l'id : c'est ce qui rend le POST rejouable sans table
    // d'idempotence (R14).
    let id = idempotency_key(&requete)?;

    let note = match (form.note_vocale, form.duree_s) {
        (None, _) => None,
        // Une note sans durée annoncée est un corps incohérent : la durée est
        // ce que le paramètre de zone borne, on ne la devine pas des octets.
        (Some(_), None) => return Err(ErreurApi::CorpsInvalide),
        (Some(champ), Some(duree)) => Some(note_vocale(champ, duree.into_inner())),
    };

    let nouvelle = NouvelleAdresse {
        libelle: form.libelle.into_inner(),
        lat: form.lat.into_inner(),
        lng: form.lng.into_inner(),
        repere_texte: form.repere_texte.map(Text::into_inner),
        note_vocale: note,
        livraison_origine: form.livraison_origine.map(Text::into_inner),
    };

    let mut tx = depot
        .pool()
        .begin()
        .await
        .map_err(comptes::ErreurComptes::from)?;
    let ecriture = depot
        .enregistrer_adresse(&mut tx, id, auth.compte_id, &nouvelle)
        .await?;
    tx.commit().await.map_err(comptes::ErreurComptes::from)?;

    // Rejeu CONCURRENT perdu : notre note vocale a été déposée, mais c'est
    // l'adresse de la requête gagnante qui fait foi — la nôtre ne sera jamais
    // référencée. Après le commit, comme partout (constitution VIII).
    if let Some(cle) = ecriture.note_orpheline {
        crate::supprimer_objet_orphelin(&depot, &cle, "note vocale d'un rejeu concurrent").await;
    }

    Ok(HttpResponse::Created().json(AdresseDto::from(ecriture.adresse)))
}

/// Renomme l'adresse ou met à jour son repère écrit (FR-021).
#[utoipa::path(
    patch,
    path = "/moi/adresses/{adresse_id}",
    tag = "moi",
    params(("adresse_id" = Uuid, Path, description = "Adresse concernée.")),
    request_body = ModifierAdresse,
    responses(
        (status = 200, description = "Adresse modifiée — ne vaut que pour l'avenir.",
         body = AdresseDto),
        (status = 404, description = "Adresse inconnue ou n'appartenant pas au compte.",
         body = ErreurApiDto),
        (status = 422, description = "Libellé ou repère invalides.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[patch("/moi/adresses/{adresse_id}")]
pub async fn modifier_adresse(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<ModifierAdresse>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let id = chemin.into_inner();
    let modification = ModificationAdresse {
        libelle: corps.libelle.clone(),
        repere_texte: corps.repere_texte.clone(),
    };

    let mut tx = depot
        .pool()
        .begin()
        .await
        .map_err(comptes::ErreurComptes::from)?;
    let adresse = depot
        .modifier_adresse(&mut tx, id, auth.compte_id, &modification)
        .await?;
    tx.commit().await.map_err(comptes::ErreurComptes::from)?;

    Ok(HttpResponse::Ok().json(AdresseDto::from(adresse)))
}

/// Supprime l'adresse — soft (FR-021).
#[utoipa::path(
    delete,
    path = "/moi/adresses/{adresse_id}",
    tag = "moi",
    params(("adresse_id" = Uuid, Path, description = "Adresse concernée.")),
    responses(
        (status = 204, description = "Supprimée — émet `adresse.supprimee`. Sans effet sur les \
         livraisons passées."),
        (status = 404, description = "Adresse inconnue ou n'appartenant pas au compte.",
         body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[delete("/moi/adresses/{adresse_id}")]
pub async fn supprimer_adresse(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let id = chemin.into_inner();
    let mut tx = depot
        .pool()
        .begin()
        .await
        .map_err(comptes::ErreurComptes::from)?;
    depot.supprimer_adresse(&mut tx, id, auth.compte_id).await?;
    tx.commit().await.map_err(comptes::ErreurComptes::from)?;

    Ok(HttpResponse::NoContent().finish())
}

/// URL présignée de lecture du repère vocal (FR-020).
#[utoipa::path(
    get,
    path = "/moi/adresses/{adresse_id}/repere-vocal",
    tag = "moi",
    params(("adresse_id" = Uuid, Path, description = "Adresse concernée.")),
    responses(
        (status = 200, description = "Lien opaque, valable 10 min. Les octets rendus sont \
         IDENTIQUES à ceux enregistrés (SC-007).", body = UrlPresigneeDto),
        (status = 404, description = "Adresse inconnue, ou repère vocal absent/purgé (FR-022).",
         body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/moi/adresses/{adresse_id}/repere-vocal")]
pub async fn ecouter_repere_vocal(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let id = chemin.into_inner();
    let adresse = depot.adresse(id, auth.compte_id).await?;
    // Purgé (FR-022) : l'adresse existe, son repère non. Le contrat en fait un
    // 404 — c'est bien la RESSOURCE demandée qui n'est plus là.
    let cle = adresse
        .repere_vocal_cle_objet
        .ok_or(ErreurApi::Introuvable)?;

    let url = depot
        .objets()
        .presigner_get(&cle, PRESIGNEE_TTL)
        .await
        .map_err(comptes::ErreurComptes::from)?;

    Ok(HttpResponse::Ok().json(UrlPresigneeDto {
        url: url.url,
        expire_le: url.expire_le,
    }))
}

/// Enregistre un nouveau repère vocal — après purge, ou pour le refaire.
#[utoipa::path(
    post,
    path = "/moi/adresses/{adresse_id}/repere-vocal",
    tag = "moi",
    params(("adresse_id" = Uuid, Path, description = "Adresse concernée.")),
    request_body(content = RemplacementRepereVocalDto, content_type = "multipart/form-data"),
    responses(
        (status = 200, description = "Repère remplacé — émet `adresse.modifiee`.",
         body = AdresseDto),
        (status = 404, description = "Adresse inconnue ou n'appartenant pas au compte.",
         body = ErreurApiDto),
        (status = 422, description = "Durée (> paramètre de zone) ou note vocale invalides.",
         body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/moi/adresses/{adresse_id}/repere-vocal")]
pub async fn remplacer_repere_vocal(
    auth: Auth,
    chemin: web::Path<Uuid>,
    MultipartForm(form): MultipartForm<RepereVocalForm>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let id = chemin.into_inner();
    let note = note_vocale(form.note_vocale, form.duree_s.into_inner());

    let mut tx = depot
        .pool()
        .begin()
        .await
        .map_err(comptes::ErreurComptes::from)?;
    let ecriture = depot
        .remplacer_repere_vocal(&mut tx, id, auth.compte_id, &note)
        .await?;
    tx.commit().await.map_err(comptes::ErreurComptes::from)?;

    // L'adresse avait déjà un repère : l'ancien vient d'être déréférencé. Après
    // le commit — un rollback laisserait sinon l'adresse pointer vers du vide.
    if let Some(cle) = ecriture.note_orpheline {
        crate::supprimer_objet_orphelin(&depot, &cle, "repère vocal remplacé").await;
    }

    Ok(HttpResponse::Ok().json(AdresseDto::from(ecriture.adresse)))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;

    use actix_web::{http::StatusCode, test as atest, App};
    use comptes::{Appareil, MemoireEphemere, MemoireObjets, Plateforme, SmsTraces};
    use serde_json::json;
    use sqlx::PgPool;

    const TIASSALE: &str = "01900000-0000-7000-8000-000000000002";
    const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";

    /// Les octets EXACTS du repère parlé — c'est eux que SC-007 protège.
    const OCTETS_NOTE: &[u8] = b"\x00\x00\x00\x1cftypM4A octets-de-la-note-vocale";

    /// Le stockage objet mémoire est retenu à part : les tests doivent pouvoir
    /// relire ce qui a réellement été déposé.
    async fn preparer(pool: &PgPool) -> (PgComptes, Arc<MemoireObjets>) {
        crate::charger_seeds(pool).await.unwrap();
        let objets = Arc::new(MemoireObjets::new());
        let depot = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            objets.clone(),
            Arc::from(SECRET),
        );
        (depot, objets)
    }

    async fn creer_compte(depot: &PgComptes, numero: &str) -> Uuid {
        let mut tx = depot.pool().begin().await.unwrap();
        let compte = depot
            .creer_compte(&mut tx, numero, TIASSALE.parse().unwrap(), "2026-07")
            .await
            .unwrap();
        tx.commit().await.unwrap();
        compte.id
    }

    async fn jeton(depot: &PgComptes, compte: Uuid) -> String {
        let zone = depot.compte(compte).await.unwrap().zone_id;
        let mut tx = depot.pool().begin().await.unwrap();
        let (_, jetons) = depot
            .creer_session(
                &mut tx,
                compte,
                zone,
                &Appareil {
                    nom: "Pixel de poche".to_owned(),
                    plateforme: Plateforme::Android,
                },
                comptes::OrigineSession::VerificationOtp,
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
        jetons.acces
    }

    macro_rules! app {
        ($depot:expr) => {
            atest::init_service(
                App::new()
                    .app_data(web::Data::new($depot.clone()))
                    .app_data(crate::auth_http::config_json())
                    .app_data(crate::comptes_http::config_path())
                    .app_data(crate::comptes_http::config_multipart())
                    .service(mes_adresses)
                    .service(enregistrer_adresse)
                    .service(modifier_adresse)
                    .service(supprimer_adresse)
                    .service(ecouter_repere_vocal)
                    .service(remplacer_repere_vocal),
            )
            .await
        };
    }

    /// Corps multipart d'un enregistrement d'adresse — le format du CÂBLE.
    fn corps_adresse(libelle: &str, avec_note: bool, duree: Option<i16>) -> (String, Vec<u8>) {
        const B: &str = "----mefalitest";
        let mut corps: Vec<u8> = Vec::new();
        let mut champ = |nom: &str, valeur: &str| {
            corps.extend_from_slice(
                format!(
                    "--{B}\r\nContent-Disposition: form-data; name=\"{nom}\"\r\n\r\n{valeur}\r\n"
                )
                .as_bytes(),
            );
        };
        champ("libelle", libelle);
        champ("lat", "5.898");
        champ("lng", "-4.823");
        champ("repere_texte", "Derrière la pharmacie, portail bleu");
        if let Some(d) = duree {
            champ("duree_s", &d.to_string());
        }
        if avec_note {
            corps.extend_from_slice(
                format!(
                    "--{B}\r\nContent-Disposition: form-data; name=\"note_vocale\"; \
                     filename=\"repere.m4a\"\r\nContent-Type: audio/mp4\r\n\r\n"
                )
                .as_bytes(),
            );
            corps.extend_from_slice(OCTETS_NOTE);
            corps.extend_from_slice(b"\r\n");
        }
        corps.extend_from_slice(format!("--{B}--\r\n").as_bytes());
        (format!("multipart/form-data; boundary={B}"), corps)
    }

    macro_rules! enregistrer {
        ($app:expr, $acces:expr, $libelle:expr, $cle:expr) => {{
            let (type_contenu, corps) = corps_adresse($libelle, true, Some(12));
            let requete = atest::TestRequest::post()
                .uri("/moi/adresses")
                .insert_header(("authorization", format!("Bearer {}", $acces)))
                .insert_header(("idempotency-key", $cle.to_string()))
                .insert_header(("content-type", type_contenu))
                .set_payload(corps)
                .to_request();
            atest::call_service(&$app, requete).await
        }};
    }

    /// Corps multipart d'un (re)dépôt de repère vocal — le format du CÂBLE.
    fn corps_repere(octets: &[u8], duree: i16) -> (String, Vec<u8>) {
        const B: &str = "----mefalitest";
        let mut corps: Vec<u8> = Vec::new();
        corps.extend_from_slice(
            format!("--{B}\r\nContent-Disposition: form-data; name=\"duree_s\"\r\n\r\n{duree}\r\n")
                .as_bytes(),
        );
        corps.extend_from_slice(
            format!(
                "--{B}\r\nContent-Disposition: form-data; name=\"note_vocale\"; \
                 filename=\"repere.m4a\"\r\nContent-Type: audio/mp4\r\n\r\n"
            )
            .as_bytes(),
        );
        corps.extend_from_slice(octets);
        corps.extend_from_slice(format!("\r\n--{B}--\r\n").as_bytes());
        (format!("multipart/form-data; boundary={B}"), corps)
    }

    macro_rules! remplacer_repere {
        ($app:expr, $acces:expr, $id:expr, $octets:expr, $duree:expr) => {{
            let (type_contenu, corps) = corps_repere($octets, $duree);
            let requete = atest::TestRequest::post()
                .uri(&format!("/moi/adresses/{}/repere-vocal", $id))
                .insert_header(("authorization", format!("Bearer {}", $acces)))
                .insert_header(("content-type", type_contenu))
                .set_payload(corps)
                .to_request();
            atest::call_service(&$app, requete).await
        }};
    }

    /// SC-007 — parcours complet : enregistrer, réécouter à l'identique, gérer.
    #[sqlx::test(migrations = "../migrations")]
    async fn enregistrer_ecouter_renommer_supprimer(pool: PgPool) {
        let (depot, objets) = preparer(&pool).await;
        let app = app!(depot);
        let awa = creer_compte(&depot, "+2250701020304").await;
        let acces = jeton(&depot, awa).await;
        let id = Uuid::now_v7();

        let resp = enregistrer!(app, acces, "Maison", id);
        assert_eq!(resp.status(), StatusCode::CREATED);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["id"], json!(id), "R14 — la clé DEVIENT l'id");
        assert_eq!(corps["libelle"], "Maison");
        assert_eq!(corps["a_repere_vocal"], true);
        assert_eq!(corps["repere_vocal_duree_s"], 12);
        assert!(
            corps.get("compte_id").is_none(),
            "le compte est implicite : c'est le vôtre"
        );
        assert!(
            corps.get("repere_vocal_cle_objet").is_none(),
            "la clé du bucket ne sort JAMAIS"
        );

        // Liste (FR-021).
        let requete = atest::TestRequest::get()
            .uri("/moi/adresses")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps.as_array().unwrap().len(), 1);

        // Réécoute : URL présignée, et les octets sont IDENTIQUES (SC-007).
        let requete = atest::TestRequest::get()
            .uri(&format!("/moi/adresses/{id}/repere-vocal"))
            .insert_header(("authorization", format!("Bearer {acces}")))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert!(corps["url"].as_str().unwrap().contains("comptes/reperes/"));
        assert!(corps["expire_le"].is_string());

        let cle = depot
            .adresse(id, awa)
            .await
            .unwrap()
            .repere_vocal_cle_objet
            .unwrap();
        assert_eq!(
            objets.lire(&cle).as_deref(),
            Some(OCTETS_NOTE),
            "SC-007 — la note rejouée est celle qui a été enregistrée, octet pour octet"
        );

        // Renommage (FR-021).
        let requete = atest::TestRequest::patch()
            .uri(&format!("/moi/adresses/{id}"))
            .insert_header(("authorization", format!("Bearer {acces}")))
            .set_json(json!({ "libelle": "Chez maman" }))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["libelle"], "Chez maman");
        assert_eq!(
            corps["repere_texte"], "Derrière la pharmacie, portail bleu",
            "un champ absent du corps n'est pas effacé"
        );

        // Effacement explicite du repère écrit (`null` ≠ absent).
        let requete = atest::TestRequest::patch()
            .uri(&format!("/moi/adresses/{id}"))
            .insert_header(("authorization", format!("Bearer {acces}")))
            .set_json(json!({ "repere_texte": null }))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["repere_texte"], serde_json::Value::Null);

        // Suppression (FR-021).
        let requete = atest::TestRequest::delete()
            .uri(&format!("/moi/adresses/{id}"))
            .insert_header(("authorization", format!("Bearer {acces}")))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::NO_CONTENT);
        assert!(depot.adresses(awa).await.unwrap().is_empty());
    }

    /// R14 — le rejeu de la même clé ne crée pas de doublon.
    #[sqlx::test(migrations = "../migrations")]
    async fn rejeu_ne_cree_pas_de_doublon(pool: PgPool) {
        let (depot, objets) = preparer(&pool).await;
        let app = app!(depot);
        let awa = creer_compte(&depot, "+2250701020304").await;
        let acces = jeton(&depot, awa).await;
        let id = Uuid::now_v7();

        let resp = enregistrer!(app, acces, "Maison", id);
        assert_eq!(resp.status(), StatusCode::CREATED);
        // Le réseau a coupé : le client rejoue.
        let resp = enregistrer!(app, acces, "Maison", id);
        assert_eq!(resp.status(), StatusCode::CREATED);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["id"], json!(id));

        assert_eq!(depot.adresses(awa).await.unwrap().len(), 1, "aucun doublon");
        assert_eq!(objets.nombre(), 1, "aucun octet déposé deux fois");
        let evenements: i64 =
            sqlx::query_scalar("SELECT count(*) FROM outbox.evenement WHERE type_evenement = $1")
                .bind("adresse.enregistree")
                .fetch_one(&pool)
                .await
                .unwrap();
        assert_eq!(evenements, 1);
    }

    /// L'adresse d'autrui est INTROUVABLE — jamais interdite.
    #[sqlx::test(migrations = "../migrations")]
    async fn adresse_d_autrui_404(pool: PgPool) {
        let (depot, _) = preparer(&pool).await;
        let app = app!(depot);
        let awa = creer_compte(&depot, "+2250701020304").await;
        let kofi = creer_compte(&depot, "+2250709080706").await;
        let acces_awa = jeton(&depot, awa).await;
        let acces_kofi = jeton(&depot, kofi).await;
        let id = Uuid::now_v7();
        enregistrer!(app, acces_awa, "Maison", id);

        for requete in [
            atest::TestRequest::get()
                .uri(&format!("/moi/adresses/{id}/repere-vocal"))
                .insert_header(("authorization", format!("Bearer {acces_kofi}")))
                .to_request(),
            atest::TestRequest::delete()
                .uri(&format!("/moi/adresses/{id}"))
                .insert_header(("authorization", format!("Bearer {acces_kofi}")))
                .to_request(),
        ] {
            let resp = atest::call_service(&app, requete).await;
            assert_eq!(
                resp.status(),
                StatusCode::NOT_FOUND,
                "404 et non 403 : un 403 confirmerait à Kofi qu'il a visé juste"
            );
            let corps: serde_json::Value = atest::read_body_json(resp).await;
            assert_eq!(corps["message_cle"], "comptes.erreur.introuvable");
        }

        // La liste de Kofi ne montre rien de celle d'Awa.
        let requete = atest::TestRequest::get()
            .uri("/moi/adresses")
            .insert_header(("authorization", format!("Bearer {acces_kofi}")))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert!(corps.as_array().unwrap().is_empty());
    }

    /// FR-019 — la durée est bornée par le PARAMÈTRE DE ZONE (30 s au seed).
    #[sqlx::test(migrations = "../migrations")]
    async fn duree_hors_parametre_de_zone_422(pool: PgPool) {
        let (depot, objets) = preparer(&pool).await;
        let app = app!(depot);
        let awa = creer_compte(&depot, "+2250701020304").await;
        let acces = jeton(&depot, awa).await;

        let (type_contenu, corps) = corps_adresse("Maison", true, Some(31));
        let requete = atest::TestRequest::post()
            .uri("/moi/adresses")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .insert_header(("idempotency-key", Uuid::now_v7().to_string()))
            .insert_header(("content-type", type_contenu))
            .set_payload(corps)
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.corps_invalide");
        assert!(depot.adresses(awa).await.unwrap().is_empty());
        assert_eq!(objets.nombre(), 0);
    }

    /// Une note vocale sans durée annoncée est un corps incohérent.
    #[sqlx::test(migrations = "../migrations")]
    async fn note_sans_duree_422(pool: PgPool) {
        let (depot, _) = preparer(&pool).await;
        let app = app!(depot);
        let awa = creer_compte(&depot, "+2250701020304").await;
        let acces = jeton(&depot, awa).await;

        let (type_contenu, corps) = corps_adresse("Maison", true, None);
        let requete = atest::TestRequest::post()
            .uri("/moi/adresses")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .insert_header(("idempotency-key", Uuid::now_v7().to_string()))
            .insert_header(("content-type", type_contenu))
            .set_payload(corps)
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
    }

    /// L'en-tête d'idempotence est REQUIS (R14).
    #[sqlx::test(migrations = "../migrations")]
    async fn sans_idempotency_key_422(pool: PgPool) {
        let (depot, _) = preparer(&pool).await;
        let app = app!(depot);
        let awa = creer_compte(&depot, "+2250701020304").await;
        let acces = jeton(&depot, awa).await;

        let (type_contenu, corps) = corps_adresse("Maison", true, Some(12));
        let requete = atest::TestRequest::post()
            .uri("/moi/adresses")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .insert_header(("content-type", type_contenu))
            .set_payload(corps)
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
        assert!(depot.adresses(awa).await.unwrap().is_empty());
    }

    /// FR-022 — un repère purgé est un 404, et se re-capte.
    #[sqlx::test(migrations = "../migrations")]
    async fn repere_purge_404_puis_recapture(pool: PgPool) {
        let (depot, objets) = preparer(&pool).await;
        let app = app!(depot);
        let awa = creer_compte(&depot, "+2250701020304").await;
        let acces = jeton(&depot, awa).await;
        let id = Uuid::now_v7();
        enregistrer!(app, acces, "Maison", id);

        // 366 jours sans utilisation, puis le job de purge.
        sqlx::query(
            "UPDATE comptes.adresse SET derniere_utilisation_le = now() - interval '366 days'
             WHERE id = $1",
        )
        .bind(id)
        .execute(&pool)
        .await
        .unwrap();
        assert_eq!(depot.purger_reperes_vocaux().await.unwrap(), 1);

        let ecouter = || {
            atest::TestRequest::get()
                .uri(&format!("/moi/adresses/{id}/repere-vocal"))
                .insert_header(("authorization", format!("Bearer {acces}")))
                .to_request()
        };
        let resp = atest::call_service(&app, ecouter()).await;
        assert_eq!(
            resp.status(),
            StatusCode::NOT_FOUND,
            "la RESSOURCE demandée n'est plus là — mais l'adresse, si"
        );

        // L'adresse reste utilisable (FR-022) et redemande un repère.
        let requete = atest::TestRequest::get()
            .uri("/moi/adresses")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps[0]["a_repere_vocal"], false);
        assert_eq!(corps[0]["libelle"], "Maison", "l'adresse a survécu à sa purge");

        // Re-capture.
        let resp = remplacer_repere!(app, acces, id, b"nouvelle-note", 8);
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["a_repere_vocal"], true);
        assert_eq!(corps["repere_vocal_duree_s"], 8);

        let cle = depot
            .adresse(id, awa)
            .await
            .unwrap()
            .repere_vocal_cle_objet
            .unwrap();
        assert_eq!(objets.lire(&cle).as_deref(), Some(&b"nouvelle-note"[..]));

        let resp = atest::call_service(&app, ecouter()).await;
        assert_eq!(resp.status(), StatusCode::OK);
    }

    /// Constitution VIII — refaire un repère qui EXISTE déjà écrit une clé
    /// neuve : sans suppression après commit, la voix d'Awa — une donnée
    /// personnelle — resterait dans le bucket indéfiniment, sans que rien ne la
    /// désigne plus (minimisation ARTCI).
    #[sqlx::test(migrations = "../migrations")]
    async fn remplacement_supprime_l_ancien_repere_vocal(pool: PgPool) {
        let (depot, objets) = preparer(&pool).await;
        let app = app!(depot);
        let awa = creer_compte(&depot, "+2250701020304").await;
        let acces = jeton(&depot, awa).await;
        let id = Uuid::now_v7();
        enregistrer!(app, acces, "Maison", id);

        let cle_dela = |depot: PgComptes| async move {
            depot
                .adresse(id, awa)
                .await
                .unwrap()
                .repere_vocal_cle_objet
                .unwrap()
        };
        let ancienne = cle_dela(depot.clone()).await;
        assert_eq!(objets.lire(&ancienne).as_deref(), Some(OCTETS_NOTE));

        // Awa refait son repère — l'adresse en avait DÉJÀ un (ce n'est pas une
        // re-capture après purge : là, il n'y aurait rien à déréférencer).
        let resp = remplacer_repere!(app, acces, id, b"repere-refait", 8);
        assert_eq!(resp.status(), StatusCode::OK);

        let nouvelle = cle_dela(depot.clone()).await;
        assert_ne!(nouvelle, ancienne, "un dépôt n'écrase jamais : clé neuve");
        assert_eq!(
            objets.lire(&nouvelle).as_deref(),
            Some(&b"repere-refait"[..]),
            "le repère courant est bien celui qu'Awa vient d'enregistrer"
        );
        assert_eq!(
            objets.lire(&ancienne),
            None,
            "l'ancienne note a disparu du bucket, pas seulement de la base"
        );
        assert_eq!(objets.nombre(), 1, "une seule note vocale subsiste");
    }

    /// FR-009 — sans session, rien.
    #[sqlx::test(migrations = "../migrations")]
    async fn adresses_401_sans_session(pool: PgPool) {
        let (depot, _) = preparer(&pool).await;
        let app = app!(depot);

        let requete = atest::TestRequest::get().uri("/moi/adresses").to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
    }

    /// Une adresse sans note vocale est légitime (FR-019).
    #[sqlx::test(migrations = "../migrations")]
    async fn adresse_texte_seul_acceptee(pool: PgPool) {
        let (depot, objets) = preparer(&pool).await;
        let app = app!(depot);
        let awa = creer_compte(&depot, "+2250701020304").await;
        let acces = jeton(&depot, awa).await;

        let (type_contenu, corps) = corps_adresse("Bureau", false, None);
        let requete = atest::TestRequest::post()
            .uri("/moi/adresses")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .insert_header(("idempotency-key", Uuid::now_v7().to_string()))
            .insert_header(("content-type", type_contenu))
            .set_payload(corps)
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::CREATED);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["a_repere_vocal"], false);
        assert_eq!(corps["repere_texte"], "Derrière la pharmacie, portail bleu");
        assert_eq!(objets.nombre(), 0);
    }
}
