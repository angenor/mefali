//! Adresses enregistrées avec repère vocal (CPT-05, FR-019 → FR-022).
//!
//! ## Pourquoi une adresse porte une note vocale
//!
//! À Tiassalé, il n'y a pas de nom de rue. Ce qui permet à un coursier de
//! trouver Awa, c'est « derrière la pharmacie, portail bleu » — dit, pas écrit
//! (cadrage §8.2 : pensé pour les personnes peu technophiles ou peu lettrées).
//! L'adresse enregistrée conserve donc le repère TEL QUEL, octets compris.
//!
//! ## Pourquoi la purge existe
//!
//! Une note vocale est une donnée personnelle. La conserver au-delà de son
//! usage est une faute de minimisation (ARTCI, constitution VIII) : elle est
//! purgée après 12 mois SANS UTILISATION de l'adresse — durée en paramètre de
//! zone, jamais en dur. L'adresse, elle, SURVIT : elle redemande simplement un
//! repère à la prochaine utilisation (FR-022).

use chrono::{DateTime, Duration, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;
use zones::ConfigurationZones;

use crate::depot::PgComptes;
use crate::modele::{Adresse, ErreurComptes};

/// Clé du paramètre de zone bornant la durée d'une note vocale (FR-019).
pub const CLE_NOTE_VOCALE_DUREE_MAX: &str = "medias.note_vocale_duree_max_s";

/// Clé du paramètre de zone portant la rétention du repère vocal (FR-022).
pub const CLE_RETENTION_REPERE: &str = "adresse.retention_repere_vocal_jours";

/// Taille maximale d'une note vocale.
///
/// CONSTANTE PRODUIT : 1,5 Mo tient largement 30 s d'AAC à débit mobile, et
/// borne ce qu'un client peut pousser. La DURÉE, elle, est un paramètre de zone
/// — c'est elle qui est une décision produit locale, pas les octets.
pub const NOTE_VOCALE_TAILLE_MAX: usize = 1_536 * 1024;

/// Types MIME acceptés pour une note vocale (contrat `NouvelleAdresse`).
pub const NOTE_VOCALE_MIMES: &[&str] = &["audio/mp4", "audio/aac", "audio/m4a", "audio/x-m4a"];

/// Longueurs maximales du contrat.
pub const LIBELLE_MAX: usize = 60;
/// Longueur maximale du repère écrit (contrat).
pub const REPERE_TEXTE_MAX: usize = 500;

/// Note vocale de repère soumise.
#[derive(Debug, Clone)]
pub struct NoteVocale {
    /// Contenu du fichier.
    pub octets: Vec<u8>,
    /// Type MIME déclaré, validé ici.
    pub mime: String,
    /// Durée annoncée — bornée par le paramètre de zone.
    pub duree_s: i16,
}

/// Ce que le client enregistre après une livraison réussie (FR-019).
#[derive(Debug, Clone)]
pub struct NouvelleAdresse {
    /// « Maison », « Bureau » ou libre — CONTENU utilisateur, pas une clé i18n.
    pub libelle: String,
    /// Latitude du pin GPS.
    pub lat: f64,
    /// Longitude du pin GPS.
    pub lng: f64,
    /// Repère écrit.
    pub repere_texte: Option<String>,
    /// Repère parlé.
    pub note_vocale: Option<NoteVocale>,
    /// PROVISION — posé par CMD/CRS plus tard ; aucune logique ne le lit.
    pub livraison_origine: Option<Uuid>,
}

/// Champs modifiables d'une adresse (FR-021).
///
/// `Option<Option<String>>` sur le repère : `None` = ne pas toucher,
/// `Some(None)` = effacer, `Some(Some(t))` = remplacer. Un simple
/// `Option<String>` ne saurait pas distinguer « laisse » de « efface ».
#[derive(Debug, Clone, Default)]
pub struct ModificationAdresse {
    /// Nouveau libellé.
    pub libelle: Option<String>,
    /// Nouveau repère écrit (`Some(None)` efface).
    pub repere_texte: Option<Option<String>>,
}

impl PgComptes {
    /// Enregistre une adresse (FR-019).
    ///
    /// `id` est la clé d'idempotence du client (R14) : un rejeu rend l'adresse
    /// EXISTANTE sans doublon ni second événement. C'est ce qui protège Awa
    /// d'une liste d'adresses en double après un timeout.
    pub async fn enregistrer_adresse(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
        compte: Uuid,
        nouvelle: &NouvelleAdresse,
    ) -> Result<Adresse, ErreurComptes> {
        let zone = self.zone_du_compte_adresse(tx, compte).await?;

        let libelle = nouvelle.libelle.trim();
        if libelle.is_empty() || libelle.chars().count() > LIBELLE_MAX {
            return Err(ErreurComptes::MediaInvalide("libelle".to_owned()));
        }
        let repere_texte = nettoyer_repere(nouvelle.repere_texte.as_deref())?;

        // Rejeu : l'adresse est déjà là. On la rend telle quelle — sans
        // redéposer la note vocale ni ré-émettre l'événement.
        if let Some(existante) = self.adresse_dans_tx(tx, id, compte).await? {
            return Ok(existante);
        }

        let cle_vocale = match &nouvelle.note_vocale {
            None => None,
            Some(note) => Some(self.deposer_note(compte, zone, note).await?),
        };
        let duree = nouvelle.note_vocale.as_ref().map(|n| n.duree_s);

        let maintenant = Utc::now();
        let ligne = sqlx::query!(
            r#"INSERT INTO comptes.adresse
                 (id, compte_id, libelle, lat, lng, repere_texte,
                  repere_vocal_cle_objet, repere_vocal_duree_s, zone_id,
                  livraison_origine, cree_le, derniere_utilisation_le)
               VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $11)
               -- Rejeu concurrent : deux requêtes de la même clé en vol. La
               -- seconde ne crée rien et ne rend rien — on relit ensuite.
               ON CONFLICT (id) DO NOTHING
               RETURNING cree_le"#,
            id,
            compte,
            libelle,
            nouvelle.lat,
            nouvelle.lng,
            repere_texte,
            cle_vocale,
            duree,
            zone,
            nouvelle.livraison_origine,
            maintenant,
        )
        .fetch_optional(&mut **tx)
        .await?;

        if ligne.is_none() {
            // La course est perdue : l'autre requête a créé l'adresse.
            return self
                .adresse_dans_tx(tx, id, compte)
                .await?
                .ok_or(ErreurComptes::AdresseInconnue(id));
        }

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "adresse.enregistree",
                entite_type: "adresse",
                entite_id: id,
                // Minimisation ARTCI : ni libellé, ni GPS, ni repère ne sortent
                // en événement — seulement des booléens de PRÉSENCE (T004).
                payload: json!({
                    "zone": zone,
                    "compte": compte,
                    "a_repere_texte": repere_texte.is_some(),
                    "a_repere_vocal": cle_vocale.is_some(),
                    "livraison_origine": nouvelle.livraison_origine,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;

        Ok(Adresse {
            id,
            compte_id: compte,
            libelle: libelle.to_owned(),
            lat: nouvelle.lat,
            lng: nouvelle.lng,
            repere_texte,
            repere_vocal_cle_objet: cle_vocale,
            repere_vocal_duree_s: duree,
            zone_id: zone,
            livraison_origine: nouvelle.livraison_origine,
            cree_le: maintenant,
            derniere_utilisation_le: maintenant,
            supprimee_le: None,
        })
    }

    /// Renomme l'adresse ou change son repère écrit (FR-021).
    ///
    /// Ne vaut QUE pour l'avenir : les livraisons passées ont figé ce dont
    /// elles avaient besoin, ce module ne les connaît pas.
    pub async fn modifier_adresse(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
        compte: Uuid,
        modification: &ModificationAdresse,
    ) -> Result<Adresse, ErreurComptes> {
        let existante = self
            .adresse_dans_tx(tx, id, compte)
            .await?
            .ok_or(ErreurComptes::AdresseInconnue(id))?;

        let mut champs: Vec<&str> = Vec::new();
        let libelle = match &modification.libelle {
            None => existante.libelle.clone(),
            Some(l) => {
                let l = l.trim();
                if l.is_empty() || l.chars().count() > LIBELLE_MAX {
                    return Err(ErreurComptes::MediaInvalide("libelle".to_owned()));
                }
                champs.push("libelle");
                l.to_owned()
            }
        };
        let repere_texte = match &modification.repere_texte {
            None => existante.repere_texte.clone(),
            Some(r) => {
                champs.push("repere_texte");
                nettoyer_repere(r.as_deref())?
            }
        };

        if champs.is_empty() {
            // Rien à changer : ne pas écrire d'événement pour un non-événement.
            return Ok(existante);
        }

        let maintenant = Utc::now();
        sqlx::query!(
            "UPDATE comptes.adresse SET libelle = $3, repere_texte = $4
             WHERE id = $1 AND compte_id = $2",
            id,
            compte,
            libelle,
            repere_texte,
        )
        .execute(&mut **tx)
        .await?;

        self.emettre_adresse_modifiee(tx, &existante, &champs, maintenant)
            .await?;

        Ok(Adresse {
            libelle,
            repere_texte,
            ..existante
        })
    }

    /// Remplace le repère vocal — après purge, ou pour le refaire (FR-022).
    pub async fn remplacer_repere_vocal(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
        compte: Uuid,
        note: &NoteVocale,
    ) -> Result<Adresse, ErreurComptes> {
        let existante = self
            .adresse_dans_tx(tx, id, compte)
            .await?
            .ok_or(ErreurComptes::AdresseInconnue(id))?;

        let cle = self.deposer_note(compte, existante.zone_id, note).await?;
        let maintenant = Utc::now();
        sqlx::query!(
            "UPDATE comptes.adresse
             SET repere_vocal_cle_objet = $3, repere_vocal_duree_s = $4
             WHERE id = $1 AND compte_id = $2",
            id,
            compte,
            cle,
            note.duree_s,
        )
        .execute(&mut **tx)
        .await?;

        self.emettre_adresse_modifiee(tx, &existante, &["repere_vocal"], maintenant)
            .await?;

        Ok(Adresse {
            repere_vocal_cle_objet: Some(cle),
            repere_vocal_duree_s: Some(note.duree_s),
            ..existante
        })
    }

    /// Supprime une adresse — SOFT (FR-021).
    ///
    /// Soft parce qu'une commande passée peut encore la référencer : l'effacer
    /// vraiment réécrirait l'histoire.
    pub async fn supprimer_adresse(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
        compte: Uuid,
    ) -> Result<(), ErreurComptes> {
        let existante = self
            .adresse_dans_tx(tx, id, compte)
            .await?
            .ok_or(ErreurComptes::AdresseInconnue(id))?;

        let maintenant = Utc::now();
        sqlx::query!(
            "UPDATE comptes.adresse SET supprimee_le = $3 WHERE id = $1 AND compte_id = $2",
            id,
            compte,
            maintenant,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "adresse.supprimee",
                entite_type: "adresse",
                entite_id: id,
                payload: json!({ "zone": existante.zone_id, "compte": compte }),
                survenu_le: maintenant,
            },
        )
        .await?;
        Ok(())
    }

    /// Adresses vivantes d'un compte, la plus récemment utilisée d'abord.
    pub async fn adresses(&self, compte: Uuid) -> Result<Vec<Adresse>, ErreurComptes> {
        let lignes = sqlx::query!(
            r#"SELECT id, compte_id, libelle, lat, lng, repere_texte,
                      repere_vocal_cle_objet, repere_vocal_duree_s, zone_id,
                      livraison_origine, cree_le, derniere_utilisation_le, supprimee_le
               FROM comptes.adresse
               WHERE compte_id = $1 AND supprimee_le IS NULL
               ORDER BY derniere_utilisation_le DESC"#,
            compte,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| Adresse {
                id: l.id,
                compte_id: l.compte_id,
                libelle: l.libelle,
                lat: l.lat,
                lng: l.lng,
                repere_texte: l.repere_texte,
                repere_vocal_cle_objet: l.repere_vocal_cle_objet,
                repere_vocal_duree_s: l.repere_vocal_duree_s,
                zone_id: l.zone_id,
                livraison_origine: l.livraison_origine,
                cree_le: l.cree_le,
                derniere_utilisation_le: l.derniere_utilisation_le,
                supprimee_le: l.supprimee_le,
            })
            .collect())
    }

    /// Une adresse vivante du compte (propriété STRICTE).
    pub async fn adresse(&self, id: Uuid, compte: Uuid) -> Result<Adresse, ErreurComptes> {
        let mut tx = self.pool.begin().await?;
        let adresse = self.adresse_dans_tx(&mut tx, id, compte).await?;
        tx.rollback().await?;
        adresse.ok_or(ErreurComptes::AdresseInconnue(id))
    }

    /// Marque une adresse comme utilisée — recule sa purge d'autant (FR-022).
    ///
    /// Appelée par le module commandes (cycle CMD) à chaque réutilisation :
    /// c'est ce qui fait qu'une adresse dont on se sert ne perd JAMAIS son
    /// repère. Ce cycle ne l'appelle que dans ses tests.
    pub async fn marquer_adresse_utilisee(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
    ) -> Result<(), ErreurComptes> {
        sqlx::query!(
            "UPDATE comptes.adresse SET derniere_utilisation_le = now()
             WHERE id = $1 AND supprimee_le IS NULL",
            id,
        )
        .execute(&mut **tx)
        .await?;
        Ok(())
    }

    /// Purge les repères vocaux des adresses inutilisées depuis la rétention de
    /// leur zone (FR-022, research R8). Rend le nombre d'adresses purgées.
    ///
    /// ORDRE VOLONTAIRE, par adresse : transaction Postgres (clé → NULL +
    /// événement) PUIS suppression S3 best-effort. La vérité — « cette adresse
    /// n'a plus de repère vocal » — vit dans Postgres et est émise
    /// atomiquement ; l'objet est un artefact dont la suppression se rattrape.
    /// L'inverse laisserait, sur un crash entre les deux, des adresses pointant
    /// vers du vide.
    pub async fn purger_reperes_vocaux(&self) -> Result<u64, ErreurComptes> {
        // Candidates : toutes celles qui ont encore un repère vocal. La
        // rétention dépend de la ZONE, donc le filtre d'âge se fait en Rust —
        // une adresse d'une zone à 30 jours et une autre à 365 ne se trient pas
        // par la même requête.
        let candidates = sqlx::query!(
            r#"SELECT id, compte_id, zone_id, derniere_utilisation_le,
                      repere_vocal_cle_objet AS "cle!"
               FROM comptes.adresse
               WHERE repere_vocal_cle_objet IS NOT NULL AND supprimee_le IS NULL
               ORDER BY derniere_utilisation_le"#,
        )
        .fetch_all(&self.pool)
        .await?;

        let maintenant = Utc::now();
        let mut retentions: std::collections::HashMap<Uuid, i64> = std::collections::HashMap::new();
        let mut purgees = 0u64;

        for candidate in candidates {
            let jours = match retentions.get(&candidate.zone_id) {
                Some(j) => *j,
                None => {
                    let j = self.retention_jours(candidate.zone_id).await?;
                    retentions.insert(candidate.zone_id, j);
                    j
                }
            };
            if candidate.derniere_utilisation_le + Duration::days(jours) > maintenant {
                continue;
            }

            let mut tx = self.pool.begin().await?;
            sqlx::query!(
                "UPDATE comptes.adresse
                 SET repere_vocal_cle_objet = NULL, repere_vocal_duree_s = NULL
                 WHERE id = $1",
                candidate.id,
            )
            .execute(&mut *tx)
            .await?;
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "adresse.repere_vocal_purge",
                    entite_type: "adresse",
                    entite_id: candidate.id,
                    payload: json!({
                        "zone": candidate.zone_id,
                        "compte": candidate.compte_id,
                        "retention_jours": jours,
                        "derniere_utilisation_le": candidate.derniere_utilisation_le,
                    }),
                    survenu_le: maintenant,
                },
            )
            .await?;
            tx.commit().await?;

            // Best-effort : la ligne est déjà juste. Un échec ici laisse un
            // objet orphelin, que le passage suivant retentera — jamais une
            // adresse qui pointe dans le vide.
            if let Err(e) = self.objets.supprimer(&candidate.cle).await {
                tracing::warn!(
                    adresse = %candidate.id,
                    cle = %candidate.cle,
                    erreur = %e,
                    "repère vocal purgé en base, objet non supprimé — à rattraper",
                );
            }
            purgees += 1;
        }
        Ok(purgees)
    }

    /// Rétention du repère vocal pour une zone (FR-022) — jamais en dur.
    async fn retention_jours(&self, zone: Uuid) -> Result<i64, ErreurComptes> {
        self.zones
            .parametre(zone, CLE_RETENTION_REPERE)
            .await?
            .and_then(|v| v.as_i64())
            .ok_or_else(|| ErreurComptes::ConfigurationZoneInvalide {
                cle: CLE_RETENTION_REPERE,
                raison: "absent de la chaîne d'héritage de la zone".to_owned(),
            })
    }

    /// Dépose une note vocale après l'avoir validée contre la zone.
    async fn deposer_note(
        &self,
        compte: Uuid,
        zone: Uuid,
        note: &NoteVocale,
    ) -> Result<String, ErreurComptes> {
        if note.octets.is_empty() {
            return Err(ErreurComptes::MediaInvalide("note_vocale".to_owned()));
        }
        if note.octets.len() > NOTE_VOCALE_TAILLE_MAX {
            return Err(ErreurComptes::ObjetTropVolumineux);
        }
        if !NOTE_VOCALE_MIMES.contains(&note.mime.as_str()) {
            return Err(ErreurComptes::MediaInvalide(note.mime.clone()));
        }

        // La DURÉE est un paramètre de zone (FR-019/FR-024), pas une constante.
        let max = self
            .zones
            .parametre(zone, CLE_NOTE_VOCALE_DUREE_MAX)
            .await?
            .and_then(|v| v.as_i64())
            .ok_or_else(|| ErreurComptes::ConfigurationZoneInvalide {
                cle: CLE_NOTE_VOCALE_DUREE_MAX,
                raison: "absent de la chaîne d'héritage de la zone".to_owned(),
            })?;
        if note.duree_s <= 0 || i64::from(note.duree_s) > max {
            return Err(ErreurComptes::MediaInvalide("duree_s".to_owned()));
        }

        let cle = format!("comptes/reperes/{compte}/{}", Uuid::now_v7());
        self.objets
            .deposer(&cle, note.octets.clone(), &note.mime)
            .await?;
        Ok(cle)
    }

    /// Zone de rattachement du compte, dans la transaction en cours.
    async fn zone_du_compte_adresse(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
    ) -> Result<Uuid, ErreurComptes> {
        sqlx::query_scalar!("SELECT zone_id FROM comptes.compte WHERE id = $1", compte)
            .fetch_optional(&mut **tx)
            .await?
            .ok_or(ErreurComptes::CompteInconnu(compte))
    }

    /// Adresse vivante du compte, dans la transaction en cours.
    ///
    /// Le `compte_id` est dans le WHERE, pas dans un contrôle après coup :
    /// l'adresse d'autrui est INTROUVABLE, pas interdite (le 404 du contrat ne
    /// dit pas à un curieux qu'il a visé juste).
    async fn adresse_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        id: Uuid,
        compte: Uuid,
    ) -> Result<Option<Adresse>, ErreurComptes> {
        let ligne = sqlx::query!(
            r#"SELECT id, compte_id, libelle, lat, lng, repere_texte,
                      repere_vocal_cle_objet, repere_vocal_duree_s, zone_id,
                      livraison_origine, cree_le, derniere_utilisation_le, supprimee_le
               FROM comptes.adresse
               WHERE id = $1 AND compte_id = $2 AND supprimee_le IS NULL"#,
            id,
            compte,
        )
        .fetch_optional(&mut **tx)
        .await?;

        Ok(ligne.map(|l| Adresse {
            id: l.id,
            compte_id: l.compte_id,
            libelle: l.libelle,
            lat: l.lat,
            lng: l.lng,
            repere_texte: l.repere_texte,
            repere_vocal_cle_objet: l.repere_vocal_cle_objet,
            repere_vocal_duree_s: l.repere_vocal_duree_s,
            zone_id: l.zone_id,
            livraison_origine: l.livraison_origine,
            cree_le: l.cree_le,
            derniere_utilisation_le: l.derniere_utilisation_le,
            supprimee_le: l.supprimee_le,
        }))
    }

    /// Événement `adresse.modifiee` — payload commun (taxonomie T004).
    async fn emettre_adresse_modifiee(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        adresse: &Adresse,
        champs: &[&str],
        survenu_le: DateTime<Utc>,
    ) -> Result<(), ErreurComptes> {
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "adresse.modifiee",
                entite_type: "adresse",
                entite_id: adresse.id,
                payload: json!({
                    "zone": adresse.zone_id,
                    "compte": adresse.compte_id,
                    "champs": champs,
                }),
                survenu_le,
            },
        )
        .await?;
        Ok(())
    }
}

/// Valide et normalise un repère écrit (`None`/vide = pas de repère).
fn nettoyer_repere(repere: Option<&str>) -> Result<Option<String>, ErreurComptes> {
    match repere.map(str::trim).filter(|r| !r.is_empty()) {
        None => Ok(None),
        Some(r) if r.chars().count() > REPERE_TEXTE_MAX => {
            Err(ErreurComptes::MediaInvalide("repere_texte".to_owned()))
        }
        Some(r) => Ok(Some(r.to_owned())),
    }
}
