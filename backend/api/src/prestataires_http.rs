//! Surface HTTP du domaine prestataires — erreurs, DTO partagés et
//! consultation (cycle 005).
//!
//! Trois surfaces se partagent ce socle : la consultation (ce module —
//! publique pour la fiche, sous session pour la résolution de plaque, analyse
//! C1), `vendeur_http` (garde de pilotage) et `admin_prestataires_http`
//! (rôle admin). Les erreurs sont rendues `{ code, message_cle }` (clés i18n
//! fr), patron du cycle 003.

use std::fmt;

use actix_web::http::StatusCode;
use actix_web::{get, web, HttpResponse, ResponseError};
use chrono::{DateTime, NaiveTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::json;
use utoipa::ToSchema;
use uuid::Uuid;

use prestataires::modele::{
    AffichageRupture, ArticlePublic, EffectifBoutique, ErreurPrestataires, FichePublique,
    HorairesSemaine, Plage,
};
use prestataires::{PgPrestataires, StatutBoutique, StatutPrestataire};

use crate::auth_http::{Auth, ErreurApi as ErreurAuth, ErreurApiDto};

/// TTL des URLs présignées servies par ce module (photos, chartes) — patron du
/// cycle 003.
pub(crate) const PRESIGNEE_TTL: std::time::Duration = std::time::Duration::from_secs(10 * 60);

// ── Erreurs HTTP du module prestataires ────────────────────────────────────

/// Erreur d'API du domaine prestataires, rendue `{ code, message_cle }`.
#[derive(Debug)]
pub enum ErreurPresta {
    /// 404 — réponse NEUTRE de la consultation publique : id inconnu,
    /// prospect et suspendu sont INDISTINGUABLES (FR-017, research R9).
    Indisponible,
    /// 404 — ressource inconnue (surfaces authentifiées, non neutres).
    Introuvable,
    /// 401 — session absente, invalide ou révoquée.
    NonAuthentifie,
    /// 403 — rôle requis manquant (admin, coursier).
    RoleRequis,
    /// 403 — rôle vendeur absent (premier des trois refus — R11).
    RoleVendeurRequis,
    /// 403 — compte non rattaché à ce prestataire (FR-011).
    NonRattache,
    /// 403 — prestataire non agréé : capacités vendeur DÉRIVÉES (FR-008).
    PrestataireNonAgree,
    /// 403 — signalement coursier hors commande active (FR-038).
    SignalementInterdit,
    /// 409 — transition refusée par le cycle de vie (FR-004).
    TransitionInvalide,
    /// 409 — rupture posée par l'Admin, remise admin seulement (FR-041).
    RuptureAdmin,
    /// 422 — agrément refusé, manques EXPLICITES (FR-005).
    AgrementIncomplet(Vec<&'static str>),
    /// 422 — motif absent pour une suspension (FR-010).
    MotifRequis,
    /// 422 — prix barré ≤ prix courant (FR-023).
    PrixBarreInvalide,
    /// 422 — zone de rattachement qui n'est pas une ville (FR-002).
    ZoneNonVille,
    /// 422 — catégorie de service inconnue.
    CategorieInconnue,
    /// 422 — corps, média ou champ invalide.
    CorpsInvalide,
    /// 500 — erreur interne (SQL, S3, configuration de zone).
    Interne,
}

impl ErreurPresta {
    fn statut(&self) -> StatusCode {
        match self {
            ErreurPresta::Indisponible | ErreurPresta::Introuvable => StatusCode::NOT_FOUND,
            ErreurPresta::NonAuthentifie => StatusCode::UNAUTHORIZED,
            ErreurPresta::RoleRequis
            | ErreurPresta::RoleVendeurRequis
            | ErreurPresta::NonRattache
            | ErreurPresta::PrestataireNonAgree
            | ErreurPresta::SignalementInterdit => StatusCode::FORBIDDEN,
            ErreurPresta::TransitionInvalide | ErreurPresta::RuptureAdmin => StatusCode::CONFLICT,
            ErreurPresta::AgrementIncomplet(_)
            | ErreurPresta::MotifRequis
            | ErreurPresta::PrixBarreInvalide
            | ErreurPresta::ZoneNonVille
            | ErreurPresta::CategorieInconnue
            | ErreurPresta::CorpsInvalide => StatusCode::UNPROCESSABLE_ENTITY,
            ErreurPresta::Interne => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    fn code(&self) -> &'static str {
        match self {
            ErreurPresta::Indisponible => "prestataire_indisponible",
            ErreurPresta::Introuvable => "introuvable",
            ErreurPresta::NonAuthentifie => "non_authentifie",
            ErreurPresta::RoleRequis => "role_requis",
            ErreurPresta::RoleVendeurRequis => "role_vendeur_requis",
            ErreurPresta::NonRattache => "prestataire_non_rattache",
            ErreurPresta::PrestataireNonAgree => "prestataire_non_agree",
            ErreurPresta::SignalementInterdit => "signalement_interdit",
            ErreurPresta::TransitionInvalide => "transition_invalide",
            ErreurPresta::RuptureAdmin => "rupture_admin",
            ErreurPresta::AgrementIncomplet(_) => "agrement_incomplet",
            ErreurPresta::MotifRequis => "motif_requis",
            ErreurPresta::PrixBarreInvalide => "prix_barre_invalide",
            ErreurPresta::ZoneNonVille => "zone_non_ville",
            ErreurPresta::CategorieInconnue => "categorie_inconnue",
            ErreurPresta::CorpsInvalide => "corps_invalide",
            ErreurPresta::Interne => "erreur_interne",
        }
    }

    fn message_cle(&self) -> String {
        format!("prestataires.erreur.{}", self.code())
    }
}

impl fmt::Display for ErreurPresta {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.code())
    }
}

impl ResponseError for ErreurPresta {
    fn status_code(&self) -> StatusCode {
        self.statut()
    }
    fn error_response(&self) -> HttpResponse {
        let mut corps = json!({ "code": self.code(), "message_cle": self.message_cle() });
        // Motif EXPLICITE du refus d'agrément (FR-005) : les manques, en
        // identifiants stables que l'écran ADM traduira en clés i18n.
        if let ErreurPresta::AgrementIncomplet(manques) = self {
            corps["manques"] = json!(manques);
        }
        HttpResponse::build(self.statut()).json(corps)
    }
}

impl From<ErreurPrestataires> for ErreurPresta {
    fn from(erreur: ErreurPrestataires) -> Self {
        use ErreurPrestataires as E;
        match erreur {
            E::PrestataireInconnu(_)
            | E::SiteInconnu(_)
            | E::ArticleInconnu(_)
            | E::ArticleRetire(_)
            | E::PhotoInconnue(_)
            | E::RattachementInconnu { .. } => ErreurPresta::Introuvable,
            E::ZoneNonVille(_) => ErreurPresta::ZoneNonVille,
            E::CategorieInconnue(_) => ErreurPresta::CategorieInconnue,
            E::TransitionInvalide { .. } => ErreurPresta::TransitionInvalide,
            E::AgrementIncomplet { manques } => ErreurPresta::AgrementIncomplet(manques),
            E::MotifRequis => ErreurPresta::MotifRequis,
            E::PrixBarreInvalide => ErreurPresta::PrixBarreInvalide,
            E::PrestataireNonAgree(_) => ErreurPresta::PrestataireNonAgree,
            E::NonRattache { .. } => ErreurPresta::NonRattache,
            E::RuptureAdmin => ErreurPresta::RuptureAdmin,
            E::SignalementInterdit => ErreurPresta::SignalementInterdit,
            E::FicheInvalide(_)
            | E::MontantInvalide(_)
            | E::HorairesInvalides(_)
            | E::DureeRequise
            | E::ProlongationSansPause
            | E::ObjetTropVolumineux
            | E::MediaInvalide(_) => ErreurPresta::CorpsInvalide,
            // Comptes : le rattachement traverse la machine à états du 003.
            E::Comptes(comptes::ErreurComptes::CompteInconnu(_)) => ErreurPresta::Introuvable,
            E::Comptes(comptes::ErreurComptes::TransitionInvalide { .. }) => {
                ErreurPresta::TransitionInvalide
            }
            E::Zones(zones::ErreurZones::ZoneInconnue(_)) => ErreurPresta::Introuvable,
            E::Comptes(_)
            | E::Zones(_)
            | E::CommandesActives(_)
            | E::ConfigurationZoneInvalide { .. }
            | E::Objets(_)
            | E::Sql(_) => ErreurPresta::Interne,
        }
    }
}

impl From<ErreurAuth> for ErreurPresta {
    /// L'extracteur `Auth` et sa garde parlent en `ErreurApi` du cycle 003 —
    /// repliés sur les variantes équivalentes de ce module.
    fn from(erreur: ErreurAuth) -> Self {
        match erreur {
            ErreurAuth::NonAuthentifie => ErreurPresta::NonAuthentifie,
            ErreurAuth::RoleRequis => ErreurPresta::RoleRequis,
            _ => ErreurPresta::Interne,
        }
    }
}

/// Erreur SQL hors domaine (ouverture/commit de transaction).
pub(crate) fn sql(e: sqlx::Error) -> ErreurPresta {
    ErreurPresta::from(ErreurPrestataires::Sql(e))
}

// ── DTO partagés ───────────────────────────────────────────────────────────

/// Une plage d'ouverture, heures locales `HH:MM` (FR-031).
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PlageDto {
    /// Début (inclus), ex. `08:00`.
    #[schema(example = "08:00")]
    pub debut: String,
    /// Fin (exclue), ex. `19:00`.
    #[schema(example = "19:00")]
    pub fin: String,
}

/// Horaires hebdomadaires : 7 tableaux de plages, index 0 = lundi ; un jour
/// sans plage est un jour de fermeture.
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct HorairesSemaineDto {
    /// Plages par jour (lundi → dimanche).
    #[schema(min_items = 7, max_items = 7)]
    pub jours: Vec<Vec<PlageDto>>,
}

fn heure_vers_texte(t: NaiveTime) -> String {
    t.format("%H:%M").to_string()
}

fn texte_vers_heure(s: &str) -> Result<NaiveTime, ErreurPresta> {
    NaiveTime::parse_from_str(s, "%H:%M")
        .or_else(|_| NaiveTime::parse_from_str(s, "%H:%M:%S"))
        .map_err(|_| ErreurPresta::CorpsInvalide)
}

impl From<&HorairesSemaine> for HorairesSemaineDto {
    fn from(h: &HorairesSemaine) -> Self {
        Self {
            jours: h
                .jours
                .iter()
                .map(|plages| {
                    plages
                        .iter()
                        .map(|p| PlageDto {
                            debut: heure_vers_texte(p.debut),
                            fin: heure_vers_texte(p.fin),
                        })
                        .collect()
                })
                .collect(),
        }
    }
}

impl HorairesSemaineDto {
    /// Reconstruit la semaine domaine — 7 jours EXACTEMENT (422 sinon).
    pub(crate) fn vers_domaine(&self) -> Result<HorairesSemaine, ErreurPresta> {
        if self.jours.len() != 7 {
            return Err(ErreurPresta::CorpsInvalide);
        }
        let mut horaires = HorairesSemaine::default();
        for (jour, plages) in self.jours.iter().enumerate() {
            for p in plages {
                horaires.jours[jour].push(Plage {
                    debut: texte_vers_heure(&p.debut)?,
                    fin: texte_vers_heure(&p.fin)?,
                });
            }
        }
        Ok(horaires)
    }
}

/// Statut de boutique DÉCLARÉ (FR-030).
#[derive(Debug, Clone, Copy, Serialize, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
#[schema(as = StatutBoutique)]
pub enum StatutBoutiqueDto {
    /// Reçoit les commandes pendant les horaires.
    Ouvert,
    /// Fermée manuellement.
    Ferme,
    /// Fermée jusqu'au prochain jour d'ouverture.
    FermeJournee,
    /// Pause temporisée.
    EnPause,
}

impl From<StatutBoutique> for StatutBoutiqueDto {
    fn from(s: StatutBoutique) -> Self {
        match s {
            StatutBoutique::Ouvert => StatutBoutiqueDto::Ouvert,
            StatutBoutique::Ferme => StatutBoutiqueDto::Ferme,
            StatutBoutique::FermeJournee => StatutBoutiqueDto::FermeJournee,
            StatutBoutique::EnPause => StatutBoutiqueDto::EnPause,
        }
    }
}

impl From<StatutBoutiqueDto> for StatutBoutique {
    fn from(s: StatutBoutiqueDto) -> Self {
        match s {
            StatutBoutiqueDto::Ouvert => StatutBoutique::Ouvert,
            StatutBoutiqueDto::Ferme => StatutBoutique::Ferme,
            StatutBoutiqueDto::FermeJournee => StatutBoutique::FermeJournee,
            StatutBoutiqueDto::EnPause => StatutBoutique::EnPause,
        }
    }
}

/// Statut du cycle de vie (FR-004).
#[derive(Debug, Clone, Copy, Serialize, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
#[schema(as = StatutPrestataire)]
pub enum StatutPrestataireDto {
    /// Fiche en constitution.
    Prospect,
    /// Agréé — fiche servie, plaque valide.
    Agree,
    /// Suspendu — tout est coupé.
    Suspendu,
}

impl From<StatutPrestataire> for StatutPrestataireDto {
    fn from(s: StatutPrestataire) -> Self {
        match s {
            StatutPrestataire::Prospect => StatutPrestataireDto::Prospect,
            StatutPrestataire::Agree => StatutPrestataireDto::Agree,
            StatutPrestataire::Suspendu => StatutPrestataireDto::Suspendu,
        }
    }
}

/// État EFFECTIF de la boutique — dérivé, jamais stocké (FR-032).
#[derive(Debug, Clone, Serialize, ToSchema)]
#[schema(as = EtatEffectifBoutique)]
pub struct EffectifBoutiqueDto {
    /// La boutique reçoit-elle des commandes en cet instant ?
    pub ouvert: bool,
    /// Prochaine réouverture estimée quand fermée (FR-029).
    pub reouverture_estimee: Option<DateTime<Utc>>,
}

impl From<EffectifBoutique> for EffectifBoutiqueDto {
    fn from(e: EffectifBoutique) -> Self {
        Self {
            ouvert: e.ouvert,
            reouverture_estimee: e.reouverture_estimee,
        }
    }
}

// ── Consultation (FR-027..029, SC-013) ─────────────────────────────────────

/// Article du catalogue public.
#[derive(Debug, Clone, Serialize, ToSchema)]
#[schema(as = ArticlePublic)]
pub struct ArticlePublicDto {
    /// Identifiant.
    pub id: Uuid,
    /// Nom.
    pub nom: String,
    /// Prix courant — ENTIER en unités mineures (constitution III).
    pub prix_unites: i64,
    /// Code ISO 4217 de la zone.
    pub devise: String,
    /// Prix barré (présent ⇒ promotion, strictement supérieur — FR-023).
    pub prix_barre_unites: Option<i64>,
    /// URL présignée de la photo (TTL 10 min).
    pub photo_url: Option<String>,
    /// Étiquette libre de regroupement.
    pub categorie_interne: Option<String>,
    /// Faux = rupture (servi seulement si le mode de la catégorie est `grise`).
    pub disponible: bool,
}

impl From<ArticlePublic> for ArticlePublicDto {
    fn from(a: ArticlePublic) -> Self {
        Self {
            id: a.id,
            nom: a.nom,
            prix_unites: a.prix_unites,
            devise: a.devise,
            prix_barre_unites: a.prix_barre_unites,
            photo_url: a.photo_url,
            categorie_interne: a.categorie_interne,
            disponible: a.disponible,
        }
    }
}

/// Mode de rendu des articles en rupture (paramètre de catégorie — FR-050).
#[derive(Debug, Clone, Copy, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
#[schema(as = AffichageRupture)]
pub enum AffichageRuptureDto {
    /// Servi grisé, non commandable.
    Grise,
    /// Absent de la consultation.
    Masque,
}

impl From<AffichageRupture> for AffichageRuptureDto {
    fn from(a: AffichageRupture) -> Self {
        match a {
            AffichageRupture::Grise => AffichageRuptureDto::Grise,
            AffichageRupture::Masque => AffichageRuptureDto::Masque,
        }
    }
}

/// Fiche publique : le sous-ensemble EXACT de FR-027 — ni contact
/// téléphonique, ni coordonnées de site, ni donnée d'exploitation (SC-013).
#[derive(Debug, Clone, Serialize, ToSchema)]
#[schema(as = FichePublique)]
pub struct FichePubliqueDto {
    /// Identifiant du prestataire.
    pub id: Uuid,
    /// Nom public.
    pub nom: String,
    /// Slug de la catégorie de service.
    pub categorie: String,
    /// URLs présignées des photos de fiche.
    pub photos: Vec<String>,
    /// Délai de préparation moyen déclaré (minutes).
    pub delai_preparation_min: i32,
    /// État effectif de la boutique.
    pub boutique: EffectifBoutiqueDto,
    /// Horaires hebdomadaires.
    pub horaires: HorairesSemaineDto,
    /// FR-028 — la SEULE définition de « commandable ».
    pub commandable: bool,
    /// Mode de rendu des ruptures, résolu pour la catégorie.
    pub affichage_rupture: AffichageRuptureDto,
    /// Catalogue servi (retirés absents ; ruptures selon le mode).
    pub articles: Vec<ArticlePublicDto>,
}

impl From<FichePublique> for FichePubliqueDto {
    fn from(f: FichePublique) -> Self {
        Self {
            id: f.id,
            nom: f.nom,
            categorie: f.categorie,
            photos: f.photos,
            delai_preparation_min: f.delai_preparation_min,
            boutique: f.boutique.into(),
            horaires: HorairesSemaineDto::from(&f.horaires),
            commandable: f.commandable,
            affichage_rupture: f.affichage_rupture.into(),
            articles: f.articles.into_iter().map(Into::into).collect(),
        }
    }
}

/// Fiche + catalogue, lecture seule, SANS authentification — la plaque est un
/// canal d'acquisition (FR-027 ; exception VIII documentée au plan, R9).
#[utoipa::path(
    get,
    path = "/prestataires/{id}",
    tag = "prestataires",
    params(("id" = Uuid, Path, description = "Prestataire consulté.")),
    responses(
        (status = 200, description = "Prestataire AGRÉÉ — boutique ouverte ou fermée (fermée : \
         catalogue en lecture seule + horaires + réouverture estimée, FR-029). Articles retirés \
         absents ; en rupture : servis `disponible=false` si le mode est `grise`, ABSENTS si \
         `masque` (FR-042).",
         body = FichePubliqueDto),
        (status = 404, description = "Réponse NEUTRE — id inconnu, prospect et suspendu sont \
         indistinguables, sans photo ni motif (FR-017, SC-013).", body = ErreurApiDto),
        (status = 429, description = "Rate-limit par IP."),
    ),
)]
#[get("/prestataires/{id}")]
pub async fn consulter_prestataire(
    chemin: web::Path<Uuid>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    let fiche = depot
        .fiche_publique_de(chemin.into_inner())
        .await
        .map_err(ErreurPresta::from)?
        .ok_or(ErreurPresta::Indisponible)?;
    Ok(HttpResponse::Ok().json(FichePubliqueDto::from(fiche)))
}

/// Résolution d'un jeton de plaque (contrat).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ResolutionPlaque)]
pub struct ResolutionPlaqueDto {
    /// Prestataire que la plaque désigne.
    pub prestataire_id: Uuid,
    /// Validité courante — DÉRIVÉE de l'état d'agrément (FR-015).
    pub valide: bool,
}

/// Résout un jeton de plaque — sous SESSION valide, AUCUN rôle particulier
/// (analyse C1 : seule la consultation de la fiche échappe au principe VIII).
#[utoipa::path(
    get,
    path = "/prestataires/plaque/{jeton}",
    tag = "prestataires",
    params(("jeton" = String, Path, description = "Jeton signé porté par la plaque.")),
    responses(
        (status = 200, description = "Jeton connu — la révocation est OBSERVABLE : un \
         prestataire suspendu rend `valide=false`, sans autre donnée (FR-016/017).",
         body = ResolutionPlaqueDto),
        (status = 404, description = "Jeton inconnu ou forgé.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/prestataires/plaque/{jeton}")]
pub async fn resoudre_plaque(
    _auth: Auth,
    chemin: web::Path<String>,
    depot: web::Data<PgPrestataires>,
) -> Result<HttpResponse, ErreurPresta> {
    let resolution = depot
        .resolution_plaque(&chemin.into_inner())
        .await
        .map_err(ErreurPresta::from)?
        .ok_or(ErreurPresta::Introuvable)?;
    Ok(HttpResponse::Ok().json(ResolutionPlaqueDto {
        prestataire_id: resolution.prestataire_id,
        valide: resolution.valide,
    }))
}
