//! Grille d'effort : paliers d'articles, prime d'attente (une fois par course),
//! supplément d'arrêt sur tronçon routier (US6 — T029, FR-028/FR-029).
//!
//! Les trois composantes sont **100 % reversées à la part coursier** : la marge
//! Mefali est strictement inchangée par l'effort (SC-007). C'est ce qui rend le
//! travail réel du coursier — porter 20 articles, patienter chez un vendeur
//! lent, enchaîner trois étals — payé plutôt que subi.
//!
//! Tous les barèmes vivent en **configuration de zone** (`effort.*`, seed
//! `50_tarification_tiassale.sql`) : un barème absent vaut simplement 0, jamais
//! une valeur devinée.

use serde_json::Value;

use crate::modele::{Attente, Troncon};

/// Tranche d'un barème : `[min, max, montant]`, `max` absent = +∞.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Palier {
    /// Borne basse, toujours incluse.
    pub min: i64,
    /// Borne haute (`None` = +∞).
    pub max: Option<i64>,
    /// Montant en unités mineures.
    pub montant: i64,
}

impl Palier {
    /// Le palier couvre-t-il ce COMPTE (nombre d'articles) ?
    ///
    /// Borne haute **incluse** : un barème « 6–10 → +50 » doit payer 10 articles.
    /// Les comptes sont discrets, leurs tranches se lisent bornes comprises.
    pub fn couvre_compte(&self, valeur: i64) -> bool {
        valeur >= self.min && self.max.is_none_or(|max| valeur <= max)
    }

    /// Le palier couvre-t-il cette DISTANCE (mètres) ?
    ///
    /// Borne haute **exclue** : les distances sont continues, et le barème
    /// produit du cadrage se lit « < 100 m → +25 ; 100 m–1 km → +50 ; > 1 km →
    /// +100 ». Des bornes hautes incluses feraient se chevaucher `[0, 100]` et
    /// `[100, 1000]` — 100 m tomberait dans les deux, et le prix dépendrait de
    /// l'ordre de lecture du barème.
    pub fn couvre_distance(&self, valeur: i64) -> bool {
        valeur >= self.min && self.max.is_none_or(|max| valeur < max)
    }
}

/// Prime d'attente — **une seule fois par course** (clarification 2026-07-24).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PrimeAttente {
    /// Minutes d'attente au-delà desquelles la prime est due.
    pub seuil_min: i64,
    /// Montant de la prime (unités mineures).
    pub montant: i64,
}

/// Barèmes d'effort d'une zone, résolus par héritage.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct ParametresEffort {
    /// Paliers d'articles (`effort.paliers_articles`).
    pub paliers_articles: Vec<Palier>,
    /// Prime d'attente (`effort.prime_attente`), `None` = aucune.
    pub prime_attente: Option<PrimeAttente>,
    /// Barème du supplément par arrêt (`effort.supplement_arret_m`).
    pub supplement_arret_m: Vec<Palier>,
    /// Plafond du TOTAL des suppléments d'arrêt (`effort.plafond_supplements_arret`),
    /// `None` = aucun plafond.
    pub plafond_supplements_arret: Option<i64>,
}

impl ParametresEffort {
    /// Lit les barèmes depuis la configuration de zone résolue.
    ///
    /// Toute valeur illisible est traitée comme ABSENTE (barème vide, prime
    /// nulle) : une faute de frappe dans la configuration doit coûter un effort
    /// non payé — visible et corrigeable — jamais un prix aberrant.
    pub fn depuis_config(lire: impl Fn(&str) -> Option<Value>) -> Self {
        Self {
            paliers_articles: lire("effort.paliers_articles")
                .as_ref()
                .map(paliers_depuis_json)
                .unwrap_or_default(),
            prime_attente: lire("effort.prime_attente")
                .as_ref()
                .and_then(prime_depuis_json),
            supplement_arret_m: lire("effort.supplement_arret_m")
                .as_ref()
                .map(paliers_depuis_json)
                .unwrap_or_default(),
            plafond_supplements_arret: lire("effort.plafond_supplements_arret")
                .as_ref()
                .and_then(Value::as_i64),
        }
    }
}

/// `[[min, max|null, montant], ...]` → paliers. Les tranches mal formées sont
/// ignorées une à une, sans faire échouer tout le barème.
fn paliers_depuis_json(valeur: &Value) -> Vec<Palier> {
    valeur
        .as_array()
        .map(|tranches| {
            tranches
                .iter()
                .filter_map(|t| {
                    let t = t.as_array()?;
                    Some(Palier {
                        min: t.first()?.as_i64()?,
                        max: t.get(1).and_then(Value::as_i64),
                        montant: t.get(2)?.as_i64()?,
                    })
                })
                .collect()
        })
        .unwrap_or_default()
}

/// `{"seuil_min": 15, "montant": 100, "par": "course"}` → prime.
fn prime_depuis_json(valeur: &Value) -> Option<PrimeAttente> {
    // `par` n'a qu'une valeur implémentée : « course » (clarification du
    // 2026-07-24). Toute autre valeur est journalisée et traitée comme
    // « course » — mieux vaut une prime prévisible qu'un comportement inventé.
    match valeur.get("par").and_then(Value::as_str) {
        Some("course") | None => {}
        Some(autre) => tracing::warn!(
            par = autre,
            "prime d'attente : seul « course » est implémenté — appliquée par course",
        ),
    }
    Some(PrimeAttente {
        seuil_min: valeur.get("seuil_min")?.as_i64()?,
        montant: valeur.get("montant")?.as_i64()?,
    })
}

/// Détail de la grille d'effort, en unités mineures. **Intégralement** part
/// coursier.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Effort {
    /// Palier d'articles de la commande (FR-028, composante 1).
    pub paliers: i64,
    /// Prime d'attente — **une seule fois par course** (FR-028, composante 2 ;
    /// clarification du 2026-07-24).
    pub attente: i64,
    /// Suppléments d'arrêt, indexés sur le tronçon routier au précédent
    /// (FR-028/FR-029, composante 3).
    pub arrets: i64,
}

impl Effort {
    /// Total des trois composantes.
    pub fn total(&self) -> i64 {
        self.paliers + self.attente + self.arrets
    }
}

/// Calcule l'effort d'une course.
///
/// `troncons_entre_arrets` = les jambes reliant deux retraits consécutifs de
/// l'itinéraire optimisé, **sans** la jambe de livraison finale : un « arrêt
/// supplémentaire » est un retrait de plus, pas la remise au client. Une course
/// à un seul retrait n'a donc aucun supplément d'arrêt.
pub fn calculer(
    params: &ParametresEffort,
    nb_articles: i32,
    attentes: &[Attente],
    troncons_entre_arrets: &[Troncon],
) -> Effort {
    let paliers = params
        .paliers_articles
        .iter()
        .find(|p| p.couvre_compte(i64::from(nb_articles)))
        .map_or(0, |p| p.montant);

    // UNE seule fois par course, même si trois arrêts ont fait attendre : la
    // prime récompense le fait d'avoir patienté, pas le nombre de vendeurs
    // lents (clarification). Requiert les DEUX horodatages — la structure
    // `Attente` les impose, donc une attente non tracée n'entre jamais ici.
    let attente = params
        .prime_attente
        .filter(|prime| attentes.iter().any(|a| a.minutes() > prime.seuil_min))
        .map_or(0, |prime| prime.montant);

    let arrets_bruts: i64 = troncons_entre_arrets
        .iter()
        .map(|t| {
            params
                .supplement_arret_m
                .iter()
                .find(|p| p.couvre_distance(t.distance_m))
                .map_or(0, |p| p.montant)
        })
        .sum();
    let arrets = match params.plafond_supplements_arret {
        Some(plafond) => arrets_bruts.min(plafond),
        None => arrets_bruts,
    };

    Effort {
        paliers,
        attente,
        arrets,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::{DateTime, TimeZone, Utc};
    use serde_json::json;

    /// Barèmes du seed Tiassalé.
    fn params() -> ParametresEffort {
        let config = |cle: &str| match cle {
            "effort.paliers_articles" => Some(json!([[6, 10, 50], [11, 20, 100], [21, null, 150]])),
            "effort.prime_attente" => {
                Some(json!({"seuil_min": 15, "montant": 100, "par": "course"}))
            }
            "effort.supplement_arret_m" => {
                Some(json!([[0, 100, 25], [100, 1000, 50], [1000, null, 100]]))
            }
            _ => None,
        };
        ParametresEffort::depuis_config(config)
    }

    fn troncon(distance_m: i64) -> Troncon {
        Troncon {
            distance_m,
            duree_s: distance_m / 5,
        }
    }

    fn heure(h: u32, m: u32) -> DateTime<Utc> {
        Utc.with_ymd_and_hms(2026, 7, 22, h, m, 0).unwrap()
    }

    /// Attente de `minutes` à partir de 12 h — construite par ADDITION, pas en
    /// posant la minute (`heure(12, 60)` n'existe pas).
    fn attente(minutes: i64) -> Attente {
        let arrivee = heure(12, 0);
        Attente {
            arrivee,
            scan: arrivee + chrono::Duration::minutes(minutes),
        }
    }

    #[test]
    fn paliers_articles_bornes_incluses() {
        let p = params();
        for (articles, attendu) in [
            (1, 0),
            (5, 0),
            (6, 50),
            (10, 50),
            (11, 100),
            (20, 100),
            (21, 150),
            (99, 150),
        ] {
            let effort = calculer(&p, articles, &[], &[]);
            assert_eq!(
                effort.paliers, attendu,
                "{articles} articles → {attendu} attendu"
            );
        }
    }

    /// La borne haute d'un palier d'articles est INCLUSE : « 6–10 » paie 10.
    #[test]
    fn dix_articles_sont_dans_le_palier_six_dix() {
        assert_eq!(calculer(&params(), 10, &[], &[]).paliers, 50);
    }

    /// Clarification 2026-07-24 — la prime tombe UNE fois par course, quel que
    /// soit le nombre d'arrêts lents.
    #[test]
    fn prime_attente_une_seule_fois_par_course() {
        let p = params();
        assert_eq!(
            calculer(&p, 1, &[], &[]).attente,
            0,
            "aucune attente tracée"
        );
        assert_eq!(
            calculer(&p, 1, &[attente(15)], &[]).attente,
            0,
            "15 min pile : pas encore"
        );
        assert_eq!(calculer(&p, 1, &[attente(16)], &[]).attente, 100);
        assert_eq!(
            calculer(&p, 1, &[attente(20), attente(30)], &[]).attente,
            100,
            "DEUX arrêts lents → +100, surtout pas 2 × 100"
        );
        assert_eq!(
            calculer(&p, 1, &[attente(5), attente(40), attente(2)], &[]).attente,
            100,
            "un seul arrêt lent suffit"
        );
    }

    /// Une horloge cliente incohérente (scan avant arrivée) ne crédite rien.
    #[test]
    fn attente_negative_ne_credite_rien() {
        let inversee = Attente {
            arrivee: heure(12, 30),
            scan: heure(12, 0),
        };
        assert_eq!(calculer(&params(), 1, &[inversee], &[]).attente, 0);
    }

    /// SC-008 — marché : 12 articles chez 3 étals voisins = 2 × 25 + 100.
    #[test]
    fn marche_trois_etals_voisins() {
        // 3 retraits ⇒ 2 jambes ENTRE arrêts (la 3ᵉ, vers le client, n'est pas
        // un arrêt supplémentaire).
        let effort = calculer(&params(), 12, &[], &[troncon(40), troncon(80)]);
        assert_eq!(effort.arrets, 50, "2 × 25 (voisins de moins de 100 m)");
        assert_eq!(effort.paliers, 100, "palier 11–20");
        assert_eq!(effort.attente, 0);
        assert_eq!(effort.total(), 150);
    }

    /// Le barème d'arrêt classe sur le TRONÇON ROUTIER, bornes hautes exclues.
    #[test]
    fn supplement_arret_par_tranche() {
        let p = params();
        for (distance, attendu) in [
            (0, 25),
            (99, 25),
            (100, 50),
            (999, 50),
            (1_000, 100),
            (5_000, 100),
        ] {
            let effort = calculer(&p, 1, &[], &[troncon(distance)]);
            assert_eq!(effort.arrets, attendu, "{distance} m → {attendu} attendu");
        }
    }

    #[test]
    fn retrait_unique_aucun_supplement_d_arret() {
        assert_eq!(calculer(&params(), 3, &[], &[]).arrets, 0);
    }

    /// Le plafond de zone borne le TOTAL des suppléments d'arrêt.
    #[test]
    fn plafond_des_supplements_d_arret() {
        let mut p = params();
        let jambes = [troncon(2_000), troncon(2_000), troncon(2_000)]; // 3 × 100
        assert_eq!(calculer(&p, 1, &[], &jambes).arrets, 300);
        p.plafond_supplements_arret = Some(150);
        assert_eq!(calculer(&p, 1, &[], &jambes).arrets, 150);
    }

    /// Barèmes ABSENTS de la zone → effort nul, jamais une valeur devinée.
    #[test]
    fn sans_bareme_aucun_effort() {
        let vide = ParametresEffort::depuis_config(|_| None);
        let effort = calculer(&vide, 50, &[attente(60)], &[troncon(5_000)]);
        assert_eq!(effort, Effort::default());
        assert_eq!(effort.total(), 0);
    }

    /// Une configuration mal formée est ignorée tranche par tranche — elle ne
    /// fait pas échouer tout le barème.
    #[test]
    fn config_mal_formee_ignoree_tranche_par_tranche() {
        let params = ParametresEffort::depuis_config(|cle| match cle {
            "effort.paliers_articles" => Some(json!([[1, 5, "beaucoup"], [6, null, 50]])),
            "effort.prime_attente" => Some(json!({"montant": 100})), // seuil absent
            _ => None,
        });
        assert_eq!(
            params.paliers_articles.len(),
            1,
            "la tranche fautive sautée"
        );
        assert_eq!(calculer(&params, 8, &[], &[]).paliers, 50);
        assert!(params.prime_attente.is_none(), "prime incomplète = absente");
    }
}
