//! Pipeline d'évaluation — étapes 1 à 9 du data-model §3 (US2 — T018/T019).
//!
//! Un **seul** cœur de calcul sert la production ET le simulateur admin
//! (research R11) : ce qui est simulé est exactement ce qui sera facturé. Seule
//! la [`SourceGrille`] change — grille en vigueur, ou brouillon en dry run.
//!
//! Ordre EXACT (data-model §3), qui n'est pas une commodité mais le sens même
//! du prix :
//!
//! 1. optimisation de l'ordre des arrêts (distance routière minimale) ;
//! 2. sélection de la règle la plus spécifique en vigueur ;
//! 3. composante déplacement (base + km au-delà du seuil, plafonnée) ;
//! 4. suppléments activés (pluie…) ;
//! 5. grille d'effort — **100 % part coursier** (greffée en US6, T030) ;
//! 6. arrondi du prix client, **reliquat à la part coursier** ;
//! 7. drapeaux de zone (gratuité des commissions, livraison offerte Mefali) ;
//! 8. VND-08 (mono-vendeur seulement) ;
//! 9. figeage du devis.
//!
//! Les étapes 7 et 8 **ne touchent jamais la part coursier** : le coursier est
//! payé pour son travail, qu'une promo Mefali ou un vendeur prenne ou non la
//! livraison à sa charge (§7.5 « le coursier ne perd jamais »).

use async_trait::async_trait;
use chrono::Utc;
use serde_json::json;
use uuid::Uuid;

use socle::{ecrire_evenement, NouvelEvenement};

use crate::depot::Knobs;
use crate::modele::{
    Composantes, DemandeDevis, Devis, ErreurTarif, Evaluation, Grille, Itineraire, Matrice, Point,
    RegleRetenue, SourceGrille,
};
use crate::optimisation;
use crate::ports::{EvaluationTarifaire, OptimisationArrets};
use crate::regle::{self, Criteres};
use crate::routage::matrice_ou_degrade;
use crate::PgTarification;

/// Mètres dans un kilomètre — le barème `prix_par_km` s'exprime au km, les
/// distances routières au mètre.
const METRES_PAR_KM: i64 = 1_000;

/// Arrondit `montant` au multiple SUPÉRIEUR de `pas`, et rend le reliquat
/// (FR-016).
///
/// Un pas ≤ 1 désactive l'arrondi. Le reliquat abonde la **part coursier** —
/// jamais la marge, et le client ne le paie qu'une fois.
fn arrondir_au_pas_superieur(montant: i64, pas: i64) -> (i64, i64) {
    if pas <= 1 || montant <= 0 {
        return (montant, 0);
    }
    let reste = montant % pas;
    if reste == 0 {
        (montant, 0)
    } else {
        let complement = pas - reste;
        (montant + complement, complement)
    }
}

impl PgTarification {
    /// Évaluation COMPLÈTE : le devis et toute sa traçabilité (règle retenue,
    /// itinéraire, drapeaux). C'est ce que rend le simulateur admin (FR-020) ;
    /// le trait [`EvaluationTarifaire`] n'en expose que le devis.
    ///
    /// En production ([`SourceGrille::EnVigueur`]), les événements du cycle sont
    /// écrits ; en simulation, **rien** n'est écrit (research R10/R11).
    pub async fn evaluer_detail(
        &self,
        demande: &DemandeDevis,
        source: SourceGrille,
    ) -> Result<Evaluation, ErreurTarif> {
        if demande.retraits.is_empty() {
            return Err(ErreurTarif::DemandeInvalide("aucun point de retrait"));
        }
        let knobs = self.knobs(demande.zone_id).await?;

        // ── 1. Ordre des arrêts sur distance ROUTIÈRE (jamais vol d'oiseau
        //       hors dégradé tracé — constitution IV).
        let mut points: Vec<Point> = demande.retraits.clone();
        points.push(demande.client);
        let matrice = matrice_ou_degrade(
            self.routage.as_ref(),
            self.cache.as_ref(),
            &points,
            knobs.cache,
            knobs.facteur_degrade,
            knobs.vitesse_degradee_kmh,
        )
        .await;
        let itineraire = optimisation::optimiser(&matrice, demande.retraits.len());

        // ── 2. Règle la plus spécifique en vigueur — la distance est connue.
        let grille = self.grille_source(demande.zone_id, source).await?;
        let regle_retenue = regle::selectionner(
            &grille.regles,
            &Criteres {
                transport_slug: &demande.transport_slug,
                categorie_slug: demande.categorie_slug.as_deref(),
                distance_m: itineraire.distance_m,
                instant: demande.instant,
                fuseau: knobs.fuseau,
            },
        )
        .ok_or(ErreurTarif::AucuneRegle)?;

        // Une règle dont la devise aurait divergé de celle de la zone (devise de
        // zone éditée après coup) ne doit pas produire un montant ambigu :
        // rejet, jamais conversion (FR-025).
        regle::verifier_devise(&knobs.devise.code, &regle_retenue.devise)?;

        // ── 3. Déplacement : base + km au-delà du seuil, plafonné.
        let base = regle_retenue.prix_client_base();
        let distance_facturee_m =
            (itineraire.distance_m - i64::from(regle_retenue.seuil_km_m)).max(0);
        let km_theorique = (distance_facturee_m * regle_retenue.prix_par_km) / METRES_PAR_KM;
        // Le plafond borne la composante KILOMÉTRIQUE : il ne rogne jamais le
        // tarif de base, sans quoi un plafond mal saisi rendrait la part
        // coursier inférieure à sa base — le coursier paierait la course.
        let km = match regle_retenue.prix_plafond {
            Some(plafond) => km_theorique.min((plafond - base).max(0)),
            None => km_theorique,
        };

        // ── 4. Suppléments activés par la zone.
        let supplements = if knobs.drapeaux.pluie {
            knobs.supplement_pluie
        } else {
            0
        };

        // ── 5. Grille d'effort — 100 % part coursier (T030, SC-007). Elle
        //       abonde le prix client ET la part coursier ; la marge, elle, ne
        //       bouge pas d'un franc.
        let effort = crate::effort::calculer(
            &knobs.effort,
            demande.nb_articles,
            &demande.attentes,
            itineraire.troncons_entre_arrets(),
        );

        // ── 6. Arrondi du prix client ; le reliquat abonde la part coursier.
        let avant_arrondi = base + km + supplements + effort.total();
        let (prix_arrondi, arrondi) = arrondir_au_pas_superieur(avant_arrondi, knobs.arrondi_pas);

        // La part coursier est fixée ICI, avant tout drapeau : c'est la somme
        // due au coursier pour son travail. Les étapes 7 et 8 ne la touchent
        // plus jamais.
        let part_coursier = prix_arrondi - regle_retenue.marge;
        let mut prix_client = prix_arrondi;
        let mut marge = regle_retenue.marge;

        // ── 7. Drapeaux de zone. La gratuité des commissions passe EN PREMIER :
        //      elle retire la marge du prix client ; l'appliquer après une mise
        //      à 0 rendrait un prix client négatif.
        if knobs.drapeaux.gratuite_commissions {
            prix_client = part_coursier;
            marge = 0;
        }
        if knobs.drapeaux.livraison_offerte_mefali {
            prix_client = 0;
        }

        // ── 8. VND-08 — APRÈS les drapeaux, et pour les commandes MONO-VENDEUR
        //      seulement : sur un panier multi-vendeurs, l'offre d'un vendeur ne
        //      peut pas couvrir la course des autres (FR-018).
        let mut retenue_vendeur = 0;
        if demande.mono_vendeur && prix_client > 0 {
            if let Some(offre) = demande.offre_livraison_vendeur {
                if offre.joue(demande.montant_panier) {
                    retenue_vendeur = prix_client;
                    prix_client = 0;
                }
            }
        }

        // ── 9. Figeage.
        let detour_m = optimisation::detour_m(&matrice, &itineraire);
        let proposer_scission = knobs
            .plafond_eclatement_m
            .is_some_and(|plafond| detour_m > plafond);

        let devis = Devis {
            prix_client,
            part_coursier,
            marge,
            devise: knobs.devise.code.clone(),
            distance_m: itineraire.distance_m,
            eta_s: itineraire.eta_s,
            degraded: itineraire.degraded,
            proposer_scission,
            ordre: itineraire.ordre.clone(),
            composantes: Composantes {
                base,
                km,
                supplements,
                effort_paliers: effort.paliers,
                effort_attente: effort.attente,
                effort_arrets: effort.arrets,
                arrondi,
                retenue_vendeur,
            },
        };
        debug_assert!(
            devis.invariant_verifie() != Some(false),
            "invariant prix_client = part_coursier + marge rompu : {devis:?}"
        );

        let evaluation = Evaluation {
            devis,
            itineraire,
            regle: RegleRetenue {
                regle_id: regle_retenue.id,
                transport_slug: regle_retenue.transport_slug.clone(),
                priorite: regle_retenue.priorite,
            },
            drapeaux: knobs.drapeaux,
            effort_non_facture: knobs.drapeaux.livraison_offerte_mefali && effort.total() > 0,
        };

        // Le SIMULATEUR est muet : un dry run d'admin ne doit pas peupler les
        // métriques MET ni ressembler à une course réelle (research R10).
        if !source.est_simulation() {
            self.journaliser_evaluation(demande, &evaluation, &knobs)
                .await?;
        }
        Ok(evaluation)
    }

    /// Grille contre laquelle évaluer, selon la source demandée.
    async fn grille_source(
        &self,
        zone: Uuid,
        source: SourceGrille,
    ) -> Result<Grille, ErreurTarif> {
        match source {
            SourceGrille::EnVigueur => self
                .grille_en_vigueur(zone)
                .await?
                // « En vigueur À LA DATE considérée » (FR-010) : une grille
                // publiée à effet futur ne tarife pas encore.
                .filter(|g| g.effet_le.is_some_and(|effet| effet <= Utc::now()))
                .ok_or(ErreurTarif::AucuneGrilleEnVigueur(zone)),
            SourceGrille::Brouillon(id) => {
                let grille = self.grille(id).await?;
                if grille.etat != crate::modele::EtatGrille::Brouillon {
                    return Err(ErreurTarif::PasUnBrouillon(id));
                }
                Ok(grille)
            }
        }
    }

    /// T019 — écrit les événements d'une évaluation RÉELLE, dans une transaction.
    ///
    /// Payloads **minimisés ARTCI** : ni latitude ni longitude, jamais. Seules
    /// des distances arrondies au mètre et des montants en unités mineures.
    async fn journaliser_evaluation(
        &self,
        demande: &DemandeDevis,
        evaluation: &Evaluation,
        knobs: &Knobs,
    ) -> Result<(), ErreurTarif> {
        let degrade = evaluation.devis.degraded;
        let effort_journalise = evaluation.effort_non_facture;
        if !degrade && !effort_journalise {
            return Ok(());
        }

        let mut tx = self.pool.begin().await?;
        if degrade {
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "routage.degrade",
                    entite_type: "devis",
                    // Le devis n'est pas une entité persistée ce cycle (CMD le
                    // verrouillera) : la zone est la seule entité durable en jeu
                    // au moment du calcul.
                    entite_id: demande.zone_id,
                    payload: json!({
                        "zone": demande.zone_id,
                        "transport": demande.transport_slug,
                        "nb_points": demande.retraits.len() + 1,
                        "distance_m": evaluation.devis.distance_m,
                        "facteur": knobs.facteur_degrade,
                        "motif": "routage_indisponible",
                    }),
                    survenu_le: Utc::now(),
                },
            )
            .await?;
        }
        if effort_journalise {
            let c = &evaluation.devis.composantes;
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "effort.calcule",
                    entite_type: "devis",
                    entite_id: demande.zone_id,
                    payload: json!({
                        "zone": demande.zone_id,
                        "transport": demande.transport_slug,
                        "montant_effort": c.effort_total(),
                        "paliers": c.effort_paliers,
                        "attente": c.effort_attente,
                        "arrets": c.effort_arrets,
                        "nb_articles": demande.nb_articles,
                        "nb_arrets": demande.retraits.len(),
                        "facture": false,
                        "devise": knobs.devise.code,
                    }),
                    survenu_le: Utc::now(),
                },
            )
            .await?;
        }
        tx.commit().await?;
        Ok(())
    }

    /// Itinéraire optimisé seul, sans tarifer — support d'[`OptimisationArrets`].
    async fn itineraire_optimise(
        &self,
        zone: Uuid,
        retraits: &[Point],
        client: Point,
    ) -> Result<(Matrice, Itineraire), ErreurTarif> {
        if retraits.is_empty() {
            return Err(ErreurTarif::DemandeInvalide("aucun point de retrait"));
        }
        let knobs = self.knobs(zone).await?;
        let mut points = retraits.to_vec();
        points.push(client);
        let matrice = matrice_ou_degrade(
            self.routage.as_ref(),
            self.cache.as_ref(),
            &points,
            knobs.cache,
            knobs.facteur_degrade,
            knobs.vitesse_degradee_kmh,
        )
        .await;
        let itineraire = optimisation::optimiser(&matrice, retraits.len());
        Ok((matrice, itineraire))
    }
}

#[async_trait]
impl EvaluationTarifaire for PgTarification {
    async fn evaluer(
        &self,
        demande: DemandeDevis,
        source: SourceGrille,
    ) -> Result<Devis, ErreurTarif> {
        Ok(self.evaluer_detail(&demande, source).await?.devis)
    }
}

#[async_trait]
impl OptimisationArrets for PgTarification {
    async fn optimiser(
        &self,
        zone: Uuid,
        retraits: &[Point],
        client: Point,
    ) -> Result<Itineraire, ErreurTarif> {
        Ok(self.itineraire_optimise(zone, retraits, client).await?.1)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// L'arrondi monte au pas SUPÉRIEUR et rend exactement le reliquat.
    #[test]
    fn arrondi_au_pas_superieur() {
        assert_eq!(arrondir_au_pas_superieur(300, 25), (300, 0), "déjà au pas");
        assert_eq!(arrondir_au_pas_superieur(301, 25), (325, 24));
        assert_eq!(arrondir_au_pas_superieur(324, 25), (325, 1));
        assert_eq!(arrondir_au_pas_superieur(0, 25), (0, 0), "0 reste 0");
        assert_eq!(arrondir_au_pas_superieur(137, 1), (137, 0), "pas 1 = aucun");
        assert_eq!(arrondir_au_pas_superieur(137, 0), (137, 0), "pas 0 = aucun");
    }
}
