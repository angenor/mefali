//! Fiche du prestataire : création, modification, photos, charte signée
//! (FR-002, FR-003, FR-025 — data-model §3.2–3.4).
//!
//! Le cycle de vie (agrément, suspension, rétablissement, correction) vit dans
//! ce module aussi, ajouté par ses tâches dédiées ; toutes les ÉCRITURES
//! prennent `&mut sqlx::PgTransaction` et émettent leur événement dans la même
//! transaction (constitution VI).

use chrono::{DateTime, NaiveDate, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgPrestataires;
use crate::modele::{ErreurPrestataires, StatutPrestataire};

/// Types MIME acceptés pour les photos de fiche et d'articles (FR-025).
pub const PHOTO_MIMES: &[&str] = &["image/jpeg", "image/png", "image/webp"];
/// Taille maximale d'une photo (5 Mo — ordre de grandeur d'un cliché mobile).
pub const PHOTO_TAILLE_MAX: usize = 5 * 1024 * 1024;
/// Types MIME acceptés pour le scan de charte (FR-003) — mêmes formats que la
/// pièce d'identité du cycle 003, PDF compris.
pub const CHARTE_MIMES: &[&str] = &["image/jpeg", "image/png", "image/webp", "application/pdf"];
/// Taille maximale du scan de charte (10 Mo, patron pièce d'identité).
pub const CHARTE_TAILLE_MAX: usize = 10 * 1024 * 1024;

/// Fiche complète, vue ADMIN (le sous-ensemble public vit dans
/// `consultation.rs` — FR-027, SC-013).
#[derive(Debug, Clone, PartialEq)]
pub struct Prestataire {
    /// Identifiant stable (UUIDv7).
    pub id: Uuid,
    /// Nom public.
    pub nom: String,
    /// Catégorie de service (référentiel du cycle 002).
    pub categorie_id: Uuid,
    /// Slug de la catégorie (joint — évite un aller-retour aux appelants).
    pub categorie_slug: String,
    /// Ville de rattachement (type `ville` garanti à l'écriture — FR-002).
    pub ville_id: Uuid,
    /// Contact téléphonique — servi UNIQUEMENT à l'admin (SC-013).
    pub contact_telephone: String,
    /// Délai de préparation moyen déclaré (minutes).
    pub delai_preparation_min: i32,
    /// Cycle de vie (FR-004).
    pub statut: StatutPrestataire,
    /// Journal de la DERNIÈRE décision (l'historique vit dans l'outbox).
    pub statut_decide_par: Option<Uuid>,
    /// Horodatage de la dernière décision.
    pub statut_decide_le: Option<DateTime<Utc>>,
    /// Motif de la dernière décision (REQUIS pour une suspension).
    pub statut_motif: Option<String>,
    /// Jeton de plaque — posé au PREMIER agrément, stable ensuite (FR-013).
    pub jeton_plaque: Option<String>,
    /// Code de secours à 4 chiffres (FR-014).
    pub code_secours: Option<String>,
    /// Création de la fiche.
    pub cree_le: DateTime<Utc>,
    /// Dernière modification.
    pub modifie_le: DateTime<Utc>,
}

/// Champs de création d'une fiche (statut initial : prospect).
#[derive(Debug, Clone)]
pub struct NouveauPrestataire {
    /// Nom public.
    pub nom: String,
    /// Slug de la catégorie de service.
    pub categorie_slug: String,
    /// Ville de rattachement — type `ville` exigé (FR-002).
    pub ville_id: Uuid,
    /// Contact téléphonique.
    pub contact_telephone: String,
    /// Délai de préparation moyen déclaré (minutes).
    pub delai_preparation_min: i32,
}

/// Modification partielle de la fiche (`None` = champ inchangé).
#[derive(Debug, Clone, Default)]
pub struct ModificationPrestataire {
    /// Nouveau nom.
    pub nom: Option<String>,
    /// Nouveau contact.
    pub contact_telephone: Option<String>,
    /// Nouveau délai de préparation (minutes).
    pub delai_preparation_min: Option<i32>,
}

/// Photo de fiche (clé S3 privée — l'URL présignée est émise à la lecture).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhotoPrestataire {
    /// Identifiant.
    pub id: Uuid,
    /// Clé S3 (`prestataires/fiches/{prestataire_id}/{uuidv7}`).
    pub cle_objet: String,
    /// Ordre d'affichage.
    pub position: i32,
}

/// Charte signée déposée (FR-003) — pièce contractuelle à accès admin.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CharteSignee {
    /// Identifiant.
    pub id: Uuid,
    /// Clé S3 (`prestataires/chartes/{prestataire_id}/{uuidv7}`).
    pub cle_objet: String,
    /// Version de charte en vigueur À LA SIGNATURE — jamais recomparée.
    pub version_charte: String,
    /// Date de signature manuscrite.
    pub signee_le: NaiveDate,
    /// Dépôt du scan.
    pub deposee_le: DateTime<Utc>,
}

impl PgPrestataires {
    // ── Création et modification de la fiche ───────────────────────────────

    /// Crée la fiche à l'état `prospect`, avec son extension vendeur (toutes
    /// les catégories du MVP vendent — data-model §3.7) et le plan « gratuit »
    /// (provision VND-07). Émet `prestataire.cree`.
    pub async fn creer_prestataire(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        nouveau: &NouveauPrestataire,
        acteur: Uuid,
    ) -> Result<Prestataire, ErreurPrestataires> {
        valider_champs(
            &nouveau.nom,
            &nouveau.contact_telephone,
            nouveau.delai_preparation_min,
        )?;
        let categorie = self
            .categorie_par_slug(tx, &nouveau.categorie_slug)
            .await?;
        self.verifier_ville(tx, nouveau.ville_id).await?;

        let plan: Uuid =
            sqlx::query_scalar!("SELECT id FROM prestataires.plan WHERE code = 'gratuit'")
                .fetch_one(&mut **tx)
                .await?;

        let id = Uuid::now_v7();
        sqlx::query!(
            "INSERT INTO prestataires.prestataire
                 (id, nom, categorie_id, ville_id, contact_telephone,
                  delai_preparation_min, plan_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7)",
            id,
            nouveau.nom.trim(),
            categorie,
            nouveau.ville_id,
            nouveau.contact_telephone.trim(),
            nouveau.delai_preparation_min,
            plan,
        )
        .execute(&mut **tx)
        .await?;
        sqlx::query!(
            "INSERT INTO prestataires.vendeur (prestataire_id) VALUES ($1)",
            id
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "prestataire.cree",
                entite_type: "prestataire",
                entite_id: id,
                payload: json!({
                    "zone": nouveau.ville_id,
                    "categorie": nouveau.categorie_slug,
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;

        self.prestataire_dans_tx(tx, id).await
    }

    /// Modifie la fiche — administrable à TOUT statut (edge case spec : une
    /// fiche suspendue reste administrable). Émet `prestataire.modifie` avec
    /// les NOMS des champs seulement (FR-052).
    pub async fn modifier_prestataire(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        modification: &ModificationPrestataire,
        acteur: Uuid,
    ) -> Result<Prestataire, ErreurPrestataires> {
        let courant = self.prestataire_dans_tx(tx, prestataire).await?;

        let mut champs: Vec<&str> = Vec::new();
        let nom = match &modification.nom {
            Some(n) => {
                champs.push("nom");
                n.clone()
            }
            None => courant.nom.clone(),
        };
        let contact = match &modification.contact_telephone {
            Some(c) => {
                champs.push("contact");
                c.clone()
            }
            None => courant.contact_telephone.clone(),
        };
        let delai = match modification.delai_preparation_min {
            Some(d) => {
                champs.push("delai_preparation");
                d
            }
            None => courant.delai_preparation_min,
        };
        if champs.is_empty() {
            return Ok(courant); // aucun champ → aucune écriture, aucun événement
        }
        valider_champs(&nom, &contact, delai)?;

        sqlx::query!(
            "UPDATE prestataires.prestataire
             SET nom = $2, contact_telephone = $3, delai_preparation_min = $4,
                 modifie_le = now()
             WHERE id = $1",
            prestataire,
            nom.trim(),
            contact.trim(),
            delai,
        )
        .execute(&mut **tx)
        .await?;

        self.emettre_modification(tx, prestataire, &champs, acteur)
            .await?;
        self.prestataire_dans_tx(tx, prestataire).await
    }

    // ── Photos de fiche (FR-025, FR-026) ───────────────────────────────────

    /// Dépose une photo de fiche sous une clé NEUVE et l'ajoute en dernière
    /// position. Émet `prestataire.modifie` (`champs: ["photos"]`).
    pub async fn ajouter_photo(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        octets: Vec<u8>,
        mime: &str,
        acteur: Uuid,
    ) -> Result<PhotoPrestataire, ErreurPrestataires> {
        self.prestataire_dans_tx(tx, prestataire).await?;
        valider_media(&octets, mime, PHOTO_MIMES, PHOTO_TAILLE_MAX)?;

        let id = Uuid::now_v7();
        let cle = format!("prestataires/fiches/{prestataire}/{id}");
        // Dépôt AVANT la ligne : si la transaction échoue ensuite, l'objet est
        // orphelin (purge best-effort) — l'inverse servirait une clé sans objet.
        self.objets.deposer(&cle, octets, mime).await?;

        let position: i32 = sqlx::query_scalar!(
            r#"SELECT COALESCE(MAX(position) + 1, 0) AS "position!"
               FROM prestataires.photo_prestataire WHERE prestataire_id = $1"#,
            prestataire,
        )
        .fetch_one(&mut **tx)
        .await?;
        sqlx::query!(
            "INSERT INTO prestataires.photo_prestataire (id, prestataire_id, cle_objet, position)
             VALUES ($1, $2, $3, $4)",
            id,
            prestataire,
            cle,
            position,
        )
        .execute(&mut **tx)
        .await?;

        self.emettre_modification(tx, prestataire, &["photos"], acteur)
            .await?;
        Ok(PhotoPrestataire {
            id,
            cle_objet: cle,
            position,
        })
    }

    /// Supprime une photo et rend la clé S3 ORPHELINE — l'appelant la purge
    /// APRÈS commit (patron du cycle 003, FR-026).
    pub async fn supprimer_photo(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        photo: Uuid,
        acteur: Uuid,
    ) -> Result<String, ErreurPrestataires> {
        let cle = sqlx::query_scalar!(
            "DELETE FROM prestataires.photo_prestataire
             WHERE id = $1 AND prestataire_id = $2
             RETURNING cle_objet",
            photo,
            prestataire,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurPrestataires::PhotoInconnue(photo))?;

        self.emettre_modification(tx, prestataire, &["photos"], acteur)
            .await?;
        Ok(cle)
    }

    /// Photos de la fiche, dans l'ordre d'affichage.
    pub async fn photos(&self, prestataire: Uuid) -> Result<Vec<PhotoPrestataire>, ErreurPrestataires> {
        let lignes = sqlx::query!(
            "SELECT id, cle_objet, position FROM prestataires.photo_prestataire
             WHERE prestataire_id = $1 ORDER BY position",
            prestataire,
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(lignes
            .into_iter()
            .map(|l| PhotoPrestataire {
                id: l.id,
                cle_objet: l.cle_objet,
                position: l.position,
            })
            .collect())
    }

    // ── Charte signée (FR-003) ─────────────────────────────────────────────

    /// Dépose un scan de charte signée (clé neuve, 0..n par prestataire — une
    /// re-signature n'écrase jamais). Émet `charte.deposee`.
    pub async fn deposer_charte(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        octets: Vec<u8>,
        mime: &str,
        version_charte: &str,
        signee_le: NaiveDate,
        acteur: Uuid,
    ) -> Result<CharteSignee, ErreurPrestataires> {
        self.prestataire_dans_tx(tx, prestataire).await?;
        valider_media(&octets, mime, CHARTE_MIMES, CHARTE_TAILLE_MAX)?;
        if version_charte.trim().is_empty() {
            return Err(ErreurPrestataires::FicheInvalide(
                "version de charte vide".to_owned(),
            ));
        }

        let id = Uuid::now_v7();
        let cle = format!("prestataires/chartes/{prestataire}/{id}");
        self.objets.deposer(&cle, octets, mime).await?;

        sqlx::query!(
            "INSERT INTO prestataires.charte_signee
                 (id, prestataire_id, cle_objet, version_charte, signee_le)
             VALUES ($1, $2, $3, $4, $5)",
            id,
            prestataire,
            cle,
            version_charte.trim(),
            signee_le,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "charte.deposee",
                entite_type: "charte_signee",
                entite_id: id,
                payload: json!({
                    "prestataire": prestataire,
                    "version_charte": version_charte.trim(),
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;

        Ok(CharteSignee {
            id,
            cle_objet: cle,
            version_charte: version_charte.trim().to_owned(),
            signee_le,
            deposee_le: Utc::now(),
        })
    }

    /// Chartes déposées, la plus récente d'abord (lecture ADMIN).
    pub async fn chartes(&self, prestataire: Uuid) -> Result<Vec<CharteSignee>, ErreurPrestataires> {
        let lignes = sqlx::query!(
            "SELECT id, cle_objet, version_charte, signee_le, deposee_le
             FROM prestataires.charte_signee
             WHERE prestataire_id = $1 ORDER BY deposee_le DESC",
            prestataire,
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(lignes
            .into_iter()
            .map(|l| CharteSignee {
                id: l.id,
                cle_objet: l.cle_objet,
                version_charte: l.version_charte,
                signee_le: l.signee_le,
                deposee_le: l.deposee_le,
            })
            .collect())
    }

    // ── Lectures ───────────────────────────────────────────────────────────

    /// Fiche par identifiant (lecture sur pool — vue admin).
    pub async fn prestataire(&self, id: Uuid) -> Result<Prestataire, ErreurPrestataires> {
        let mut tx = self.pool.begin().await?;
        let p = self.prestataire_dans_tx(&mut tx, id).await?;
        tx.commit().await?;
        Ok(p)
    }

    /// Liste admin, filtrable par statut, ville et catégorie (slug).
    pub async fn lister(
        &self,
        statut: Option<StatutPrestataire>,
        ville: Option<Uuid>,
        categorie_slug: Option<&str>,
    ) -> Result<Vec<Prestataire>, ErreurPrestataires> {
        let lignes = sqlx::query!(
            r#"SELECT p.id, p.nom, p.categorie_id, c.slug AS categorie_slug, p.ville_id,
                      p.contact_telephone, p.delai_preparation_min,
                      p.statut::text AS "statut!", p.statut_decide_par, p.statut_decide_le,
                      p.statut_motif, p.jeton_plaque, p.code_secours, p.cree_le, p.modifie_le
               FROM prestataires.prestataire p
               JOIN zones.categorie c ON c.id = p.categorie_id
               WHERE ($1::text IS NULL OR p.statut::text = $1)
                 AND ($2::uuid IS NULL OR p.ville_id = $2)
                 AND ($3::text IS NULL OR c.slug = $3)
               ORDER BY p.cree_le"#,
            statut.map(|s| s.comme_str()),
            ville,
            categorie_slug,
        )
        .fetch_all(&self.pool)
        .await?;

        lignes
            .into_iter()
            .map(|l| {
                Ok(Prestataire {
                    id: l.id,
                    nom: l.nom,
                    categorie_id: l.categorie_id,
                    categorie_slug: l.categorie_slug,
                    ville_id: l.ville_id,
                    contact_telephone: l.contact_telephone,
                    delai_preparation_min: l.delai_preparation_min,
                    statut: l
                        .statut
                        .parse()
                        .map_err(ErreurPrestataires::FicheInvalide)?,
                    statut_decide_par: l.statut_decide_par,
                    statut_decide_le: l.statut_decide_le,
                    statut_motif: l.statut_motif,
                    jeton_plaque: l.jeton_plaque,
                    code_secours: l.code_secours,
                    cree_le: l.cree_le,
                    modifie_le: l.modifie_le,
                })
            })
            .collect()
    }

    /// Fiche par identifiant, dans la transaction en cours.
    pub(crate) async fn prestataire_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
    ) -> Result<Prestataire, ErreurPrestataires> {
        let ligne = sqlx::query!(
            r#"SELECT p.id, p.nom, p.categorie_id, c.slug AS categorie_slug, p.ville_id,
                      p.contact_telephone, p.delai_preparation_min,
                      p.statut::text AS "statut!", p.statut_decide_par, p.statut_decide_le,
                      p.statut_motif, p.jeton_plaque, p.code_secours, p.cree_le, p.modifie_le
               FROM prestataires.prestataire p
               JOIN zones.categorie c ON c.id = p.categorie_id
               WHERE p.id = $1"#,
            id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurPrestataires::PrestataireInconnu(id))?;

        Ok(Prestataire {
            id: ligne.id,
            nom: ligne.nom,
            categorie_id: ligne.categorie_id,
            categorie_slug: ligne.categorie_slug,
            ville_id: ligne.ville_id,
            contact_telephone: ligne.contact_telephone,
            delai_preparation_min: ligne.delai_preparation_min,
            statut: ligne
                .statut
                .parse()
                .map_err(ErreurPrestataires::FicheInvalide)?,
            statut_decide_par: ligne.statut_decide_par,
            statut_decide_le: ligne.statut_decide_le,
            statut_motif: ligne.statut_motif,
            jeton_plaque: ligne.jeton_plaque,
            code_secours: ligne.code_secours,
            cree_le: ligne.cree_le,
            modifie_le: ligne.modifie_le,
        })
    }

    // ── Aides internes ─────────────────────────────────────────────────────

    /// Catégorie de service par slug — FR-002.
    pub(crate) async fn categorie_par_slug(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        slug: &str,
    ) -> Result<Uuid, ErreurPrestataires> {
        sqlx::query_scalar!("SELECT id FROM zones.categorie WHERE slug = $1", slug)
            .fetch_optional(&mut **tx)
            .await?
            .ok_or_else(|| ErreurPrestataires::CategorieInconnue(slug.to_owned()))
    }

    /// Refuse toute zone qui n'est pas de type `ville` — seule granularité que
    /// l'activation de catégorie sait lire (FR-002, ZON-03).
    pub(crate) async fn verifier_ville(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        zone: Uuid,
    ) -> Result<(), ErreurPrestataires> {
        let type_zone: Option<String> = sqlx::query_scalar!(
            r#"SELECT type::text AS "type!" FROM zones.zone WHERE id = $1"#,
            zone
        )
        .fetch_optional(&mut **tx)
        .await?;
        match type_zone.as_deref() {
            None => Err(zones::ErreurZones::ZoneInconnue(zone).into()),
            Some("ville") => Ok(()),
            Some(_) => Err(ErreurPrestataires::ZoneNonVille(zone)),
        }
    }

    /// Émet `prestataire.modifie` — noms de champs SEULEMENT, jamais leurs
    /// valeurs (minimisation FR-052).
    async fn emettre_modification(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        champs: &[&str],
        acteur: Uuid,
    ) -> Result<(), ErreurPrestataires> {
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "prestataire.modifie",
                entite_type: "prestataire",
                entite_id: prestataire,
                payload: json!({ "champs": champs, "acteur": acteur }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        Ok(())
    }
}

// ── Cycle de vie (FR-004, FR-009, FR-010 — data-model §4.1) ────────────────

/// Actions du cycle de vie — décisions ADMIN, jamais automatiques.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ActionPrestataire {
    /// prospect → agree (fiche + charte + site complets — FR-005).
    Agreer,
    /// agree → suspendu (motif REQUIS — FR-010).
    Suspendre,
    /// suspendu → agree (plaque INCHANGÉE — SC-003).
    Retablir,
}

/// Table de transitions EXHAUSTIVE du cycle de vie (FR-004) — pure, testée
/// case par case. `None` = transition refusée.
pub fn transition(
    avant: StatutPrestataire,
    action: ActionPrestataire,
) -> Option<StatutPrestataire> {
    match (avant, action) {
        (StatutPrestataire::Prospect, ActionPrestataire::Agreer) => Some(StatutPrestataire::Agree),
        (StatutPrestataire::Agree, ActionPrestataire::Suspendre) => {
            Some(StatutPrestataire::Suspendu)
        }
        (StatutPrestataire::Suspendu, ActionPrestataire::Retablir) => {
            Some(StatutPrestataire::Agree)
        }
        _ => None,
    }
}

impl PgPrestataires {
    /// Agrée un prospect (VND-01). Refus MOTIVÉ si la fiche est incomplète
    /// (FR-005) ; au PREMIER agrément, l'identité de plaque est générée
    /// (FR-013) ; le compteur d'activation de la catégorie est recalculé dans
    /// la MÊME transaction (FR-009, research R7). Émet `prestataire.agree`.
    pub async fn agreer(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        acteur: Uuid,
    ) -> Result<Prestataire, ErreurPrestataires> {
        let p = self.verrouiller(tx, prestataire).await?;
        exiger_transition(p.statut, ActionPrestataire::Agreer, StatutPrestataire::Agree)?;

        // Complétude (FR-005) : fiche (≥ 1 photo), charte signée, site doté
        // d'au moins une plage d'horaires. Manques STABLES, tous remontés.
        let mut manques: Vec<&'static str> = Vec::new();
        let a_photo = sqlx::query_scalar!(
            r#"SELECT EXISTS(SELECT 1 FROM prestataires.photo_prestataire
                             WHERE prestataire_id = $1) AS "existe!""#,
            prestataire,
        )
        .fetch_one(&mut **tx)
        .await?;
        if !a_photo {
            manques.push("photo");
        }
        let a_charte = sqlx::query_scalar!(
            r#"SELECT EXISTS(SELECT 1 FROM prestataires.charte_signee
                             WHERE prestataire_id = $1) AS "existe!""#,
            prestataire,
        )
        .fetch_one(&mut **tx)
        .await?;
        if !a_charte {
            manques.push("charte_signee");
        }
        match self.site_optionnel_dans_tx(tx, prestataire).await? {
            None => manques.push("site"),
            Some(site) => {
                let plages = sqlx::query_scalar!(
                    r#"SELECT count(*) AS "n!" FROM prestataires.horaire_site WHERE site_id = $1"#,
                    site.id,
                )
                .fetch_one(&mut **tx)
                .await?;
                if plages == 0 {
                    manques.push("horaires");
                }
            }
        }
        if !manques.is_empty() {
            return Err(ErreurPrestataires::AgrementIncomplet { manques });
        }

        // Identité de plaque : posée au PREMIER agrément, stable ensuite.
        let plaque_creee = p.jeton_plaque.is_none();
        let (jeton, code) = if plaque_creee {
            (
                Some(crate::plaque::generer_jeton(&self.secret_plaque, prestataire)),
                Some(crate::plaque::generer_code_secours()),
            )
        } else {
            (None, None)
        };
        sqlx::query!(
            "UPDATE prestataires.prestataire
             SET statut = 'agree', statut_decide_par = $2, statut_decide_le = now(),
                 statut_motif = NULL,
                 jeton_plaque = COALESCE($3, jeton_plaque),
                 code_secours = COALESCE($4, code_secours),
                 modifie_le = now()
             WHERE id = $1",
            prestataire,
            acteur,
            jeton,
            code,
        )
        .execute(&mut **tx)
        .await?;

        self.recalculer_activation_apres(tx, p.ville_id, p.categorie_id, &p.categorie_slug)
            .await?;
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "prestataire.agree",
                entite_type: "prestataire",
                entite_id: prestataire,
                payload: json!({
                    "zone": p.ville_id,
                    "categorie": p.categorie_slug,
                    "plaque_creee": plaque_creee,
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        self.prestataire_dans_tx(tx, prestataire).await
    }

    /// Suspend un agréé (motif REQUIS — FR-010). La fiche cesse d'être servie,
    /// la commandabilité et la validité du jeton tombent PAR DÉRIVATION —
    /// aucune action distincte (FR-015, SC-002). Le recalcul est déclenché,
    /// SANS effet attendu : le seuil ne joue qu'à la hausse (FR-009).
    pub async fn suspendre(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        motif: &str,
        acteur: Uuid,
    ) -> Result<Prestataire, ErreurPrestataires> {
        if motif.trim().is_empty() {
            return Err(ErreurPrestataires::MotifRequis);
        }
        let p = self.verrouiller(tx, prestataire).await?;
        exiger_transition(
            p.statut,
            ActionPrestataire::Suspendre,
            StatutPrestataire::Suspendu,
        )?;

        sqlx::query!(
            "UPDATE prestataires.prestataire
             SET statut = 'suspendu', statut_decide_par = $2, statut_decide_le = now(),
                 statut_motif = $3, modifie_le = now()
             WHERE id = $1",
            prestataire,
            acteur,
            motif.trim(),
        )
        .execute(&mut **tx)
        .await?;

        self.recalculer_activation_apres(tx, p.ville_id, p.categorie_id, &p.categorie_slug)
            .await?;
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "prestataire.suspendu",
                entite_type: "prestataire",
                entite_id: prestataire,
                payload: json!({
                    "zone": p.ville_id,
                    "categorie": p.categorie_slug,
                    "motif": motif.trim(),
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        self.prestataire_dans_tx(tx, prestataire).await
    }

    /// Rétablit un suspendu : tout revient — MÊME jeton, MÊME code de secours
    /// (SC-003), recalcul d'activation (FR-009). Émet `prestataire.retabli`.
    pub async fn retablir(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        acteur: Uuid,
    ) -> Result<Prestataire, ErreurPrestataires> {
        let p = self.verrouiller(tx, prestataire).await?;
        exiger_transition(
            p.statut,
            ActionPrestataire::Retablir,
            StatutPrestataire::Agree,
        )?;

        sqlx::query!(
            "UPDATE prestataires.prestataire
             SET statut = 'agree', statut_decide_par = $2, statut_decide_le = now(),
                 statut_motif = NULL, modifie_le = now()
             WHERE id = $1",
            prestataire,
            acteur,
        )
        .execute(&mut **tx)
        .await?;

        self.recalculer_activation_apres(tx, p.ville_id, p.categorie_id, &p.categorie_slug)
            .await?;
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "prestataire.retabli",
                entite_type: "prestataire",
                entite_id: prestataire,
                payload: json!({
                    "zone": p.ville_id,
                    "categorie": p.categorie_slug,
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        self.prestataire_dans_tx(tx, prestataire).await
    }

    /// Recompte les agréés du couple catégorie/ville et appelle le recalcul
    /// d'activation ZON-03 dans la MÊME transaction (research R7). Le crate
    /// `zones` ne connaît pas les vendeurs : le comptage est ici.
    pub(crate) async fn recalculer_activation_apres(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ville: Uuid,
        categorie: Uuid,
        categorie_slug: &str,
    ) -> Result<(), ErreurPrestataires> {
        let agrees = sqlx::query_scalar!(
            r#"SELECT count(*) AS "n!" FROM prestataires.prestataire
               WHERE ville_id = $1 AND categorie_id = $2
                 AND statut = 'agree'::prestataires.statut_prestataire"#,
            ville,
            categorie,
        )
        .fetch_one(&mut **tx)
        .await?;
        self.zones
            .recalculer_activation(tx, ville, categorie_slug, agrees)
            .await?;
        Ok(())
    }

    /// Verrouille la ligne (décisions concurrentes sérialisées) puis la relit.
    async fn verrouiller(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
    ) -> Result<Prestataire, ErreurPrestataires> {
        sqlx::query!(
            "SELECT id FROM prestataires.prestataire WHERE id = $1 FOR UPDATE",
            prestataire,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurPrestataires::PrestataireInconnu(prestataire))?;
        self.prestataire_dans_tx(tx, prestataire).await
    }
}

/// Applique la table de transitions, en erreur 409 sinon.
fn exiger_transition(
    avant: StatutPrestataire,
    action: ActionPrestataire,
    apres: StatutPrestataire,
) -> Result<(), ErreurPrestataires> {
    match transition(avant, action) {
        Some(cible) => {
            debug_assert_eq!(cible, apres);
            Ok(())
        }
        None => Err(ErreurPrestataires::TransitionInvalide { avant, apres }),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Table de transitions conforme à data-model §4.1 — EXHAUSTIVE (3 × 3).
    #[test]
    fn table_de_transitions_conforme_au_data_model() {
        use ActionPrestataire::*;
        use StatutPrestataire::*;
        let cas = [
            (Prospect, Agreer, Some(Agree)),
            (Prospect, Suspendre, None),
            (Prospect, Retablir, None),
            (Agree, Agreer, None),
            (Agree, Suspendre, Some(Suspendu)),
            (Agree, Retablir, None),
            (Suspendu, Agreer, None),
            (Suspendu, Suspendre, None),
            (Suspendu, Retablir, Some(Agree)),
        ];
        for (avant, action, attendu) in cas {
            assert_eq!(
                transition(avant, action),
                attendu,
                "{avant} × {action:?}"
            );
        }
    }
}

/// Validation commune des champs de fiche (création et modification).
fn valider_champs(
    nom: &str,
    contact: &str,
    delai_preparation_min: i32,
) -> Result<(), ErreurPrestataires> {
    if nom.trim().is_empty() {
        return Err(ErreurPrestataires::FicheInvalide("nom vide".to_owned()));
    }
    if contact.trim().is_empty() {
        return Err(ErreurPrestataires::FicheInvalide(
            "contact téléphonique vide".to_owned(),
        ));
    }
    if delai_preparation_min < 0 {
        return Err(ErreurPrestataires::FicheInvalide(
            "délai de préparation négatif".to_owned(),
        ));
    }
    Ok(())
}

/// Validation commune des médias (type + taille) — FR-025.
fn valider_media(
    octets: &[u8],
    mime: &str,
    acceptes: &[&str],
    taille_max: usize,
) -> Result<(), ErreurPrestataires> {
    if !acceptes.contains(&mime) {
        return Err(ErreurPrestataires::MediaInvalide(format!(
            "type refusé : {mime}"
        )));
    }
    if octets.is_empty() {
        return Err(ErreurPrestataires::MediaInvalide("objet vide".to_owned()));
    }
    if octets.len() > taille_max {
        return Err(ErreurPrestataires::ObjetTropVolumineux);
    }
    Ok(())
}
