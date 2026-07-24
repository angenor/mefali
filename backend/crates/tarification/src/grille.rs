//! Cycle de vie d'une grille tarifaire : brouillon, simulation, publication
//! (US1/US3, research R7).
//!
//! La **garde de publication** est ici, et nulle part ailleurs : publier exige
//! une simulation portant sur l'**empreinte courante** du brouillon ET aucune
//! règle hors bornes (FR-021). Toute édition de règle change l'empreinte, donc
//! **réarme** l'obligation — « ce qui est simulé est ce qui sera publié ».

use chrono::{DateTime, Utc};
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::modele::{ErreurTarif, EtatGrille, Grille, Regle};
use crate::PgTarification;

/// En-tête d'une grille, sans ses règles — ce qu'il faut pour garder une
/// écriture (état, zone) sans payer le chargement du catalogue.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Entete {
    pub(crate) id: Uuid,
    pub(crate) zone_id: Uuid,
    pub(crate) version: i32,
    pub(crate) etat: EtatGrille,
    pub(crate) effet_le: Option<DateTime<Utc>>,
    pub(crate) simulee_le: Option<DateTime<Utc>>,
    pub(crate) simulee_empreinte: Option<String>,
}

/// Charge l'en-tête d'une grille sur une connexion quelconque (pool OU
/// transaction) — une écriture doit lire dans SA transaction.
pub(crate) async fn charger_entete(
    conn: &mut sqlx::PgConnection,
    grille_id: Uuid,
) -> Result<Option<Entete>, ErreurTarif> {
    let ligne = sqlx::query!(
        r#"SELECT id, zone_id, version, etat::text AS "etat!", effet_le, simulee_le,
                  simulee_empreinte
           FROM tarification.grille WHERE id = $1"#,
        grille_id,
    )
    .fetch_optional(&mut *conn)
    .await?;
    Ok(ligne.map(|l| Entete {
        id: l.id,
        zone_id: l.zone_id,
        version: l.version,
        etat: l.etat.parse().expect("énum Postgres tarification.etat_grille"),
        effet_le: l.effet_le,
        simulee_le: l.simulee_le,
        simulee_empreinte: l.simulee_empreinte,
    }))
}

/// Charge les règles d'une grille, **triées par `id`** — ordre stable qui rend
/// l'empreinte et la sélection rejouables (research R5/R7).
pub(crate) async fn charger_regles(
    conn: &mut sqlx::PgConnection,
    grille_id: Uuid,
) -> Result<Vec<Regle>, ErreurTarif> {
    let lignes = sqlx::query!(
        r#"SELECT id, grille_id, transport_slug, categorie_slug, distance_min_m, distance_max_m,
                  plage_debut_min, plage_fin_min, jours_masque, point_relais_id,
                  part_coursier_base, marge, prix_par_km, seuil_km_m, prix_plafond, devise,
                  priorite, actif
           FROM tarification.regle WHERE grille_id = $1 ORDER BY id"#,
        grille_id,
    )
    .fetch_all(&mut *conn)
    .await?;
    Ok(lignes
        .into_iter()
        .map(|l| Regle {
            id: l.id,
            grille_id: l.grille_id,
            transport_slug: l.transport_slug,
            categorie_slug: l.categorie_slug,
            distance_min_m: l.distance_min_m,
            distance_max_m: l.distance_max_m,
            plage_debut_min: l.plage_debut_min,
            plage_fin_min: l.plage_fin_min,
            jours_masque: l.jours_masque,
            point_relais_id: l.point_relais_id,
            part_coursier_base: l.part_coursier_base,
            marge: l.marge,
            prix_par_km: l.prix_par_km,
            seuil_km_m: l.seuil_km_m,
            prix_plafond: l.prix_plafond,
            devise: l.devise,
            priorite: l.priorite,
            actif: l.actif,
        })
        .collect())
}

/// Assemble une grille complète (en-tête + règles) sur une connexion.
pub(crate) async fn charger(
    conn: &mut sqlx::PgConnection,
    grille_id: Uuid,
) -> Result<Option<Grille>, ErreurTarif> {
    let Some(entete) = charger_entete(&mut *conn, grille_id).await? else {
        return Ok(None);
    };
    let regles = charger_regles(&mut *conn, grille_id).await?;
    Ok(Some(Grille {
        id: entete.id,
        zone_id: entete.zone_id,
        version: entete.version,
        etat: entete.etat,
        effet_le: entete.effet_le,
        simulee_le: entete.simulee_le,
        simulee_empreinte: entete.simulee_empreinte,
        regles,
    }))
}

impl PgTarification {
    /// Grille dans un état donné pour une zone (au plus une — index uniques
    /// partiels `grille_en_vigueur_unique` / `grille_brouillon_unique`).
    async fn grille_de_zone(
        &self,
        zone: Uuid,
        etat: EtatGrille,
    ) -> Result<Option<Grille>, ErreurTarif> {
        let id: Option<Uuid> = sqlx::query_scalar!(
            "SELECT id FROM tarification.grille
             WHERE zone_id = $1 AND etat = $2::text::tarification.etat_grille",
            zone,
            etat.comme_str(),
        )
        .fetch_optional(&self.pool)
        .await?;
        let Some(id) = id else { return Ok(None) };
        let mut conn = self.pool.acquire().await?;
        charger(&mut conn, id).await
    }

    /// Grille **en vigueur** de la zone (celle qui tarife), ou `None`.
    pub async fn grille_en_vigueur(&self, zone: Uuid) -> Result<Option<Grille>, ErreurTarif> {
        self.grille_de_zone(zone, EtatGrille::EnVigueur).await
    }

    /// **Brouillon** de la zone, ou `None` s'il n'y en a pas.
    pub async fn brouillon(&self, zone: Uuid) -> Result<Option<Grille>, ErreurTarif> {
        self.grille_de_zone(zone, EtatGrille::Brouillon).await
    }

    /// Grille par identifiant (toute zone, tout état).
    pub async fn grille(&self, grille_id: Uuid) -> Result<Grille, ErreurTarif> {
        let mut conn = self.pool.acquire().await?;
        charger(&mut conn, grille_id)
            .await?
            .ok_or(ErreurTarif::GrilleInconnue(grille_id))
    }

    /// Crée le brouillon de la zone, ou rend celui qui existe — **idempotent**
    /// (T010, contrat `POST zones/{zone}/brouillon`).
    ///
    /// À la création, le brouillon **clone la grille en vigueur** : l'admin part
    /// du tarif réel et corrige, il ne repart pas d'une grille vide qui
    /// n'appliquerait plus aucun prix. Sans grille en vigueur (zone neuve), le
    /// brouillon naît vide.
    ///
    /// `version` = max(version de la zone) + 1 : le numéro est acquis à la
    /// CRÉATION du brouillon, pas à sa publication — deux brouillons successifs
    /// ne peuvent pas se disputer un numéro.
    pub async fn obtenir_ou_creer_brouillon(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        zone: Uuid,
    ) -> Result<Grille, ErreurTarif> {
        // Verrou de la zone pendant la création : deux appels concurrents ne
        // doivent pas se heurter sur l'index unique partiel (l'un des deux
        // rendrait une erreur SQL brute au lieu du brouillon existant).
        let existant: Option<Uuid> = sqlx::query_scalar!(
            "SELECT id FROM tarification.grille
             WHERE zone_id = $1 AND etat = 'brouillon' FOR UPDATE",
            zone,
        )
        .fetch_optional(&mut **tx)
        .await?;
        if let Some(id) = existant {
            return charger(&mut **tx, id)
                .await?
                .ok_or(ErreurTarif::GrilleInconnue(id));
        }

        let version: i32 = sqlx::query_scalar!(
            r#"SELECT COALESCE(MAX(version), 0) + 1 AS "suivante!"
               FROM tarification.grille WHERE zone_id = $1"#,
            zone,
        )
        .fetch_one(&mut **tx)
        .await?;

        let id = Uuid::now_v7();
        sqlx::query!(
            "INSERT INTO tarification.grille (id, zone_id, version, etat)
             VALUES ($1, $2, $3, 'brouillon')",
            id,
            zone,
            version,
        )
        .execute(&mut **tx)
        .await?;

        // Clone des règles de la grille en vigueur, si elle existe. Les règles
        // reçoivent de NOUVEAUX identifiants : la grille historisée garde les
        // siennes intactes (traçabilité de version).
        let en_vigueur: Option<Uuid> = sqlx::query_scalar!(
            "SELECT id FROM tarification.grille WHERE zone_id = $1 AND etat = 'en_vigueur'",
            zone,
        )
        .fetch_optional(&mut **tx)
        .await?;
        if let Some(source) = en_vigueur {
            sqlx::query!(
                r#"
                INSERT INTO tarification.regle
                    (id, grille_id, transport_slug, categorie_slug, distance_min_m, distance_max_m,
                     plage_debut_min, plage_fin_min, jours_masque, part_coursier_base, marge,
                     prix_par_km, seuil_km_m, prix_plafond, devise, priorite, actif)
                SELECT uuidv7(), $1, transport_slug, categorie_slug, distance_min_m, distance_max_m,
                       plage_debut_min, plage_fin_min, jours_masque, part_coursier_base, marge,
                       prix_par_km, seuil_km_m, prix_plafond, devise, priorite, actif
                FROM tarification.regle WHERE grille_id = $2
                "#,
                id,
                source,
            )
            .execute(&mut **tx)
            .await?;
        }

        charger(&mut **tx, id)
            .await?
            .ok_or(ErreurTarif::GrilleInconnue(id))
    }
}

/// Empreinte SHA-256 du CONTENU tarifaire d'une grille.
///
/// Déterministe : les règles sont triées par `id` (UUIDv7, ordre stable) et
/// chaque champ qui influence un prix entre dans le condensé. Les champs
/// purement techniques (`grille_id`) en sont exclus — cloner un brouillon ne
/// doit pas invalider une simulation portant sur un contenu identique.
///
/// `actif` est inclus : désactiver une règle change ce qui sera facturé.
pub fn empreinte(regles: &[Regle]) -> String {
    let mut triees: Vec<&Regle> = regles.iter().collect();
    triees.sort_by_key(|r| r.id);

    let mut hacheur = Sha256::new();
    hacheur.update(b"tarification.grille.v1");
    for r in triees {
        // Séparateurs explicites : sans eux, deux champs adjacents pourraient se
        // « décaler » et deux grilles distinctes partager une empreinte.
        hacheur.update(r.id.as_bytes());
        hacheur.update(b"|");
        hacheur.update(r.transport_slug.as_bytes());
        hacheur.update(b"|");
        hacheur.update(r.categorie_slug.as_deref().unwrap_or("*").as_bytes());
        hacheur.update(b"|");
        for entier in [
            r.distance_min_m as i64,
            r.distance_max_m.map_or(-1, i64::from),
            r.plage_debut_min.map_or(-1, i64::from),
            r.plage_fin_min.map_or(-1, i64::from),
            r.jours_masque.map_or(-1, i64::from),
            r.part_coursier_base,
            r.marge,
            r.prix_par_km,
            r.seuil_km_m as i64,
            r.prix_plafond.unwrap_or(-1),
            r.priorite as i64,
            i64::from(r.actif),
        ] {
            hacheur.update(entier.to_be_bytes());
            hacheur.update(b",");
        }
        hacheur.update(r.devise.as_bytes());
        hacheur.update(b";");
    }
    hex(&hacheur.finalize())
}

/// base16 minuscule (patron `qr::verification` / `comptes::session` — sha2 0.11
/// rend un `Array`, qui n'implémente pas `LowerHex`).
fn hex(octets: &[u8]) -> String {
    use std::fmt::Write;
    let mut s = String::with_capacity(octets.len() * 2);
    for o in octets {
        write!(s, "{o:02x}").expect("écriture en mémoire");
    }
    s
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    fn regle(id: Uuid, marge: i64) -> Regle {
        Regle {
            id,
            grille_id: Uuid::now_v7(),
            transport_slug: "moto".to_owned(),
            categorie_slug: None,
            distance_min_m: 0,
            distance_max_m: None,
            plage_debut_min: None,
            plage_fin_min: None,
            jours_masque: None,
            point_relais_id: None,
            part_coursier_base: 150,
            marge,
            prix_par_km: 50,
            seuil_km_m: 2000,
            prix_plafond: Some(500),
            devise: "XOF".to_owned(),
            priorite: 0,
            actif: true,
        }
    }

    /// L'empreinte ne dépend NI de l'ordre de lecture NI de la grille porteuse :
    /// sans cela, cloner la grille en vigueur en brouillon invaliderait une
    /// simulation portant sur un contenu strictement identique.
    #[test]
    fn empreinte_stable_par_contenu() {
        let (a, b) = (Uuid::now_v7(), Uuid::now_v7());
        let ordre_un = vec![regle(a, 50), regle(b, 60)];
        let mut ordre_deux = vec![regle(b, 60), regle(a, 50)];
        ordre_deux[0].grille_id = Uuid::now_v7();
        assert_eq!(empreinte(&ordre_un), empreinte(&ordre_deux));
    }

    /// Toute édition tarifaire change l'empreinte — c'est ce qui RÉARME la garde
    /// de publication (FR-021).
    #[test]
    fn empreinte_change_a_chaque_edition() {
        let id = Uuid::now_v7();
        let base = vec![regle(id, 50)];
        let reference = empreinte(&base);

        let mut marge_modifiee = base.clone();
        marge_modifiee[0].marge = 60;
        assert_ne!(reference, empreinte(&marge_modifiee), "marge");

        let mut desactivee = base.clone();
        desactivee[0].actif = false;
        assert_ne!(reference, empreinte(&desactivee), "actif");

        let mut plafond_retire = base.clone();
        plafond_retire[0].prix_plafond = None;
        assert_ne!(reference, empreinte(&plafond_retire), "plafond");

        let mut ajout = base.clone();
        ajout.push(regle(Uuid::now_v7(), 50));
        assert_ne!(reference, empreinte(&ajout), "règle ajoutée");

        assert_ne!(reference, empreinte(&[]), "brouillon vidé");
    }
}
