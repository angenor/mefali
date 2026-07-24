//! Règles tarifaires : garde des **bornes de marge** (FR-009) et **sélection de
//! la règle la plus spécifique en vigueur** (FR-010, research R5).
//!
//! Tout est **pur** ici : les bornes, la devise et le fuseau sont résolus par
//! `PgTarification` (configuration de zone héritée, constitution I) et passés en
//! argument. C'est ce qui rend la sélection testable sans base et, surtout,
//! **rejouable** : deux évaluations des mêmes entrées rendent la même règle.

use chrono::{DateTime, Datelike, Timelike, Utc};
use chrono_tz::Tz;

use crate::depot::BornesMarge;
use crate::modele::{ErreurTarif, Regle};

/// Refuse une marge hors des bornes de la zone (FR-009).
///
/// Appelée à l'ÉCRITURE d'une règle (rien d'hors bornes n'entre en base) ET
/// avant publication (une borne resserrée après coup doit bloquer la
/// publication, pas passer inaperçue — FR-021).
pub fn verifier_marge(bornes: BornesMarge, marge: i64) -> Result<(), ErreurTarif> {
    if bornes.contient(marge) {
        Ok(())
    } else {
        Err(ErreurTarif::MargeHorsBornes {
            min: bornes.min,
            max: bornes.max,
            valeur: marge,
        })
    }
}

/// Refuse une devise différente de celle de la zone (FR-023/FR-025).
///
/// **Jamais de conversion** : une règle en devise étrangère est rejetée, pas
/// convertie — le MVP n'a aucune logique de change (provision).
pub fn verifier_devise(devise_zone: &str, devise_regle: &str) -> Result<(), ErreurTarif> {
    if devise_zone == devise_regle {
        Ok(())
    } else {
        Err(ErreurTarif::DeviseIncoherente {
            attendue: devise_zone.to_owned(),
            fournie: devise_regle.to_owned(),
        })
    }
}

/// Critères d'appariement d'une course à une règle, à l'instant considéré.
#[derive(Debug, Clone, PartialEq)]
pub struct Criteres<'a> {
    /// Véhicule demandé.
    pub transport_slug: &'a str,
    /// Catégorie de la commande, `None` = aucune contrainte de catégorie.
    pub categorie_slug: Option<&'a str>,
    /// Distance ROUTIÈRE totale de l'itinéraire (mètres) — connue AVANT la
    /// sélection : c'est l'ordre optimisé qui donne les km (research R5).
    pub distance_m: i64,
    /// Instant d'évaluation (UTC).
    pub instant: DateTime<Utc>,
    /// Fuseau de la zone — les plages horaires et jours s'y interprètent.
    pub fuseau: Tz,
}

/// La règle s'applique-t-elle à ces critères ?
fn correspond(regle: &Regle, criteres: &Criteres<'_>) -> bool {
    if !regle.actif || regle.transport_slug != criteres.transport_slug {
        return false;
    }
    // Catégorie : une règle sans catégorie vaut pour toutes ; une règle
    // catégorisée exige la MÊME catégorie (une commande sans catégorie ne peut
    // donc pas capter une règle catégorisée).
    if let Some(categorie_regle) = regle.categorie_slug.as_deref() {
        if criteres.categorie_slug != Some(categorie_regle) {
            return false;
        }
    }
    // Tranche de distance — borne haute INCLUSIVE : le seed dit « à pied 100
    // (≤ 800 m) » (FR-026), donc 800 m est encore à pied. Deux tranches
    // adjacentes se chevauchent d'un mètre ; le départage déterministe
    // ci-dessous tranche, aucun prix n'est jamais ambigu.
    if criteres.distance_m < i64::from(regle.distance_min_m) {
        return false;
    }
    if let Some(max) = regle.distance_max_m {
        if criteres.distance_m > i64::from(max) {
            return false;
        }
    }

    let local = criteres.instant.with_timezone(&criteres.fuseau);
    // Jours : bit 0 = lundi … bit 6 = dimanche.
    if let Some(masque) = regle.jours_masque {
        let jour = local.weekday().num_days_from_monday();
        if masque & (1i16 << jour) == 0 {
            return false;
        }
    }
    // Plage horaire — bornes en minutes depuis minuit LOCAL, début inclus, fin
    // exclue. Une plage qui ENJAMBE minuit (22:00–02:00 → début 1320 > fin 120)
    // est lue comme telle : sans ce cas, un supplément de nuit serait
    // silencieusement inapplicable.
    if let (Some(debut), Some(fin)) = (regle.plage_debut_min, regle.plage_fin_min) {
        let minute = (local.hour() * 60 + local.minute()) as i16;
        let dans_la_plage = if debut <= fin {
            minute >= debut && minute < fin
        } else {
            minute >= debut || minute < fin
        };
        if !dans_la_plage {
            return false;
        }
    }
    true
}

/// Score de spécificité : plus une règle est CONTRAINTE, plus elle est
/// spécifique (research R5). Les poids sont hiérarchiques (8/4/2/1) pour qu'une
/// contrainte de catégorie l'emporte sur toute combinaison des autres.
fn specificite(regle: &Regle) -> u32 {
    u32::from(regle.categorie_slug.is_some()) * 8
        + u32::from(regle.plage_debut_min.is_some() && regle.plage_fin_min.is_some()) * 4
        + u32::from(regle.jours_masque.is_some()) * 2
        + u32::from(regle.distance_max_m.is_some())
}

/// Largeur de la tranche de distance — à spécificité égale, la tranche la plus
/// ÉTROITE est la plus spécifique. Une tranche ouverte vaut l'infini.
fn largeur_tranche(regle: &Regle) -> i64 {
    match regle.distance_max_m {
        Some(max) => i64::from(max) - i64::from(regle.distance_min_m),
        None => i64::MAX,
    }
}

/// Sélectionne la règle applicable — **déterministe et rejouable** (FR-010).
///
/// Ordre de décision, dans cet ordre exact (research R5, tâche T011) :
///
/// 1. **spécificité** décroissante (catégorie > plage > jours > tranche bornée) ;
/// 2. **largeur de tranche** croissante (la plus étroite gagne) ;
/// 3. **priorité** décroissante — le départage VOLONTAIRE de l'admin ;
/// 4. **identifiant** croissant — départage final, jamais une égalité non résolue.
///
/// La priorité vient APRÈS la spécificité : elle tranche entre règles de même
/// forme, elle ne permet pas à une règle générale de capter une course qu'une
/// règle plus précise décrit mieux.
///
/// `None` quand aucune règle ne correspond : l'appelant rend
/// [`ErreurTarif::AucuneRegle`] — jamais un prix arbitraire (edge case FR-010).
pub fn selectionner<'a>(regles: &'a [Regle], criteres: &Criteres<'_>) -> Option<&'a Regle> {
    regles
        .iter()
        .filter(|r| correspond(r, criteres))
        .min_by(|a, b| {
            specificite(b)
                .cmp(&specificite(a))
                .then_with(|| largeur_tranche(a).cmp(&largeur_tranche(b)))
                .then_with(|| b.priorite.cmp(&a.priorite))
                .then_with(|| a.id.cmp(&b.id))
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    fn regle_base(id: Uuid) -> Regle {
        Regle {
            id,
            grille_id: Uuid::nil(),
            transport_slug: "moto".to_owned(),
            categorie_slug: None,
            distance_min_m: 0,
            distance_max_m: None,
            plage_debut_min: None,
            plage_fin_min: None,
            jours_masque: None,
            point_relais_id: None,
            part_coursier_base: 150,
            marge: 50,
            prix_par_km: 50,
            seuil_km_m: 2000,
            prix_plafond: Some(500),
            devise: "XOF".to_owned(),
            priorite: 0,
            actif: true,
        }
    }

    /// Mercredi 2026-07-22, 19 h 30 UTC (= 19 h 30 à Abidjan, UTC+0).
    fn criteres(distance_m: i64) -> Criteres<'static> {
        Criteres {
            transport_slug: "moto",
            categorie_slug: Some("restauration"),
            distance_m,
            instant: "2026-07-22T19:30:00Z".parse().unwrap(),
            fuseau: chrono_tz::Africa::Abidjan,
        }
    }

    #[test]
    fn bornes_de_marge_gardees() {
        let bornes = BornesMarge { min: 25, max: 100 };
        assert!(verifier_marge(bornes, 25).is_ok(), "borne basse incluse");
        assert!(verifier_marge(bornes, 100).is_ok(), "borne haute incluse");
        let err = verifier_marge(bornes, 110).unwrap_err();
        assert_eq!(err.message_cle(), Some("marge_hors_bornes"));
        // La marge 0 du LANCEMENT ne vient jamais d'une règle (research R4) :
        // elle est produite par le drapeau `gratuite_commissions`.
        assert!(verifier_marge(bornes, 0).is_err(), "marge 0 refusée en règle");
    }

    #[test]
    fn devise_gardee_sans_conversion() {
        assert!(verifier_devise("XOF", "XOF").is_ok());
        let err = verifier_devise("XOF", "EUR").unwrap_err();
        assert_eq!(err.message_cle(), Some("devise_incoherente"));
    }

    /// La plus spécifique gagne, quelle que soit la priorité de la générale.
    #[test]
    fn specificite_avant_priorite() {
        let generale = {
            let mut r = regle_base(Uuid::now_v7());
            r.priorite = 100; // priorité forte…
            r
        };
        let categorisee = {
            let mut r = regle_base(Uuid::now_v7());
            r.categorie_slug = Some("restauration".to_owned());
            r.priorite = 0; // …mais moins spécifique
            r
        };
        let jeu = [generale, categorisee.clone()];
        let choisie = selectionner(&jeu, &criteres(3000)).expect("une règle applicable");
        assert_eq!(choisie.id, categorisee.id);
    }

    /// À spécificité égale, la priorité tranche ; à priorité égale, l'id.
    #[test]
    fn priorite_puis_id_departagent() {
        let (mut faible, mut forte) = (regle_base(Uuid::now_v7()), regle_base(Uuid::now_v7()));
        faible.priorite = 1;
        forte.priorite = 9;
        let jeu = [faible, forte.clone()];
        let choisie = selectionner(&jeu, &criteres(3000)).unwrap();
        assert_eq!(choisie.id, forte.id, "priorité supérieure retenue");

        // Égalité stricte : deux règles identiques hors id → la plus PETITE.
        let petite = regle_base("01900000-0000-7000-8000-000000000001".parse().unwrap());
        let grande = regle_base("01900000-0000-7000-8000-000000000002".parse().unwrap());
        let jeu = vec![grande.clone(), petite.clone()];
        let choisie = selectionner(&jeu, &criteres(3000)).unwrap();
        assert_eq!(choisie.id, petite.id, "départage déterministe par id");
        // Rejouable : l'ordre de lecture ne change rien.
        let inverse = vec![petite.clone(), grande];
        assert_eq!(selectionner(&inverse, &criteres(3000)).unwrap().id, petite.id);
    }

    /// À spécificité de forme égale, la tranche la plus étroite l'emporte.
    #[test]
    fn tranche_etroite_plus_specifique() {
        let mut large = regle_base(Uuid::now_v7());
        large.distance_max_m = Some(20_000);
        let mut etroite = regle_base(Uuid::now_v7());
        etroite.distance_max_m = Some(4_000);
        let jeu = [large, etroite.clone()];
        let choisie = selectionner(&jeu, &criteres(3000)).unwrap();
        assert_eq!(choisie.id, etroite.id);
    }

    #[test]
    fn filtres_vehicule_categorie_distance_actif() {
        let mut velo = regle_base(Uuid::now_v7());
        velo.transport_slug = "velo".to_owned();
        assert!(selectionner(&[velo], &criteres(1000)).is_none(), "véhicule");

        let mut autre_categorie = regle_base(Uuid::now_v7());
        autre_categorie.categorie_slug = Some("pharmacie".to_owned());
        assert!(
            selectionner(&[autre_categorie], &criteres(1000)).is_none(),
            "catégorie"
        );

        let mut bornee = regle_base(Uuid::now_v7());
        bornee.distance_max_m = Some(800);
        assert!(selectionner(&[bornee.clone()], &criteres(800)).is_some(), "≤ inclusif");
        assert!(selectionner(&[bornee], &criteres(801)).is_none(), "hors tranche");

        let mut inactive = regle_base(Uuid::now_v7());
        inactive.actif = false;
        assert!(selectionner(&[inactive], &criteres(1000)).is_none(), "inactive");
    }

    /// Plages horaires : cas simple, cas qui ENJAMBE minuit, et jours.
    #[test]
    fn plage_horaire_et_jours() {
        // 19 h 30 local. Plage 18:00–22:00 → dedans.
        let mut soir = regle_base(Uuid::now_v7());
        soir.plage_debut_min = Some(18 * 60);
        soir.plage_fin_min = Some(22 * 60);
        assert!(selectionner(&[soir], &criteres(1000)).is_some());

        // Plage 06:00–12:00 → dehors.
        let mut matin = regle_base(Uuid::now_v7());
        matin.plage_debut_min = Some(6 * 60);
        matin.plage_fin_min = Some(12 * 60);
        assert!(selectionner(&[matin], &criteres(1000)).is_none());

        // Nuit 22:00–02:00 (enjambe minuit) → 19 h 30 dehors, 23 h 00 dedans.
        let mut nuit = regle_base(Uuid::now_v7());
        nuit.plage_debut_min = Some(22 * 60);
        nuit.plage_fin_min = Some(2 * 60);
        assert!(selectionner(&[nuit.clone()], &criteres(1000)).is_none());
        let mut tard = criteres(1000);
        tard.instant = "2026-07-22T23:00:00Z".parse().unwrap();
        assert!(selectionner(&[nuit], &tard).is_some(), "plage de nuit");

        // Mercredi = bit 2. Un masque « lundi seulement » (bit 0) ne matche pas.
        let mut lundi = regle_base(Uuid::now_v7());
        lundi.jours_masque = Some(0b000_0001);
        assert!(selectionner(&[lundi], &criteres(1000)).is_none());
        let mut mercredi = regle_base(Uuid::now_v7());
        mercredi.jours_masque = Some(0b000_0100);
        assert!(selectionner(&[mercredi], &criteres(1000)).is_some());
    }

    /// Le fuseau de la ZONE fait foi, pas celui du serveur : à 23 h 30 UTC, il
    /// est 00 h 30 le lendemain à Abidjan+1 — un supplément de nuit local doit
    /// s'appliquer sur l'heure LOCALE.
    #[test]
    fn plage_lue_dans_le_fuseau_de_la_zone() {
        let mut apres_minuit = regle_base(Uuid::now_v7());
        apres_minuit.plage_debut_min = Some(0);
        apres_minuit.plage_fin_min = Some(2 * 60);

        let mut a_abidjan = criteres(1000);
        a_abidjan.instant = "2026-07-22T23:30:00Z".parse().unwrap();
        assert!(
            selectionner(&[apres_minuit.clone()], &a_abidjan).is_none(),
            "23 h 30 à Abidjan (UTC+0) n'est pas dans 00:00–02:00"
        );

        let mut a_lagos = a_abidjan.clone();
        a_lagos.fuseau = chrono_tz::Africa::Lagos; // UTC+1 → 00 h 30 local
        assert!(
            selectionner(&[apres_minuit], &a_lagos).is_some(),
            "00 h 30 heure locale EST dans la plage"
        );
    }

    #[test]
    fn aucune_regle_applicable() {
        assert!(selectionner(&[], &criteres(1000)).is_none());
    }
}
