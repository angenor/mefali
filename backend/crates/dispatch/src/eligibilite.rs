//! Ne proposer une course qu'à ceux qui peuvent la faire (DSP-02).
//!
//! **Huit critères, nommés un par un** — l'ordre est celui de l'énum Postgres,
//! et il est le même dans le code, dans les tests et dans les agrégats
//! d'événements. Un coursier écarté rend la **liste** de ses motifs, jamais le
//! premier : FR-026 (« la capacité d'avance est le SEUL obstacle ») est
//! indécidable sur un filtre qui s'arrête au premier refus.
//!
//! **Le pool ne rend jamais éligible** (FR-009, research R12). L'index
//! géographique pré-filtre, l'état de pool renseigne — mais rôle, blocage et
//! course active se **confirment en Postgres**. Un état Redis survit à une
//! suspension : sans cette confirmation, un coursier suspendu ce matin
//! recevrait des courses jusqu'à ce qu'il se taise.
//!
//! **Deux étages pour le rayon** (research R5) : le pré-filtre en vol d'oiseau
//! est sûr **par construction** — il MINORE la distance routière, donc il ne
//! peut pas écarter un coursier réellement dans le rayon — puis le test exact se
//! fait sur la distance ROUTIÈRE (constitution IV). Une seule matrice pour tous
//! les candidats, jamais un appel par candidat (FR-035).
//!
//! **Chaque écart est journalisé avec son motif** (FR-029) : un pipeline qui ne
//! trouve personne n'est jamais silencieux sur la raison.

use std::collections::HashSet;

use tarification::Point;
use uuid::Uuid;

use crate::config::ConfigDispatch;
use crate::depot::PgDispatch;
use crate::modele::{
    Capacite, EcartEligibilite, ErreurDispatch, InscriptionPool, MesureProximite, MotifEcart,
};

/// Ce qu'il faut savoir d'une commande pour décider qui peut la faire.
///
/// **Aucune zone ici** : elle vit dans la [`ConfigDispatch`] que `filtrer` reçoit
/// par ailleurs, et qui a été résolue POUR cette zone. La porter deux fois
/// offrirait deux vérités sur la même question — la seconde ne servirait qu'à
/// diverger de la première.
#[derive(Debug, Clone, PartialEq)]
pub struct DemandeEligibilite {
    /// Commande évaluée.
    pub commande: Uuid,
    /// Montant total à avancer, TOUS arrêts confondus (unités mineures).
    pub montant_a_avancer: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Position du PREMIER arrêt de collecte — le centre du rayon (FR-021).
    pub premiere_collecte: Point,
    /// Contreparties de la course : le client **et** les vendeurs de tous les
    /// arrêts. Passées en UN lot au port des paires bloquées (FR-025).
    pub contreparties: Vec<Uuid>,
    /// Capacités que la course exige (famille, valeur).
    pub capacites_requises: Vec<Capacite>,
    /// Coursiers à ne pas re-solliciter pour CETTE commande (FR-051, FR-074) —
    /// déjà destinataires d'une offre, ou retirés par réassignation.
    pub deja_sollicites: Vec<Uuid>,
}

/// Un candidat retenu, avec ce que le filtre a mesuré au passage.
///
/// La distance et la durée sont conservées : le classement s'en sert, et les
/// recalculer coûterait une seconde matrice routière.
#[derive(Debug, Clone, PartialEq)]
pub struct CandidatEligible {
    /// Compte du coursier.
    pub coursier: Uuid,
    /// Son état de pool au moment du filtre.
    pub inscription: InscriptionPool,
    /// Distance routière au premier arrêt (mètres).
    pub distance_m: i64,
    /// Durée de trajet routière (secondes).
    pub duree_s: i64,
    /// Plafond d'avance RETENU (min de la grille et du déclaré).
    pub plafond_retenu_unites: i64,
}

/// Résultat brut du filtre, avant classement.
#[derive(Debug, Clone, PartialEq)]
pub struct Vivier {
    /// Ceux qui peuvent faire la course.
    pub eligibles: Vec<CandidatEligible>,
    /// Ceux qui ne le peuvent pas, avec TOUS leurs motifs.
    pub ecarts: Vec<EcartEligibilite>,
    /// Vrai si la proximité vient du repli vol d'oiseau (constitution IV).
    pub degraded: bool,
    /// Grandeur sur laquelle la proximité a été mesurée.
    pub mesure: MesureProximite,
}

impl PgDispatch {
    /// Le filtre des huit critères.
    ///
    /// ⚠ **Deux lectures par candidat**, assumées à cette échelle et à surveiller
    /// (dette nommée, rapport d'écarts §6.1) : `course_active` et `coursier` sont
    /// interrogées dans la boucle, soit `2n` requêtes pour `n` membres du
    /// pré-filtre. Elles ne peuvent pas être court-circuitées : FR-026 exige la
    /// liste COMPLÈTE des motifs d'écart — s'arrêter au premier refus rendrait
    /// « la capacité d'avance est le seul obstacle » indécidable.
    ///
    /// Elles ne sont pas mises en lot **aujourd'hui** parce que le pré-filtre
    /// géographique borne déjà `n` au rayon de zone, et qu'à Tiassalé il vaut
    /// quelques unités. Le lot coûterait un changement de contrat de DEUX ports
    /// implémentés par `commandes` et `comptes` — c'est-à-dire une modification
    /// hors du périmètre de ce cycle, faite sans mesure.
    ///
    /// **Déclencheur** : quand le pool d'une zone dépasse durablement la
    /// cinquantaine de membres, `bloquees` et `etat` compris (eux aussi par
    /// candidat), passer les quatre en lot — la boucle est déjà écrite pour
    /// consommer des tableaux indexés, la substitution est locale.
    pub async fn filtrer(
        &self,
        config: &ConfigDispatch,
        demande: &DemandeEligibilite,
    ) -> Result<Vivier, ErreurDispatch> {
        // ÉTAGE 1 — pré-filtre géographique. Sûr par construction : le vol
        // d'oiseau minore la route, donc personne d'éligible n'est perdu ici.
        let membres = self
            .pool_coursiers
            .dans_rayon(
                config.zone,
                demande.premiere_collecte.lat,
                demande.premiere_collecte.lon,
                config.rayon_m,
            )
            .await?;

        // Lecture de l'état de pool de chaque membre. Un membre SANS état est un
        // fantôme de l'index (research R2) : il est écarté « hors ligne » et ne
        // reçoit rien — c'est ce que SC-003 exige entre l'expiration et
        // l'élagage.
        let mut inscrits: Vec<(Uuid, Option<InscriptionPool>)> = Vec::new();
        for membre in membres {
            inscrits.push((membre, self.pool_coursiers.etat(membre).await?));
        }

        // ÉTAGE 2 — UNE matrice routière pour tous ceux qui ont un état
        // (FR-035). Jamais un appel par candidat, et jamais d'erreur : le
        // routage dégrade, il ne bloque pas.
        let avec_etat: Vec<&InscriptionPool> =
            inscrits.iter().filter_map(|(_, i)| i.as_ref()).collect();
        let origines: Vec<Point> = avec_etat
            .iter()
            .map(|i| Point {
                lat: i.lat,
                lon: i.lon,
            })
            .collect();
        let trajets = self
            .proximite
            .vers_point(config.zone, &origines, demande.premiere_collecte)
            .await;

        // Paires bloquées : UN aller-retour pour toutes les contreparties de
        // tous les candidats (FR-025). Un appel par arrêt multiplierait la
        // latence du chemin le plus sensible du produit.
        let mut bloques: HashSet<Uuid> = HashSet::new();
        for i in &avec_etat {
            if !self
                .paires
                .bloquees(i.coursier, &demande.contreparties)
                .await?
                .is_empty()
            {
                bloques.insert(i.coursier);
            }
        }

        let porteurs_d_offre = self.coursiers_avec_offre_en_vol().await?;
        let deja_sollicites: HashSet<Uuid> = demande.deja_sollicites.iter().copied().collect();

        let mut eligibles = Vec::new();
        let mut ecarts = Vec::new();
        let mut index_trajet = 0usize;

        for (coursier, etat) in inscrits {
            let mut motifs = Vec::new();

            // 1. HORS LIGNE — aucun état : jamais publié, ou silence au-delà du
            //    TTL. Rien d'autre n'est évaluable, on s'arrête là.
            let Some(inscription) = etat else {
                motifs.push(MotifEcart::HorsLigne);
                journaliser_ecart(demande.commande, coursier, &motifs);
                ecarts.push(EcartEligibilite { coursier, motifs });
                continue;
            };
            let trajet = trajets.trajets.get(index_trajet).copied();
            index_trajet += 1;

            if !inscription.en_ligne {
                motifs.push(MotifEcart::HorsLigne);
            }

            // 2. COURSE ACTIVE — lue en BASE, jamais dans l'état de pool : le
            //    pool est un index (FR-007, FR-009).
            if self.commandes.course_active(coursier).await?.is_some() {
                motifs.push(MotifEcart::CourseActive);
            }

            // 7. COMPTE INDISPONIBLE — confirmé en base lui aussi. Lu ici parce
            //    que ses capacités DÉCLARÉES en sortent (critère 3).
            let exploitable = self.coursiers.coursier(coursier).await?;
            let capacites_declarees = match &exploitable {
                Some(c) => c.capacites.clone(),
                None => Vec::new(),
            };

            // 3. CAPACITÉS NON COUVERTES — les requises doivent TOUTES être
            //    déclarées (FR-017). Générique `(famille, valeur)` : une famille
            //    de plus (qualification d'artisan, phase N) ne coûte rien ici.
            if !demande
                .capacites_requises
                .iter()
                .all(|r| capacites_declarees.contains(r))
            {
                motifs.push(MotifEcart::CapaciteNonCouverte);
            }

            // 4. HORS RAYON — sur la distance ROUTIÈRE (constitution IV). Une
            //    mesure absente ne peut pas écarter : le routage dégrade.
            if let Some(t) = trajet {
                if t.distance_m > config.rayon_m {
                    motifs.push(MotifEcart::HorsRayon);
                }
            }

            // 5. CAPACITÉ D'AVANCE — comparaison en ENTIERS, même devise
            //    (constitution III). Le plafond retenu est `min(palier, déclaré)`.
            let (palier, _) = config.grille_avance.palier(inscription.note_centiemes);
            let plafond_retenu = palier.plafond_unites.min(inscription.plafond_unites);
            if demande.montant_a_avancer > plafond_retenu
                || demande.devise != inscription.devise
            {
                motifs.push(MotifEcart::CapaciteAvance);
            }

            // 6. PAIRE BLOQUÉE — client ou vendeur (CRS-07, non construit).
            if bloques.contains(&coursier) {
                motifs.push(MotifEcart::PaireBloquee);
            }

            if exploitable.is_none() {
                motifs.push(MotifEcart::CompteIndisponible);
            }

            // 8. OFFRE EN VOL — il porte déjà une offre, pour cette commande ou
            //    une autre (FR-056) ; ou il a déjà été sollicité pour celle-ci
            //    (FR-051, FR-074), et lui re-proposer serait du harcèlement.
            if porteurs_d_offre.contains(&coursier) || deja_sollicites.contains(&coursier) {
                motifs.push(MotifEcart::OffreEnVol);
            }

            if motifs.is_empty() {
                let t = trajet.unwrap_or(crate::ports::Trajet {
                    distance_m: 0,
                    duree_s: 0,
                });
                eligibles.push(CandidatEligible {
                    coursier,
                    inscription,
                    distance_m: t.distance_m,
                    duree_s: t.duree_s,
                    plafond_retenu_unites: plafond_retenu,
                });
            } else {
                journaliser_ecart(demande.commande, coursier, &motifs);
                ecarts.push(EcartEligibilite { coursier, motifs });
            }
        }

        // La proximité se classe sur la DURÉE quand elle est connue, sur la
        // distance sinon (FR-035). Un lot dont toutes les durées sont nulles
        // vient d'un routage muet : la distance est alors la seule information.
        let mesure = if eligibles.iter().any(|c| c.duree_s > 0) {
            MesureProximite::Duree
        } else {
            MesureProximite::Distance
        };

        Ok(Vivier {
            eligibles,
            ecarts,
            degraded: trajets.degraded,
            mesure,
        })
    }

    /// Coursiers portant une offre EN VOL non échue.
    ///
    /// L'échéance persistée fait foi : une offre dont le compte à rebours est
    /// passé ne bloque plus son destinataire, même si le tic n'a pas encore
    /// écrit son issue (research R1).
    pub(crate) async fn coursiers_avec_offre_en_vol(
        &self,
    ) -> Result<HashSet<Uuid>, ErreurDispatch> {
        let lignes = sqlx::query_scalar!(
            "SELECT coursier_id FROM dispatch.offre
             WHERE issue = 'en_vol' AND echeance_le > now()",
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(lignes.into_iter().collect())
    }
}

/// Journalise un écart avec son motif (FR-029) — **aucune coordonnée**.
fn journaliser_ecart(commande: Uuid, coursier: Uuid, motifs: &[MotifEcart]) {
    tracing::debug!(
        commande = %commande,
        coursier = %coursier,
        motifs = ?motifs.iter().map(|m| m.comme_str()).collect::<Vec<_>>(),
        "coursier écarté du vivier",
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Les huit motifs sont évalués dans l'ORDRE de l'énum Postgres — c'est ce
    /// qui rend les listes de motifs comparables d'un test à l'autre et les
    /// agrégats d'événements stables.
    #[test]
    fn l_ordre_des_motifs_suit_l_enum_postgres() {
        assert_eq!(
            MotifEcart::TOUS.map(|m| m.comme_str()),
            [
                "hors_ligne",
                "course_active",
                "capacite_non_couverte",
                "hors_rayon",
                "capacite_avance",
                "paire_bloquee",
                "compte_indisponible",
                "offre_en_vol",
            ],
        );
    }
}
