//! Site du prestataire : position, horaires hebdomadaires, statut de boutique
//! et ÉTAT EFFECTIF dérivé (FR-018, FR-030..036 — data-model §3.5, §4.2–4.3).
//!
//! Le modèle porte 1..n sites (provision VND-06) ; exactement UN est créé au
//! MVP et l'API le manipule comme ressource singulière (FR-019). L'état
//! effectif n'est JAMAIS stocké : [`etat_effectif`] est une fonction PURE de
//! l'état déclaré, des horaires et de l'horloge locale — les échéances (pause,
//! journée) s'absorbent à la lecture, sans ordonnanceur ni événement
//! (research R3).

use chrono::{DateTime, Datelike, Duration, NaiveDate, TimeZone, Utc};
use chrono_tz::Tz;
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgPrestataires;
use crate::modele::{
    EffectifBoutique, ErreurPrestataires, HorairesSemaine, Plage, SourceBascule, StatutBoutique,
};

/// Le site unique d'un prestataire (vue domaine — le GPS ne sort JAMAIS par la
/// consultation publique, SC-013).
#[derive(Debug, Clone, PartialEq)]
pub struct Site {
    /// Identifiant.
    pub id: Uuid,
    /// Prestataire porteur.
    pub prestataire_id: Uuid,
    /// Latitude relevée sur place (admin).
    pub position_lat: f64,
    /// Longitude.
    pub position_lng: f64,
    /// Statut DÉCLARÉ (FR-030) — l'effectif s'en déduit.
    pub statut_boutique: StatutBoutique,
    /// Échéance de pause (UTC) quand `statut_boutique = en_pause`.
    pub pause_fin: Option<DateTime<Utc>>,
    /// Date locale couverte quand `statut_boutique = ferme_journee`.
    pub ferme_journee_le: Option<NaiveDate>,
    /// Auteur du dernier changement décidé.
    pub statut_change_par: Option<Uuid>,
    /// Horodatage du dernier changement décidé.
    pub statut_change_le: Option<DateTime<Utc>>,
}

impl PgPrestataires {
    // ── Site unique : upsert admin (FR-019) ────────────────────────────────

    /// Crée ou met à jour LE site du prestataire : position, horaires, et —
    /// à la CRÉATION seulement — un statut initial (`ouvert` par défaut ;
    /// `en_pause`/`ferme_journee` refusés, ils exigent une échéance qui
    /// n'appartient qu'aux actions de boutique).
    ///
    /// Le remplacement des horaires émet `site.horaires_modifies` s'ils
    /// changent (source `admin` — FR-036) ; la position se corrige en silence
    /// (donnée d'exploitation, pas une transition de parcours).
    pub async fn definir_site(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        position_lat: f64,
        position_lng: f64,
        horaires: &HorairesSemaine,
        statut_initial: Option<StatutBoutique>,
        acteur: Uuid,
    ) -> Result<Site, ErreurPrestataires> {
        self.prestataire_dans_tx(tx, prestataire).await?;
        valider_horaires(horaires)?;
        if matches!(
            statut_initial,
            Some(StatutBoutique::EnPause | StatutBoutique::FermeJournee)
        ) {
            return Err(ErreurPrestataires::FicheInvalide(
                "statut initial de boutique : ouvert ou ferme seulement".to_owned(),
            ));
        }

        let existant = self.site_optionnel_dans_tx(tx, prestataire).await?;
        let site_id = match &existant {
            Some(site) => {
                sqlx::query!(
                    "UPDATE prestataires.site SET position_lat = $2, position_lng = $3
                     WHERE id = $1",
                    site.id,
                    position_lat,
                    position_lng,
                )
                .execute(&mut **tx)
                .await?;
                site.id
            }
            None => {
                let id = Uuid::now_v7();
                sqlx::query!(
                    "INSERT INTO prestataires.site
                         (id, prestataire_id, position_lat, position_lng, statut_boutique)
                     VALUES ($1, $2, $3, $4, $5::text::prestataires.statut_boutique)",
                    id,
                    prestataire,
                    position_lat,
                    position_lng,
                    statut_initial.unwrap_or(StatutBoutique::Ouvert).comme_str(),
                )
                .execute(&mut **tx)
                .await?;
                id
            }
        };

        let avant = self.horaires_dans_tx(tx, site_id).await?;
        if &avant != horaires {
            self.remplacer_horaires(tx, prestataire, site_id, &avant, horaires, SourceBascule::Admin, acteur)
                .await?;
        }
        self.site_dans_tx(tx, prestataire).await
    }

    /// Remplace les horaires hebdomadaires du site — chemin PARTAGÉ vendeur et
    /// admin (FR-034) : effet immédiat sur l'état effectif, une pause en cours
    /// continue de courir (edge case spec). Émet `site.horaires_modifies`.
    pub async fn modifier_horaires(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        horaires: &HorairesSemaine,
        source: SourceBascule,
        acteur: Uuid,
    ) -> Result<Site, ErreurPrestataires> {
        valider_horaires(horaires)?;
        let site = self.site_dans_tx(tx, prestataire).await?;
        let avant = self.horaires_dans_tx(tx, site.id).await?;
        if &avant != horaires {
            self.remplacer_horaires(tx, prestataire, site.id, &avant, horaires, source, acteur)
                .await?;
        }
        self.site_dans_tx(tx, prestataire).await
    }

    async fn remplacer_horaires(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        site: Uuid,
        avant: &HorairesSemaine,
        apres: &HorairesSemaine,
        source: SourceBascule,
        acteur: Uuid,
    ) -> Result<(), ErreurPrestataires> {
        sqlx::query!("DELETE FROM prestataires.horaire_site WHERE site_id = $1", site)
            .execute(&mut **tx)
            .await?;
        for (jour, plages) in apres.jours.iter().enumerate() {
            for plage in plages {
                sqlx::query!(
                    "INSERT INTO prestataires.horaire_site (site_id, jour, debut, fin)
                     VALUES ($1, $2, $3, $4)",
                    site,
                    jour as i16,
                    plage.debut,
                    plage.fin,
                )
                .execute(&mut **tx)
                .await?;
            }
        }
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "site.horaires_modifies",
                entite_type: "site",
                entite_id: site,
                payload: json!({
                    "prestataire": prestataire,
                    "avant": avant,
                    "apres": apres,
                    "source": source.comme_str(),
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        Ok(())
    }

    // ── Lectures ───────────────────────────────────────────────────────────

    /// LE site du prestataire, dans la transaction (SiteInconnu s'il n'existe
    /// pas encore — l'agrément l'exige, FR-005).
    pub(crate) async fn site_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
    ) -> Result<Site, ErreurPrestataires> {
        self.site_optionnel_dans_tx(tx, prestataire)
            .await?
            .ok_or(ErreurPrestataires::SiteInconnu(prestataire))
    }

    pub(crate) async fn site_optionnel_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
    ) -> Result<Option<Site>, ErreurPrestataires> {
        let ligne = sqlx::query!(
            r#"SELECT id, prestataire_id, position_lat, position_lng,
                      statut_boutique::text AS "statut_boutique!",
                      pause_fin, ferme_journee_le, statut_change_par, statut_change_le
               FROM prestataires.site WHERE prestataire_id = $1"#,
            prestataire,
        )
        .fetch_optional(&mut **tx)
        .await?;
        ligne
            .map(|l| {
                Ok(Site {
                    id: l.id,
                    prestataire_id: l.prestataire_id,
                    position_lat: l.position_lat,
                    position_lng: l.position_lng,
                    statut_boutique: l
                        .statut_boutique
                        .parse()
                        .map_err(ErreurPrestataires::FicheInvalide)?,
                    pause_fin: l.pause_fin,
                    ferme_journee_le: l.ferme_journee_le,
                    statut_change_par: l.statut_change_par,
                    statut_change_le: l.statut_change_le,
                })
            })
            .transpose()
    }

    /// Horaires du site, reconstruits en semaine complète.
    pub(crate) async fn horaires_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        site: Uuid,
    ) -> Result<HorairesSemaine, ErreurPrestataires> {
        let lignes = sqlx::query!(
            "SELECT jour, debut, fin FROM prestataires.horaire_site
             WHERE site_id = $1 ORDER BY jour, debut",
            site,
        )
        .fetch_all(&mut **tx)
        .await?;
        let mut horaires = HorairesSemaine::default();
        for l in lignes {
            horaires.jours[l.jour as usize].push(Plage {
                debut: l.debut,
                fin: l.fin,
            });
        }
        Ok(horaires)
    }

    /// Fuseau de la zone (`zone.fuseau_horaire`, héritage — research R8).
    pub(crate) async fn fuseau_de(&self, zone: Uuid) -> Result<Tz, ErreurPrestataires> {
        use zones::ConfigurationZones;
        let valeur = self.zones.parametre(zone, "zone.fuseau_horaire").await?;
        let nom = valeur
            .as_ref()
            .and_then(|v| v.as_str())
            .ok_or(ErreurPrestataires::ConfigurationZoneInvalide {
                cle: "zone.fuseau_horaire",
                raison: "absent de toute la chaîne d'héritage".to_owned(),
            })?;
        nom.parse()
            .map_err(|_| ErreurPrestataires::ConfigurationZoneInvalide {
                cle: "zone.fuseau_horaire",
                raison: format!("fuseau IANA invalide : {nom}"),
            })
    }
}

// ── Dérivation pure de l'état effectif (FR-032, research R3) ───────────────

/// État effectif d'une boutique à l'instant `maintenant_local` (horloge DANS
/// le fuseau de la zone — l'appelant l'y a convertie).
///
/// Ordre d'évaluation (FR-032) : non agréé → fermé ; hors horaires → fermé
/// quel que soit le statut ; pause avant échéance → fermé ; « fermé pour la
/// journée » le jour couvert → fermé ; fermé manuel → fermé ; sinon ouvert.
/// Une pause ÉCHUE ou une journée PASSÉE cessent de produire effet ICI, à la
/// lecture — la colonne n'est jamais réécrite, aucun événement n'est émis.
pub fn etat_effectif(
    agree: bool,
    statut: StatutBoutique,
    pause_fin: Option<DateTime<Utc>>,
    ferme_journee_le: Option<NaiveDate>,
    horaires: &HorairesSemaine,
    maintenant_local: DateTime<Tz>,
) -> EffectifBoutique {
    if !agree {
        // Ni servi ni commandable : aucune réouverture à annoncer.
        return EffectifBoutique {
            ouvert: false,
            reouverture_estimee: None,
        };
    }

    let maintenant_utc = maintenant_local.with_timezone(&Utc);
    let jour = maintenant_local.weekday().num_days_from_monday() as usize;
    let heure = maintenant_local.time();
    let dans_horaires = horaires.jours[jour]
        .iter()
        .any(|p| p.debut <= heure && heure < p.fin);

    let pause_active =
        statut == StatutBoutique::EnPause && pause_fin.is_some_and(|f| maintenant_utc < f);
    let journee_active = statut == StatutBoutique::FermeJournee
        && ferme_journee_le.is_some_and(|d| maintenant_local.date_naive() <= d);
    let ferme_manuel = statut == StatutBoutique::Ferme;

    let ouvert = dans_horaires && !pause_active && !journee_active && !ferme_manuel;
    if ouvert {
        return EffectifBoutique {
            ouvert: true,
            reouverture_estimee: None,
        };
    }

    // Réouverture estimée (FR-029). Fermeture MANUELLE : seule une action du
    // vendeur rouvrira — aucune heure à promettre.
    let reouverture_estimee = if ferme_manuel {
        None
    } else if journee_active {
        // Premier créneau STRICTEMENT après la journée couverte.
        let lendemain = ferme_journee_le
            .expect("journee_active implique la date")
            .succ_opt();
        lendemain.and_then(|d| {
            prochaine_ouverture(horaires, debut_de_journee(d, maintenant_local.timezone()))
        })
    } else if pause_active {
        // Fin de pause recalée dans les horaires : l'échéance lève la pause
        // mais ne force JAMAIS l'ouverture contre les horaires (FR-033).
        let fin = pause_fin.expect("pause_active implique l'échéance");
        prochaine_ouverture(horaires, fin.with_timezone(&maintenant_local.timezone()))
    } else {
        // Hors horaires (statut ouvert, pause échue, journée passée).
        prochaine_ouverture(horaires, maintenant_local)
    };

    EffectifBoutique {
        ouvert: false,
        reouverture_estimee,
    }
}

/// Premier instant ≥ `depuis` (horloge locale) où une plage est ouverte.
/// `None` si la semaine ne compte AUCUNE plage.
fn prochaine_ouverture(horaires: &HorairesSemaine, depuis: DateTime<Tz>) -> Option<DateTime<Utc>> {
    // 8 jours couvrent tout cycle hebdomadaire, quel que soit le point d'entrée.
    for decalage in 0..8i64 {
        let date = depuis.date_naive() + Duration::days(decalage);
        let jour = date.weekday().num_days_from_monday() as usize;
        for plage in &horaires.jours[jour] {
            let debut_local = date.and_time(plage.debut);
            let Some(debut) = depuis
                .timezone()
                .from_local_datetime(&debut_local)
                .earliest()
            else {
                continue;
            };
            let fin = depuis
                .timezone()
                .from_local_datetime(&date.and_time(plage.fin))
                .earliest();
            if debut >= depuis {
                return Some(debut.with_timezone(&Utc));
            }
            // `depuis` tombe DANS la plage : ouverture immédiate.
            if fin.is_some_and(|f| depuis < f) {
                return Some(depuis.with_timezone(&Utc));
            }
        }
    }
    None
}

/// Minuit local d'une date, robuste aux transitions d'heure.
fn debut_de_journee(date: NaiveDate, tz: Tz) -> DateTime<Tz> {
    tz.from_local_datetime(&date.and_hms_opt(0, 0, 0).expect("minuit"))
        .earliest()
        .expect("minuit représentable")
}

/// Plages triées, non chevauchantes, bornées (FR-031).
fn valider_horaires(horaires: &HorairesSemaine) -> Result<(), ErreurPrestataires> {
    for (jour, plages) in horaires.jours.iter().enumerate() {
        let mut fin_precedente = None;
        for plage in plages {
            if plage.debut >= plage.fin {
                return Err(ErreurPrestataires::HorairesInvalides(format!(
                    "jour {jour} : début ≥ fin"
                )));
            }
            if fin_precedente.is_some_and(|f| plage.debut < f) {
                return Err(ErreurPrestataires::HorairesInvalides(format!(
                    "jour {jour} : plages non triées ou chevauchantes"
                )));
            }
            fin_precedente = Some(plage.fin);
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::NaiveTime;
    use chrono_tz::Africa::Abidjan;

    fn h(heure: u32, minute: u32) -> NaiveTime {
        NaiveTime::from_hms_opt(heure, minute, 0).unwrap()
    }

    /// 8 h — 19 h du lundi au samedi, dimanche fermé (Tantie Affoué).
    fn semaine_type() -> HorairesSemaine {
        let mut horaires = HorairesSemaine::default();
        for jour in 0..6 {
            horaires.jours[jour].push(Plage {
                debut: h(8, 0),
                fin: h(19, 0),
            });
        }
        horaires
    }

    /// Mardi 2026-07-14 à l'heure donnée, Abidjan (GMT+0, sans DST).
    fn mardi(heure: u32, minute: u32) -> DateTime<Tz> {
        Abidjan
            .with_ymd_and_hms(2026, 7, 14, heure, minute, 0)
            .unwrap()
    }

    fn etat(
        statut: StatutBoutique,
        pause_fin: Option<DateTime<Utc>>,
        journee: Option<NaiveDate>,
        quand: DateTime<Tz>,
    ) -> EffectifBoutique {
        etat_effectif(true, statut, pause_fin, journee, &semaine_type(), quand)
    }

    #[test]
    fn ouvert_pendant_les_horaires() {
        assert!(etat(StatutBoutique::Ouvert, None, None, mardi(10, 15)).ouvert);
    }

    /// FR-032 — hors horaires, la boutique est FERMÉE quel que soit le statut.
    #[test]
    fn hors_horaires_ferme_quel_que_soit_le_statut() {
        for statut in [
            StatutBoutique::Ouvert,
            StatutBoutique::Ferme,
            StatutBoutique::EnPause,
            StatutBoutique::FermeJournee,
        ] {
            let e = etat(statut, None, None, mardi(20, 0));
            assert!(!e.ouvert, "{statut} à 20 h doit être fermé");
        }
        // Réouverture : mercredi 8 h.
        let e = etat(StatutBoutique::Ouvert, None, None, mardi(20, 0));
        let attendu = Abidjan
            .with_ymd_and_hms(2026, 7, 15, 8, 0, 0)
            .unwrap()
            .with_timezone(&Utc);
        assert_eq!(e.reouverture_estimee, Some(attendu));
    }

    /// Dimanche : jour SANS plage = jour de fermeture (FR-031).
    #[test]
    fn jour_sans_plage_est_ferme() {
        let dimanche = Abidjan.with_ymd_and_hms(2026, 7, 19, 12, 0, 0).unwrap();
        let e = etat(StatutBoutique::Ouvert, None, None, dimanche);
        assert!(!e.ouvert);
        // Réouverture : lundi 8 h.
        let lundi_8h = Abidjan
            .with_ymd_and_hms(2026, 7, 20, 8, 0, 0)
            .unwrap()
            .with_timezone(&Utc);
        assert_eq!(e.reouverture_estimee, Some(lundi_8h));
    }

    /// FR-033 — pause : fermé jusqu'à l'échéance, rouvre TOUT SEUL ensuite.
    #[test]
    fn pause_ferme_puis_rouvre_a_l_echeance_sans_ecriture() {
        let echeance = mardi(11, 0).with_timezone(&Utc);
        let avant = etat(StatutBoutique::EnPause, Some(echeance), None, mardi(10, 30));
        assert!(!avant.ouvert);
        assert_eq!(
            avant.reouverture_estimee,
            Some(echeance),
            "l'échéance tombe dans les horaires : réouverture à l'échéance"
        );

        // MÊMES colonnes (aucune écriture) — après l'échéance : ouvert.
        let apres = etat(StatutBoutique::EnPause, Some(echeance), None, mardi(11, 5));
        assert!(apres.ouvert, "pause échue absorbée à la lecture");
    }

    /// Edge case spec — l'échéance hors horaires NE force PAS l'ouverture.
    #[test]
    fn pause_echue_hors_horaires_ne_rouvre_pas() {
        let echeance = mardi(19, 30).with_timezone(&Utc); // après la fermeture
        let e = etat(StatutBoutique::EnPause, Some(echeance), None, mardi(18, 50));
        assert!(!e.ouvert);
        // Réouverture recalée : mercredi 8 h, pas 19 h 30.
        let mercredi_8h = Abidjan
            .with_ymd_and_hms(2026, 7, 15, 8, 0, 0)
            .unwrap()
            .with_timezone(&Utc);
        assert_eq!(e.reouverture_estimee, Some(mercredi_8h));

        let a_20h = etat(StatutBoutique::EnPause, Some(echeance), None, mardi(20, 0));
        assert!(!a_20h.ouvert, "pause échue mais hors horaires : fermé");
    }

    /// FR-030 — « fermé pour la journée » cesse au prochain jour d'ouverture.
    #[test]
    fn ferme_pour_la_journee_cesse_le_lendemain() {
        let aujourd_hui = mardi(14, 0).date_naive();
        let pendant = etat(
            StatutBoutique::FermeJournee,
            None,
            Some(aujourd_hui),
            mardi(14, 0),
        );
        assert!(!pendant.ouvert);
        let mercredi_8h = Abidjan
            .with_ymd_and_hms(2026, 7, 15, 8, 0, 0)
            .unwrap()
            .with_timezone(&Utc);
        assert_eq!(pendant.reouverture_estimee, Some(mercredi_8h));

        // Lendemain 10 h, MÊMES colonnes : la journée couverte est passée.
        let lendemain = Abidjan.with_ymd_and_hms(2026, 7, 15, 10, 0, 0).unwrap();
        let e = etat_effectif(
            true,
            StatutBoutique::FermeJournee,
            None,
            Some(aujourd_hui),
            &semaine_type(),
            lendemain,
        );
        assert!(e.ouvert, "sans que le vendeur ait à revenir rouvrir");
    }

    /// Fermeture MANUELLE : pas de réouverture à promettre (action requise).
    #[test]
    fn ferme_manuel_sans_reouverture_estimee() {
        let e = etat(StatutBoutique::Ferme, None, None, mardi(10, 0));
        assert!(!e.ouvert);
        assert_eq!(e.reouverture_estimee, None);
    }

    /// FR-004/FR-028 — non agréé : fermé, point.
    #[test]
    fn non_agree_toujours_ferme() {
        let e = etat_effectif(
            false,
            StatutBoutique::Ouvert,
            None,
            None,
            &semaine_type(),
            mardi(10, 0),
        );
        assert!(!e.ouvert);
        assert_eq!(e.reouverture_estimee, None);
    }

    /// Semaine sans AUCUNE plage : fermé, aucune réouverture calculable.
    #[test]
    fn aucune_plage_aucune_reouverture() {
        let e = etat_effectif(
            true,
            StatutBoutique::Ouvert,
            None,
            None,
            &HorairesSemaine::default(),
            mardi(10, 0),
        );
        assert!(!e.ouvert);
        assert_eq!(e.reouverture_estimee, None);
    }

    #[test]
    fn validation_des_horaires() {
        let mut inverse = HorairesSemaine::default();
        inverse.jours[0].push(Plage {
            debut: h(19, 0),
            fin: h(8, 0),
        });
        assert!(valider_horaires(&inverse).is_err(), "début ≥ fin refusé");

        let mut chevauche = HorairesSemaine::default();
        chevauche.jours[0].push(Plage {
            debut: h(8, 0),
            fin: h(12, 0),
        });
        chevauche.jours[0].push(Plage {
            debut: h(11, 0),
            fin: h(15, 0),
        });
        assert!(valider_horaires(&chevauche).is_err(), "chevauchement refusé");

        let mut deux_plages = HorairesSemaine::default();
        deux_plages.jours[0].push(Plage {
            debut: h(8, 0),
            fin: h(12, 0),
        });
        deux_plages.jours[0].push(Plage {
            debut: h(15, 0),
            fin: h(19, 0),
        });
        assert!(
            valider_horaires(&deux_plages).is_ok(),
            "plusieurs plages par jour admises (FR-031)"
        );
    }

    /// Coupure de midi : fermé entre deux plages, réouverture à la 2e plage.
    #[test]
    fn entre_deux_plages_reouvre_a_la_suivante() {
        let mut horaires = HorairesSemaine::default();
        horaires.jours[1].push(Plage {
            debut: h(8, 0),
            fin: h(12, 0),
        });
        horaires.jours[1].push(Plage {
            debut: h(15, 0),
            fin: h(19, 0),
        });
        let e = etat_effectif(
            true,
            StatutBoutique::Ouvert,
            None,
            None,
            &horaires,
            mardi(13, 0),
        );
        assert!(!e.ouvert);
        let quinze_heures = mardi(15, 0).with_timezone(&Utc);
        assert_eq!(e.reouverture_estimee, Some(quinze_heures));
    }
}
