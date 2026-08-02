//! Composition racine du domaine commandes (data-model §4).
//!
//! ÉCRITURES = méthodes inhérentes sur `&mut PgTransaction` — la transition et
//! son événement outbox vivent dans la MÊME transaction, et c'est impossible à
//! contourner (constitution VI). LECTURES = sur le pool.
//!
//! `PgCommandes` porte les collaborateurs du domaine : la configuration de zone
//! (dérivée du pool, comme `PgPrestataires` le fait), le catalogue et les prix
//! figés (`PgPrestataires`), l'évaluation tarifaire et l'optimisation d'arrêts
//! (cycle 007), les restrictions de compte (port implémenté par `comptes`) et
//! le stockage objet. Aucun n'est optionnel : une composition incomplète ne
//! compile pas.

use std::sync::Arc;

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use prestataires::PgPrestataires;
use serde_json::json;
use socle::{ecrire_evenement, DepotObjets, NouvelEvenement};
use sqlx::PgPool;
use tarification::{EvaluationTarifaire, OptimisationArrets};
use uuid::Uuid;
use zones::PgZones;

use crate::annulation::AuteurAnnulation;
use crate::etats::{verifier_transition, Acteur, Niveau};
use crate::modele::{
    ArretACollecter, ErreurCommandes, EtatCommande, EtatLivraison, EtatPaiement, ModeCollecte,
    ModePaiement, ProgressionCollecte, StatutArret,
};
use crate::ports::{
    ArretsDeCollecte, Capacite, CommandeADispatcher, CommandeAPayer, CommandesADispatcher,
    CommandesAPayer, EtatProgression, MotifPrepaiementDispatch, PositionCoursier, PreuvesEchec,
    RestrictionsCompte, MOTIF_ANNULATION_EXPIRATION,
};

/// Clés de configuration de zone lues par la file d'attente (constitution I —
/// aucun seuil en dur).
mod cles_attente {
    /// Ancienneté au-delà de laquelle une attente est ESCALADÉE (FR-038).
    pub const ESCALADE_ATTENTE_S: &str = "commande.escalade_attente_coursier_s";
}

/// Handle de dépôt du domaine commandes. Clone bon marché (pool et ports
/// partagés).
#[derive(Clone)]
pub struct PgCommandes {
    pub(crate) pool: PgPool,
    /// Configuration héritée — DÉRIVÉE du pool (même base), patron du cycle 005.
    pub(crate) zones: PgZones,
    /// Catalogue, commandabilité, sites, `figer_prix`.
    pub(crate) prestataires: PgPrestataires,
    /// Devis figé (cycle 007) — injecté : il porte le client OSRM.
    pub(crate) evaluation: Arc<dyn EvaluationTarifaire>,
    /// Ordre des arrêts (cycle 007).
    pub(crate) optimisation: Arc<dyn OptimisationArrets>,
    /// Restrictions CPT-06 — implémentées par le crate `comptes` (P3, R12).
    pub(crate) restrictions: Arc<dyn RestrictionsCompte>,
    /// Stockage objet (photos de substitution, photo de dépôt).
    pub(crate) objets: Arc<dyn DepotObjets>,
    /// Dernière position du coursier + son ÂGE (Redis éphémère, R13). Une
    /// position sans âge serait pire que pas de position : l'app la croirait
    /// fraîche (FR-040).
    pub(crate) positions: Arc<dyn PositionCoursier>,
    /// Preuves d'échec (CRS-05, non construit). Sans elles, un échec est
    /// REFUSÉ : « le coursier ne perd jamais » suppose une trace (FR-056).
    pub(crate) preuves: Arc<dyn PreuvesEchec>,
}

impl PgCommandes {
    /// Compose le domaine. `PgZones` est dérivé du pool ; tous les autres
    /// collaborateurs sont injectés par la racine (`api`), qui seule connaît
    /// l'infrastructure (constitution II).
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        pool: PgPool,
        prestataires: PgPrestataires,
        evaluation: Arc<dyn EvaluationTarifaire>,
        optimisation: Arc<dyn OptimisationArrets>,
        restrictions: Arc<dyn RestrictionsCompte>,
        objets: Arc<dyn DepotObjets>,
        positions: Arc<dyn PositionCoursier>,
        preuves: Arc<dyn PreuvesEchec>,
    ) -> Self {
        Self {
            zones: PgZones::new(pool.clone()),
            pool,
            prestataires,
            evaluation,
            optimisation,
            restrictions,
            objets,
            positions,
            preuves,
        }
    }

    /// Remplace la source de preuves d'échec **après** construction.
    ///
    /// Nécessaire parce que le calcul réel des preuves vit dans `coursier`, qui
    /// dépend de `commandes` : les deux ne peuvent pas se construire l'un dans
    /// l'autre. La racine `api` construit donc `PgCommandes` avec le double,
    /// puis `PgCoursier` par-dessus, puis rebranche le vrai port ici — patron
    /// `PgCoursier::avec_litiges`.
    ///
    /// ⚠ Le `PgCommandes` **déjà cloné** dans `PgCoursier` conserve l'ancien
    /// port. C'est sans effet : `coursier` ne déclare aucun échec, il ne lit que
    /// la course. Et l'inverse — laisser `coursier` déclarer un échec dont il
    /// fournit lui-même la preuve — serait un circuit que ce découpage évite.
    #[must_use]
    pub fn avec_preuves(mut self, preuves: Arc<dyn PreuvesEchec>) -> Self {
        self.preuves = preuves;
        self
    }

    /// Accès au pool (racine de composition `qr`).
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Accès aux restrictions de compte (garde de création, sanctions §7.5).
    pub fn restrictions(&self) -> &Arc<dyn RestrictionsCompte> {
        &self.restrictions
    }

    /// Accès au stockage objet (photos de substitution, rétention de zone).
    pub fn objets(&self) -> &Arc<dyn DepotObjets> {
        &self.objets
    }

    // ── Transitions GARDÉES des deux niveaux supérieurs (T034) ─────────────
    //
    // Un seul chemin d'écriture par niveau. Toute bascule — collecte, remise,
    // affectation, mise en attente, annulation, échec — passe par ces deux
    // méthodes, donc par `etats::verifier_transition` : il est impossible
    // d'écrire un état sans l'avoir fait valider, et impossible de le faire
    // sans son événement, qui voyage dans le même appel.

    /// Transition GARDÉE d'une livraison + son événement, dans la MÊME
    /// transaction (constitution VI).
    ///
    /// La ligne est verrouillée avant la garde : l'état lu est celui sur lequel
    /// la transition sera écrite, jamais un état devenu obsolète entre-temps.
    pub(crate) async fn transition_livraison(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        livraison_id: Uuid,
        vers: EtatLivraison,
        acteur: Acteur,
        horodatage: DateTime<Utc>,
        evenement: Option<NouvelEvenement<'_>>,
    ) -> Result<EtatLivraison, ErreurCommandes> {
        let depuis = sqlx::query_scalar!(
            r#"SELECT etat::text AS "etat!" FROM commandes.livraison
               WHERE id = $1 FOR UPDATE"#,
            livraison_id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurCommandes::LivraisonInconnue(livraison_id))?;

        verifier_transition(Niveau::Livraison, Some(&depuis), vers.comme_str(), acteur)?;

        sqlx::query!(
            "UPDATE commandes.livraison
                SET etat = $2::text::commandes.etat_livraison, etat_le = $3
              WHERE id = $1",
            livraison_id,
            vers.comme_str(),
            horodatage,
        )
        .execute(&mut **tx)
        .await?;

        if let Some(evenement) = evenement {
            ecrire_evenement(tx, evenement).await?;
        }
        Ok(vers)
    }

    /// Transition GARDÉE du tronc commande + son événement, dans la MÊME
    /// transaction (constitution VI).
    pub(crate) async fn transition_commande(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        commande_id: Uuid,
        vers: EtatCommande,
        acteur: Acteur,
        horodatage: DateTime<Utc>,
        evenement: Option<NouvelEvenement<'_>>,
    ) -> Result<EtatCommande, ErreurCommandes> {
        let depuis = sqlx::query_scalar!(
            r#"SELECT etat::text AS "etat!" FROM commandes.commande
               WHERE id = $1 FOR UPDATE"#,
            commande_id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurCommandes::CommandeInconnue(commande_id))?;

        verifier_transition(Niveau::Commande, Some(&depuis), vers.comme_str(), acteur)?;

        sqlx::query!(
            "UPDATE commandes.commande
                SET etat = $2::text::commandes.etat_commande, etat_le = $3
              WHERE id = $1",
            commande_id,
            vers.comme_str(),
            horodatage,
        )
        .execute(&mut **tx)
        .await?;

        if let Some(evenement) = evenement {
            ecrire_evenement(tx, evenement).await?;
        }
        Ok(vers)
    }

    /// Affecte un coursier à la commande : la livraison reçoit son coursier, le
    /// tronc passe EN_COURS. Reprend une commande en attente exactement comme
    /// une commande neuve — c'est la table de transitions qui autorise les deux
    /// origines (`nouvelle` et `en_attente_coursier`), pas un `if`.
    ///
    /// C'est **DSP** qui décidera QUEL coursier ; ce cycle offre l'écriture et
    /// l'exerce par le double [`crate::AffectationSimulee`] (research R16).
    pub async fn assigner_coursier(
        &self,
        commande_id: Uuid,
        coursier: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<Uuid, ErreurCommandes> {
        let mut tx = self.pool.begin().await?;
        let livraison_id = self
            .assigner_coursier_tx(&mut tx, commande_id, coursier, horodatage)
            .await?;
        tx.commit().await?;
        Ok(livraison_id)
    }

    /// Variante transactionnelle d'[`Self::assigner_coursier`] — l'affectation
    /// et son événement dans une transaction que l'appelant possède déjà.
    pub(crate) async fn assigner_coursier_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        commande_id: Uuid,
        coursier: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<Uuid, ErreurCommandes> {
        let livraison = sqlx::query!(
            r#"SELECT l.id, l.etat::text AS "etat!", c.cree_le,
                      c.etat::text AS "etat_commande!"
               FROM commandes.livraison l
               JOIN commandes.commande c ON c.id = l.commande_id
               WHERE l.commande_id = $1
               FOR UPDATE OF l"#,
            commande_id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurCommandes::CommandeInconnue(commande_id))?;

        let depuis_attente = livraison.etat_commande == EtatCommande::EnAttenteCoursier.comme_str();
        let delai_assignation_s = (horodatage - livraison.cree_le).num_seconds().max(0);

        sqlx::query!(
            "UPDATE commandes.livraison SET coursier_id = $2, assignee_le = $3 WHERE id = $1",
            livraison.id,
            coursier,
            horodatage,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "livraison.affectee",
                entite_type: "livraison",
                entite_id: livraison.id,
                payload: json!({
                    "commande": commande_id,
                    "coursier": coursier,
                    "delai_assignation_s": delai_assignation_s,
                }),
                survenu_le: horodatage,
            },
        )
        .await?;

        self.transition_commande(
            tx,
            commande_id,
            EtatCommande::EnCours,
            Acteur::Systeme,
            horodatage,
            Some(NouvelEvenement {
                type_evenement: "commande.assignee",
                entite_type: "commande",
                entite_id: commande_id,
                payload: json!({
                    "livraison": livraison.id,
                    "coursier": coursier,
                    "depuis_attente": depuis_attente,
                }),
                survenu_le: horodatage,
            }),
        )
        .await?;

        Ok(livraison.id)
    }

    // ── File d'attente coursier (CMD-10, T038) ─────────────────────────────
    //
    // **Aucune table dédiée** : la file EST la table `commande`, filtrée par son
    // état et ordonnée par `cree_le` — l'index partiel `commande_attente_fifo`
    // la sert. Une table de file séparée serait un second lieu de vérité à tenir
    // synchronisé, et le premier désaccord entre les deux perdrait une commande.

    /// Aucun coursier éligible : la commande entre dans la file FIFO (FR-037).
    ///
    /// C'est un état ANNONCÉ, pas un échec silencieux : le client voit « on
    /// cherche un coursier », avec son délai allongé et son annulation **sans
    /// frais** (maquette C4-4b). Sans cet état, la commande resterait
    /// `nouvelle` et nul ne saurait qu'elle attend.
    pub async fn mettre_en_attente_coursier(
        &self,
        commande_id: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<EtatCommande, ErreurCommandes> {
        let mut tx = self.pool.begin().await?;
        let commande = sqlx::query!(
            "SELECT zone_id, cree_le FROM commandes.commande WHERE id = $1",
            commande_id,
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(ErreurCommandes::CommandeInconnue(commande_id))?;

        let etat = self
            .transition_commande(
                &mut tx,
                commande_id,
                EtatCommande::EnAttenteCoursier,
                Acteur::Systeme,
                horodatage,
                Some(NouvelEvenement {
                    type_evenement: "commande.mise_en_attente_coursier",
                    entite_type: "commande",
                    entite_id: commande_id,
                    payload: json!({
                        "zone": commande.zone_id,
                        "motif": "aucun_coursier_eligible",
                        "age_s": (horodatage - commande.cree_le).num_seconds().max(0),
                    }),
                    survenu_le: horodatage,
                }),
            )
            .await?;
        tx.commit().await?;
        Ok(etat)
    }

    /// Escalade les attentes qui ont franchi `commande.escalade_attente_coursier_s`
    /// dans une zone (FR-038). Renvoie les commandes escaladées.
    ///
    /// **Une seule fois par commande** : le balayage est périodique, et
    /// ré-émettre à chaque passage noierait l'alerte qu'elle est censée être.
    /// L'idempotence s'appuie sur l'outbox lui-même — l'événement déjà écrit
    /// EST la trace de l'escalade, donc aucune colonne supplémentaire n'est
    /// nécessaire, et aucune ne peut se désynchroniser de lui.
    pub async fn escalader_attentes(
        &self,
        zone_id: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<Vec<Uuid>, ErreurCommandes> {
        let seuil_s = self
            .parametre_i64(zone_id, cles_attente::ESCALADE_ATTENTE_S)
            .await?;

        // ⚠ Cycle DSP 009 — le `WHERE` couvre AUSSI les commandes en `nouvelle`.
        // DSP-06 escalade *toute* commande non assignée : celle qui attend dans
        // la file FIFO comme celle dont la cascade n'a trouvé personne. Sans
        // cette extension, une commande que le dispatch n'arrive pas à placer
        // resterait `nouvelle` et **muette** — personne ne serait alerté.
        //
        // Le `chemin` du payload dit laquelle des deux : `file` quand elle est
        // formellement en attente, `pipeline` quand elle est encore `nouvelle`.
        //
        // Le `NOT EXISTS` sur l'outbox RESTE le marqueur d'idempotence : c'est
        // lui qui livre « exactement une alerte par commande, quel que soit le
        // chemin » (FR-066) — et aucune colonne ne peut s'en désynchroniser.
        let candidates = sqlx::query!(
            r#"SELECT c.id,
                      c.etat::text AS "etat!",
                      EXTRACT(EPOCH FROM ($2::timestamptz - c.cree_le))::bigint AS "age_s!"
               FROM commandes.commande c
               WHERE c.etat IN ('en_attente_coursier', 'nouvelle')
                 AND c.zone_id = $1
                 AND EXTRACT(EPOCH FROM ($2::timestamptz - c.cree_le)) >= $3::bigint
                 AND NOT EXISTS (
                     SELECT 1 FROM outbox.evenement e
                     WHERE e.type_evenement = 'commande.attente_coursier_escaladee'
                       AND e.entite_id = c.id
                 )
               ORDER BY c.cree_le"#,
            zone_id,
            horodatage,
            seuil_s,
        )
        .fetch_all(&self.pool)
        .await?;

        let mut escaladees = Vec::new();
        for candidate in candidates {
            let chemin = if candidate.etat == "en_attente_coursier" {
                "file"
            } else {
                "pipeline"
            };
            let mut tx = self.pool.begin().await?;
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "commande.attente_coursier_escaladee",
                    entite_type: "commande",
                    entite_id: candidate.id,
                    payload: json!({
                        "zone": zone_id,
                        "age_s": candidate.age_s,
                        "seuil_s": seuil_s,
                        "chemin": chemin,
                    }),
                    survenu_le: horodatage,
                },
            )
            .await?;
            tx.commit().await?;
            escaladees.push(candidate.id);
        }
        Ok(escaladees)
    }

    /// Prépaiement confirmé (PAY **simulé** ce cycle, research R16) : le tronc
    /// repasse `nouvelle`, le paiement est `regle`. Rien ne part avant ce
    /// passage — c'est le seul moyen pour une commande en attente de paiement
    /// d'atteindre le dispatch.
    pub async fn confirmer_prepaiement(
        &self,
        commande_id: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<EtatCommande, ErreurCommandes> {
        let mut tx = self.pool.begin().await?;
        let commande = sqlx::query!(
            r#"SELECT total_unites, devise, mode_paiement::text AS "mode_paiement!"
               FROM commandes.commande WHERE id = $1"#,
            commande_id,
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(ErreurCommandes::CommandeInconnue(commande_id))?;

        let etat = self
            .transition_commande(
                &mut tx,
                commande_id,
                EtatCommande::Nouvelle,
                Acteur::Systeme,
                horodatage,
                Some(NouvelEvenement {
                    type_evenement: "commande.paiement_confirme",
                    entite_type: "commande",
                    entite_id: commande_id,
                    payload: json!({
                        "mode": commande.mode_paiement,
                        "total": commande.total_unites,
                        "devise": commande.devise,
                    }),
                    survenu_le: horodatage,
                }),
            )
            .await?;

        // Un seul montant, encaissé en une fois : `regle` ou rien. Aucun état
        // intermédiaire « partiellement réglé » n'existe (constitution III).
        sqlx::query!(
            "UPDATE commandes.commande SET etat_paiement = 'regle' WHERE id = $1",
            commande_id,
        )
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;
        Ok(etat)
    }

    /// Bascule l'arrêt en COLLECTÉ dans `tx`, écrit `arret.collecte`, et si tous
    /// les arrêts de la livraison sont résolus, bascule la livraison EN_LIVRAISON
    /// en écrivant `livraison.mise_en_livraison`.
    ///
    /// Idempotent par `uuid_client` : un rejeu du même uuid sur un arrêt déjà
    /// `collecte` renvoie la progression sans nouvelle écriture ni événement.
    #[allow(clippy::too_many_arguments)]
    pub async fn marquer_arret_collecte(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        arret_id: Uuid,
        uuid_client: Uuid,
        mode: ModeCollecte,
        photo_cle: Option<&str>,
        distance_m: i32,
        horodatage_serveur: DateTime<Utc>,
        acteur: Uuid,
    ) -> Result<ProgressionCollecte, ErreurCommandes> {
        // Contexte de l'arrêt + verrou de ligne (join segment→livraison→commande).
        let arret = sqlx::query!(
            r#"SELECT a.statut::text AS "statut!", a.collecte_uuid_client,
                      a.segment_id, s.livraison_id, l.commande_id,
                      a.prestataire_id, a.devise,
                      l.etat::text AS "etat_livraison!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE a.id = $1
               FOR UPDATE OF a"#,
            arret_id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurCommandes::ArretInconnu(arret_id))?;

        let statut: StatutArret = arret.statut.parse()?;

        // Idempotence & garde d'état (data-model §1.3).
        match statut {
            // Rejeu du MÊME uuid_client → succès sans nouvelle écriture ni événement.
            StatutArret::Collecte if arret.collecte_uuid_client == Some(uuid_client) => {
                return self.progression(tx, arret.livraison_id, false).await;
            }
            // Déjà collecté par un AUTRE uuid, arrêt indisponible, ou coursier
            // en route sans avoir déclaré son arrivée → refus. `en_route` est
            // absent de la table de transitions (data-model §3.3) : c'est
            // `arrive_le` qui fonde la prime d'attente (TRF-06), on ne peut pas
            // le sauter.
            StatutArret::Collecte | StatutArret::Indisponible | StatutArret::EnRoute => {
                return Err(ErreurCommandes::EtatIncompatible {
                    avant: statut.comme_str().to_owned(),
                    apres: StatutArret::Collecte.comme_str().to_owned(),
                });
            }
            // `a_collecter → collecte` DIRECT : chemin du cycle 006, conservé
            // tel quel (le coursier peut scanner sans avoir déclaré son trajet).
            // `arrive → collecte` : chemin nominal de la boucle CMD-04.
            StatutArret::ACollecter | StatutArret::Arrive => {}
        }

        // Ce que le coursier sort VRAIMENT de sa poche ici, maintenant : la
        // somme de ses lignes vivantes (FR-013), pas `arret.montant_avance`
        // figé à la création. Un article retiré chez ce vendeur ne se paie
        // pas, et c'est ce montant-là — celui que K3 affiche en gros rouge —
        // qui doit partir dans l'événement, sinon la caisse compte de l'argent
        // que personne n'a versé. Trouvé par T087 : 900 F d'écart entre les
        // deux écrans de la même app (rapport-ecarts §5.2).
        //
        // Recalculé ICI plutôt que lu depuis la colonne, parce que le rejeu
        // hors-ligne peut présenter la collecte AVANT le retrait de ligne : la
        // colonne serait alors juste en base et fausse dans l'événement.
        let montant_articles = sqlx::query_scalar!(
            r#"SELECT COALESCE(SUM(
                          lc.quantite * COALESCE(lc.remplace_prix_unites, pf.prix_unites)
                      ) FILTER (WHERE lc.statut <> 'retiree'), 0)::bigint AS "montant!"
                 FROM commandes.ligne_commande lc
                 JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
                WHERE lc.arret_id = $1"#,
            arret_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        // ── Retenue VND-08 (cycle PAY 011, T055 — research R9) ─────────────
        //
        // La retenue est LUE dans le devis figé, jamais recalculée : le moteur
        // de tarification a déjà arbitré l'offre du vendeur contre les drapeaux
        // de zone à la création (`evaluation.rs` §8, APRÈS §7). La recalculer
        // ici créerait une seconde vérité tarifaire — et « le drapeau de zone
        // prime » deviendrait une règle tenue à deux endroits.
        //
        // Elle ne joue que si la livraison n'a qu'UN arrêt de collecte : sur un
        // panier multi-vendeurs, l'offre d'un vendeur ne peut pas couvrir la
        // course des autres (FR-051). Le devis porte déjà `retenue_vendeur = 0`
        // dans ce cas — la garde ci-dessous est la ceinture qui va avec les
        // bretelles, et elle protège d'un devis figé AVANT une scission.
        let contexte_retenue = sqlx::query!(
            r#"SELECT COALESCE((l.devis_composantes->>'retenue_vendeur')::bigint, 0)
                          AS "retenue_devis!",
                      -- Les arrêts de COLLECTE seulement : la remise chez le
                      -- client en est un aussi, et la compter ferait passer
                      -- toute commande mono-vendeur pour du multi-vendeurs.
                      (SELECT COUNT(*) FROM commandes.arret a2
                         JOIN commandes.segment s2 ON s2.id = a2.segment_id
                        WHERE s2.livraison_id = l.id
                          AND a2.type_arret = 'collecte') AS "nb_arrets!"
                 FROM commandes.livraison l
                WHERE l.id = $1"#,
            arret.livraison_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        let retenue_applicable = if contexte_retenue.nb_arrets == 1 {
            contexte_retenue.retenue_devis
        } else {
            0
        };
        // Écrêtage à zéro (FR-052) : le coursier n'avance JAMAIS moins que
        // rien. Une retenue supérieure aux articles — panier réduit par des
        // retraits après le devis — se solde par une avance nulle et un fait
        // tracé, pas par une avance négative qui ferait financer le vendeur par
        // le coursier.
        let retenue_appliquee = retenue_applicable.min(montant_articles);
        let retenue_ecretee = retenue_applicable > montant_articles;
        let montant_avance = montant_articles - retenue_appliquee;

        // ── Partie A : bascule a_collecter → collecte ──────────────────────
        sqlx::query!(
            r#"UPDATE commandes.arret
               SET statut = 'collecte',
                   collecte_le = $2,
                   mode_collecte = $3::commandes.mode_collecte,
                   photo_cle = $4,
                   distance_scan_m = $5,
                   collecte_uuid_client = $6,
                   -- Cycle PAY 011 (T055) : le NET reste `montant_avance` — la
                   -- caisse du coursier ne change pas de lecture (R9). Les
                   -- articles bruts et la retenue vivent à côté, parce que le
                   -- reçu vendeur doit montrer les trois montants (FR-071) et
                   -- qu'un net seul ne se décompose pas.
                   montant_avance = $7,
                   montant_articles_unites = $8,
                   retenue_appliquee_unites = $9,
                   retenue_ecretee = $10
               WHERE id = $1"#,
            arret_id,
            horodatage_serveur,
            mode.comme_str() as _,
            photo_cle,
            distance_m,
            uuid_client,
            montant_avance,
            montant_articles,
            retenue_appliquee,
            retenue_ecretee,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "arret.collecte",
                entite_type: "arret",
                entite_id: arret_id,
                payload: json!({
                    "commande": arret.commande_id,
                    "livraison": arret.livraison_id,
                    "segment": arret.segment_id,
                    "prestataire": arret.prestataire_id,
                    "mode": mode.comme_str(),
                    "avec_photo": photo_cle.is_some(),
                    // ARTCI : jamais de lat/lng brut — présence GPS + distance arrondie.
                    "gps_ok": true,
                    "distance_m": distance_m,
                    // `montant_avance` reste le NET : le consommateur de caisse
                    // (cycle 010) continue de lire exactement ce qu'il lisait.
                    "montant_avance": montant_avance,
                    // Ajouts du cycle PAY 011 — le reçu vendeur et le dossier
                    // d'écrêtage naissent de ces trois-là (FR-050 → FR-052).
                    "montant_articles": montant_articles,
                    "retenue_appliquee": retenue_appliquee,
                    "retenue_ecretee": retenue_ecretee,
                    "devise": arret.devise,
                    "acteur": acteur,
                }),
                survenu_le: horodatage_serveur,
            },
        )
        .await?;

        // ── Partie B : ouverture de collecte, puis gating EN_LIVRAISON ──────
        //
        // Un scan peut être la PREMIÈRE action de la course : le chemin direct
        // `à_collecter → collecte` du cycle 006 reste autorisé, et un coursier
        // qui scanne sans avoir déclaré son trajet laisserait sinon la
        // livraison en `assignee` — donc hors du gating, donc bloquée pour
        // toujours. C'est la même classe de panne que P1, par l'autre bout.
        let etat_livraison = self
            .ouvrir_collecte_si_besoin(
                tx,
                arret.livraison_id,
                arret.commande_id,
                arret_id,
                arret.etat_livraison.parse()?,
                acteur,
                horodatage_serveur,
            )
            .await?;
        self.gating_livraison(
            tx,
            arret.livraison_id,
            arret.commande_id,
            acteur,
            horodatage_serveur,
            etat_livraison == EtatLivraison::EnCollecte,
        )
        .await
    }

    /// Bascule la livraison EN_LIVRAISON si toutes ses COLLECTES sont résolues
    /// (et qu'elle est encore `en_collecte`). Renvoie la progression.
    ///
    /// ⚠ **Ne compte que les arrêts de type `collecte`** (cycle CMD 008, P1 /
    /// research R4). Le cycle 006 comptait `count(*)` sur TOUS les arrêts du
    /// segment ; depuis que la remise est elle aussi un arrêt (cadrage §7.2),
    /// `resolus = total` ne serait JAMAIS vrai — l'arrêt de remise n'est jamais
    /// `collecte`, et la livraison resterait bloquée en collecte pour toujours.
    /// Régression silencieuse : aucun test du cycle 006 ne la signalait, faute
    /// d'arrêt de remise dans ses fixtures.
    pub(crate) async fn gating_livraison(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        livraison_id: Uuid,
        commande_id: Uuid,
        acteur: Uuid,
        horodatage_serveur: DateTime<Utc>,
        livraison_en_collecte: bool,
    ) -> Result<ProgressionCollecte, ErreurCommandes> {
        let comptes = sqlx::query!(
            r#"SELECT count(*) AS "total!",
                      count(*) FILTER (WHERE a.statut = 'collecte') AS "collectes!",
                      count(*) FILTER (WHERE a.statut IN ('collecte','indisponible')) AS "resolus!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               WHERE s.livraison_id = $1
                 AND a.type_arret = 'collecte'"#,
            livraison_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        let nb_arrets = comptes.total as i16;
        let nb_collectes = comptes.collectes as i16;
        let nb_resolues = comptes.resolus as i16;
        let tous_resolus = comptes.total > 0 && comptes.resolus == comptes.total;

        let en_livraison = if tous_resolus && livraison_en_collecte {
            // Passe par la garde unique (T034) : la bascule du cycle 006 est
            // désormais une transition VÉRIFIÉE comme les autres, pas un UPDATE
            // conditionnel isolé.
            self.transition_livraison(
                tx,
                livraison_id,
                EtatLivraison::EnLivraison,
                Acteur::Coursier,
                horodatage_serveur,
                Some(NouvelEvenement {
                    type_evenement: "livraison.mise_en_livraison",
                    entite_type: "livraison",
                    entite_id: livraison_id,
                    payload: json!({
                        "commande": commande_id,
                        "nb_arrets": nb_arrets,
                        "acteur": acteur,
                    }),
                    survenu_le: horodatage_serveur,
                }),
            )
            .await?;
            true
        } else {
            false
        };

        Ok(ProgressionCollecte {
            nb_collectes,
            nb_resolues,
            nb_arrets,
            en_livraison,
        })
    }

    /// Tous les arrêts `à_collecter` de la course active du coursier (livraison
    /// `en_collecte` assignée), ordonnés. Vide si aucune course assignée
    /// (R10 — exact en prod avant DSP). Sert le pré-provisionnement (QRC-02).
    pub async fn arrets_course_active(
        &self,
        coursier: Uuid,
    ) -> Result<Vec<ArretACollecter>, ErreurCommandes> {
        let lignes = sqlx::query!(
            r#"SELECT a.id AS arret_id, l.id AS livraison_id, s.id AS segment_id,
                      l.commande_id, a.prestataire_id AS "prestataire_id!", a.site_lat, a.site_lon,
                      a.montant_avance, a.devise
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE l.coursier_id = $1
                 AND l.etat = 'en_collecte'
                 AND a.statut = 'a_collecter'
                 AND a.type_arret = 'collecte'
               ORDER BY s.ordre, a.ordre"#,
            coursier,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| ArretACollecter {
                arret_id: l.arret_id,
                livraison_id: l.livraison_id,
                segment_id: l.segment_id,
                commande_id: l.commande_id,
                prestataire_id: l.prestataire_id,
                site_lat: l.site_lat,
                site_lon: l.site_lon,
                montant_avance: l.montant_avance,
                devise: l.devise,
            })
            .collect())
    }

    /// Arrêt d'une course active du coursier par son id, QUEL QUE SOIT son
    /// statut (pour la vérification puis la garde d'état de `marquer_arret_collecte`).
    /// `None` si l'arrêt n'appartient pas à une course du coursier
    /// (précondition FR-012 → `arret_hors_course`).
    ///
    /// La course est acceptée `assignee` **autant que** `en_collecte` : une
    /// course sort du dispatch en `assignee`, et c'est la première action sur
    /// un arrêt qui l'ouvre (`ouvrir_collecte_si_besoin`). N'accepter que
    /// `en_collecte` rendait ce premier scan impossible — la course ne pouvait
    /// jamais démarrer. Les tests ne le voyaient pas : le bac appelle
    /// `marquer_arret_collecte` sur le domaine, sans passer par la route HTTP
    /// que l'app emprunte.
    pub async fn arret_de_coursier(
        &self,
        coursier: Uuid,
        arret_id: Uuid,
    ) -> Result<Option<ArretACollecter>, ErreurCommandes> {
        let ligne = sqlx::query!(
            r#"SELECT a.id AS arret_id, l.id AS livraison_id, s.id AS segment_id,
                      l.commande_id, a.prestataire_id AS "prestataire_id!", a.site_lat, a.site_lon,
                      a.montant_avance, a.devise
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE a.id = $1 AND l.coursier_id = $2
                 AND l.etat IN ('assignee', 'en_collecte')
                 AND a.type_arret = 'collecte'"#,
            arret_id,
            coursier,
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(ligne.map(|l| ArretACollecter {
            arret_id: l.arret_id,
            livraison_id: l.livraison_id,
            segment_id: l.segment_id,
            commande_id: l.commande_id,
            prestataire_id: l.prestataire_id,
            site_lat: l.site_lat,
            site_lon: l.site_lon,
            montant_avance: l.montant_avance,
            devise: l.devise,
        }))
    }

    /// Progression courante d'une livraison (chemin idempotent — aucune écriture).
    ///
    /// ⚠ Compte les seules COLLECTES (P1 / research R4) : l'arrêt de remise
    /// n'est pas une collecte, une livraison à 2 collectes + 1 remise annonce
    /// « 2 sur 2 », jamais « 2 sur 3 ».
    pub(crate) async fn progression(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        livraison_id: Uuid,
        en_livraison: bool,
    ) -> Result<ProgressionCollecte, ErreurCommandes> {
        let comptes = sqlx::query!(
            r#"SELECT count(*) AS "total!",
                      count(*) FILTER (WHERE a.statut = 'collecte') AS "collectes!",
                      count(*) FILTER (WHERE a.statut IN ('collecte','indisponible'))
                          AS "resolus!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               WHERE s.livraison_id = $1
                 AND a.type_arret = 'collecte'"#,
            livraison_id,
        )
        .fetch_one(&mut **tx)
        .await?;
        Ok(ProgressionCollecte {
            nb_collectes: comptes.collectes as i16,
            nb_resolues: comptes.resolus as i16,
            nb_arrets: comptes.total as i16,
            en_livraison,
        })
    }
}

/// Contrat OFFERT à **PAY** (cycle 011, contracts §2).
///
/// Deux des quatre méthodes **branchent un chemin existant** plutôt que d'en
/// écrire un second (FR-032). C'est le point le plus important de cette
/// implémentation : `confirmer_prepaiement` et l'annulation vivent depuis le
/// cycle 008, avec leurs transitions gardées, leurs événements outbox et leur
/// calcul de remboursement dû. Les réécrire ici aurait donné deux règles pour
/// un même geste — et elles auraient divergé au premier correctif, l'une
/// continuant de rembourser pendant que l'autre cesserait.
#[async_trait]
impl CommandesAPayer for PgCommandes {
    async fn a_payer(&self, commande: Uuid) -> Result<CommandeAPayer, ErreurCommandes> {
        let l = sqlx::query!(
            r#"SELECT c.zone_id, c.client_id, c.total_unites, c.devise,
                      c.mode_paiement::text  AS "mode_paiement!",
                      c.etat::text           AS "etat!",
                      c.etat_paiement::text  AS "etat_paiement!"
               FROM commandes.commande c
               WHERE c.id = $1"#,
            commande,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCommandes::CommandeInconnue(commande))?;

        Ok(CommandeAPayer {
            commande_id: commande,
            zone_id: l.zone_id,
            client_id: l.client_id,
            total_unites: l.total_unites,
            devise: l.devise,
            mode_paiement: l.mode_paiement.parse::<ModePaiement>()?,
            etat: l.etat.parse::<EtatCommande>()?,
            etat_paiement: l.etat_paiement.parse::<EtatPaiement>()?,
        })
    }

    /// Pose enfin `etat_paiement = 'en_attente'` (research R16, FR-014).
    ///
    /// La valeur existe dans l'énumération depuis la migration 0008 et **aucune
    /// ligne de code ne l'écrivait** : une commande mobile money restait à
    /// `'du'`, strictement indiscernable d'une commande cash. Toute lecture qui
    /// voulait savoir « ce paiement est-il en cours ? » devait le deviner.
    ///
    /// Aucun événement outbox : ce n'est pas une transition du tronc, c'est la
    /// matérialisation d'un fait que `paiement.session_ouverte` journalise déjà
    /// dans la MÊME transaction, du côté de `paiements`. En émettre un second
    /// compterait deux fois la même ouverture.
    async fn marquer_paiement_en_attente(
        &self,
        commande: Uuid,
        _quand: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        // La garde est dans le `WHERE` plutôt que dans un `if` précédé d'un
        // `SELECT` : deux ouvertures concurrentes ne peuvent pas toutes deux
        // faire passer une commande déjà réglée à `en_attente`.
        let touchees = sqlx::query!(
            "UPDATE commandes.commande
                SET etat_paiement = 'en_attente'
              WHERE id = $1 AND etat_paiement = 'du'",
            commande,
        )
        .execute(&self.pool)
        .await?
        .rows_affected();

        if touchees == 0 {
            // Ni une erreur, ni un silence : la commande était déjà en attente
            // (rappel idempotent de l'ouverture) ou déjà réglée. Dans les deux
            // cas il n'y a rien à faire, et le refuser casserait l'idempotence
            // que FR-015 exige.
            tracing::debug!(
                commande = %commande,
                "etat_paiement déjà posé — ouverture rejouée, aucun effet",
            );
        }
        Ok(())
    }

    async fn confirmer_prepaiement(
        &self,
        commande: Uuid,
        quand: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        // Chemin du cycle 008, appelé tel quel : transition gardée
        // `en_attente_paiement → nouvelle`, `etat_paiement = 'regle'`, et
        // `commande.paiement_confirme` — déjà consommé par le pipeline de
        // dispatch depuis le cycle 009. Rien à câbler ici.
        PgCommandes::confirmer_prepaiement(self, commande, quand).await?;
        Ok(())
    }

    async fn annuler_pour_expiration(
        &self,
        commande: Uuid,
        quand: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        // Chemin d'annulation EXISTANT (FR-031, FR-032), avec l'auteur
        // `systeme` — la valeur que la taxonomie déclarait depuis le cycle 008
        // sans que rien ne l'écrive, faute d'annulation automatique.
        //
        // `acteur_id` = l'identifiant de la commande : l'appel n'a pas d'acteur
        // humain, et ce paramètre n'est lu que pour la garde de propriété du
        // client, que `Systeme` ne franchit pas.
        //
        // Le calcul de « sans frais » et de la part coursier due reste celui du
        // cycle 008 : une session expirée n'a par construction aucun arrêt
        // collecté, donc `sans_frais = true` et `part_coursier_due = 0` en
        // tombent tout seuls, sans règle spéciale à maintenir.
        self.annuler_commande(
            commande,
            AuteurAnnulation::Systeme,
            commande,
            Some(MOTIF_ANNULATION_EXPIRATION),
            quand,
        )
        .await?;
        Ok(())
    }
}

/// Contrat OFFERT à **DSP** (T039) — que le cycle dispatch consommera sans
/// modification. Ce cycle l'exerce par le double [`crate::AffectationSimulee`],
/// qui décide QUEL coursier prendre et délègue l'écriture ici (research R16).
#[async_trait]
impl CommandesADispatcher for PgCommandes {
    /// File **FIFO par âge** des commandes sans coursier d'une zone.
    ///
    /// L'ordre est `cree_le` croissant, servi par l'index partiel
    /// `commande_attente_fifo` — la plus ancienne d'abord, toujours. Trier par
    /// autre chose (montant, proximité) serait une politique de dispatch : elle
    /// appartient à DSP, pas au stockage de la file.
    ///
    /// ARTCI : aucune coordonnée du CLIENT n'est exposée — seule la position du
    /// premier site VENDEUR, qui est une donnée professionnelle et ce qui
    /// décide de l'éligibilité géographique d'un coursier.
    async fn en_attente_coursier(
        &self,
        zone: Uuid,
    ) -> Result<Vec<CommandeADispatcher>, ErreurCommandes> {
        let lignes = sqlx::query!(
            r#"SELECT c.id, c.zone_id, c.devise,
                      EXTRACT(EPOCH FROM (now() - c.cree_le))::bigint AS "age_s!",
                      (SELECT count(*) FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                         JOIN commandes.livraison l ON l.id = s.livraison_id
                        WHERE l.commande_id = c.id AND a.type_arret = 'collecte')
                          AS "nb_collectes!",
                      (SELECT COALESCE(SUM(a.montant_avance), 0)::bigint FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                         JOIN commandes.livraison l ON l.id = s.livraison_id
                        WHERE l.commande_id = c.id AND a.type_arret = 'collecte')
                          AS "montant_a_avancer!",
                      (SELECT a.site_lat FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                         JOIN commandes.livraison l ON l.id = s.livraison_id
                        WHERE l.commande_id = c.id AND a.type_arret = 'collecte'
                        ORDER BY s.ordre, a.ordre LIMIT 1) AS premiere_collecte_lat,
                      (SELECT a.site_lon FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                         JOIN commandes.livraison l ON l.id = s.livraison_id
                        WHERE l.commande_id = c.id AND a.type_arret = 'collecte'
                        ORDER BY s.ordre, a.ordre LIMIT 1) AS premiere_collecte_lon
               FROM commandes.commande c
               WHERE c.etat = 'en_attente_coursier' AND c.zone_id = $1
               ORDER BY c.cree_le"#,
            zone,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| CommandeADispatcher {
                commande_id: l.id,
                zone_id: l.zone_id,
                age_s: l.age_s,
                nb_collectes: l.nb_collectes,
                montant_a_avancer: l.montant_a_avancer,
                devise: l.devise,
                premiere_collecte_lat: l.premiere_collecte_lat,
                premiere_collecte_lon: l.premiere_collecte_lon,
            })
            .collect())
    }

    /// Affecte un coursier. **Reprend une commande en attente exactement comme
    /// une commande neuve** : c'est la table de transitions qui autorise les
    /// deux origines (`nouvelle` et `en_attente_coursier`), pas une branche —
    /// il n'existe donc aucun chemin de reprise qui pourrait diverger du chemin
    /// nominal.
    async fn affecter(&self, commande: Uuid, coursier: Uuid) -> Result<Uuid, ErreurCommandes> {
        self.assigner_coursier(commande, coursier, Utc::now()).await
    }

    // ── Ajouté par le cycle DSP 009 ───────────────────────────────────────

    /// Course active, tous états de TRAVAIL confondus — servie par l'index
    /// partiel `livraison_coursier_active` du cycle 008.
    async fn course_active(&self, coursier: Uuid) -> Result<Option<Uuid>, ErreurCommandes> {
        Ok(sqlx::query_scalar!(
            r#"SELECT id FROM commandes.livraison
               WHERE coursier_id = $1
                 AND etat IN ('assignee', 'en_collecte', 'en_livraison')
               LIMIT 1"#,
            coursier,
        )
        .fetch_optional(&self.pool)
        .await?)
    }

    /// Fin de la dernière course LIVRÉE — servie par l'index
    /// `livraison_coursier_livree` (migration 0012). Celui du cycle 008 filtre
    /// les états de TRAVAIL et ne convient pas ici.
    async fn fin_derniere_course(
        &self,
        coursier: Uuid,
    ) -> Result<Option<DateTime<Utc>>, ErreurCommandes> {
        Ok(sqlx::query_scalar!(
            r#"SELECT livree_le FROM commandes.livraison
               WHERE coursier_id = $1 AND etat = 'livree' AND livree_le IS NOT NULL
               ORDER BY livree_le DESC
               LIMIT 1"#,
            coursier,
        )
        .fetch_optional(&self.pool)
        .await?
        .flatten())
    }

    /// Capacités requises, lues sur la LIVRAISON de la commande (research R9).
    async fn capacites_requises(&self, commande: Uuid) -> Result<Vec<Capacite>, ErreurCommandes> {
        let lignes = sqlx::query!(
            r#"SELECT cr.famille, cr.valeur
               FROM commandes.capacite_requise cr
               JOIN commandes.livraison l ON l.id = cr.livraison_id
               WHERE l.commande_id = $1
               ORDER BY cr.famille, cr.valeur"#,
            commande,
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(lignes
            .into_iter()
            .map(|l| Capacite {
                famille: l.famille,
                valeur: l.valeur,
            })
            .collect())
    }

    /// L'état d'avancement d'une course, tel que la reprise doit le lire.
    ///
    /// Le « premier arrêt non résolu » est celui contre lequel le rapprochement
    /// se mesure : viser l'arrêt 1 quand le coursier vient de le collecter
    /// ferait passer un coursier qui progresse pour un immobile.
    async fn etat_progression(&self, livraison: Uuid) -> Result<EtatProgression, ErreurCommandes> {
        let ligne = sqlx::query!(
            r#"SELECT l.commande_id, l.coursier_id, l.assignee_le,
                      (SELECT count(*) FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                        WHERE s.livraison_id = l.id
                          AND a.type_arret = 'collecte'
                          AND a.statut = 'collecte') AS "nb_collectes!",
                      (SELECT count(*) FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                        WHERE s.livraison_id = l.id
                          AND a.type_arret = 'collecte') AS "nb_total!",
                      (SELECT a.site_lat FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                        WHERE s.livraison_id = l.id
                          AND a.statut NOT IN ('collecte', 'indisponible')
                        ORDER BY s.ordre, a.ordre LIMIT 1) AS premier_lat,
                      (SELECT a.site_lon FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                        WHERE s.livraison_id = l.id
                          AND a.statut NOT IN ('collecte', 'indisponible')
                        ORDER BY s.ordre, a.ordre LIMIT 1) AS premier_lon
               FROM commandes.livraison l
               WHERE l.id = $1"#,
            livraison,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCommandes::LivraisonInconnue(livraison))?;

        Ok(EtatProgression {
            commande_id: ligne.commande_id,
            coursier_id: ligne.coursier_id,
            assignee_le: ligne.assignee_le,
            nb_arrets_collectes: ligne.nb_collectes,
            nb_arrets_collecte_total: ligne.nb_total,
            premier_arret_lat: ligne.premier_lat,
            premier_arret_lon: ligne.premier_lon,
        })
    }

    /// Retire le coursier et renvoie la commande au pipeline, dans UNE
    /// transaction avec son événement (constitution VI).
    ///
    /// L'ordre compte : la transition du tronc est GARDÉE, donc si la commande
    /// n'est pas `en_cours`, rien n'est écrit — pas même le `coursier_id = NULL`
    /// qui laisserait une livraison orpheline.
    async fn retirer_coursier(
        &self,
        livraison: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        let mut tx = self.pool.begin().await?;
        let ligne = sqlx::query!(
            r#"SELECT commande_id, coursier_id FROM commandes.livraison
               WHERE id = $1 FOR UPDATE"#,
            livraison,
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(ErreurCommandes::LivraisonInconnue(livraison))?;

        self.transition_commande(
            &mut tx,
            ligne.commande_id,
            EtatCommande::EnAttenteCoursier,
            Acteur::Systeme,
            horodatage,
            Some(NouvelEvenement {
                type_evenement: "commande.mise_en_attente_coursier",
                entite_type: "commande",
                entite_id: ligne.commande_id,
                payload: json!({
                    "zone": sqlx::query_scalar!(
                        "SELECT zone_id FROM commandes.commande WHERE id = $1",
                        ligne.commande_id,
                    )
                    .fetch_one(&self.pool)
                    .await?,
                    "motif": "coursier_retire",
                    "age_s": 0,
                }),
                survenu_le: horodatage,
            }),
        )
        .await?;

        sqlx::query!(
            "UPDATE commandes.livraison SET coursier_id = NULL WHERE id = $1",
            livraison,
        )
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;
        Ok(())
    }

    /// Escalade les attentes d'une zone — planifiée par le tic de dispatch.
    async fn escalader_attentes(
        &self,
        zone: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<Vec<Uuid>, ErreurCommandes> {
        PgCommandes::escalader_attentes(self, zone, horodatage).await
    }

    /// Met la commande en file d'attente FIFO — la mécanique CMD-10 existante,
    /// appelée par le pipeline de dispatch.
    async fn mettre_en_attente(
        &self,
        commande: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        self.mettre_en_attente_coursier(commande, horodatage)
            .await?;
        Ok(())
    }

    /// Exige un prépaiement après création : le tronc passe
    /// `nouvelle → en_attente_paiement` et le mode devient `mobile_money`.
    ///
    /// **Un seul montant, un seul état** : le total de la commande ne bouge pas,
    /// et aucune fraction n'est écrite nulle part (constitution III).
    async fn exiger_prepaiement(
        &self,
        commande: Uuid,
        motif: MotifPrepaiementDispatch,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        let mut tx = self.pool.begin().await?;
        let ligne = sqlx::query!(
            "SELECT zone_id, total_unites, devise FROM commandes.commande WHERE id = $1",
            commande,
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(ErreurCommandes::CommandeInconnue(commande))?;

        self.transition_commande(
            &mut tx,
            commande,
            EtatCommande::EnAttentePaiement,
            Acteur::Systeme,
            horodatage,
            Some(NouvelEvenement {
                type_evenement: "commande.paiement_requis",
                entite_type: "commande",
                entite_id: commande,
                payload: json!({
                    "motif": motif.comme_str(),
                    "total": ligne.total_unites,
                    "devise": ligne.devise,
                    "zone": ligne.zone_id,
                }),
                survenu_le: horodatage,
            }),
        )
        .await?;

        sqlx::query!(
            "UPDATE commandes.commande SET mode_paiement = 'mobile_money' WHERE id = $1",
            commande,
        )
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;
        Ok(())
    }
}

#[async_trait]
impl ArretsDeCollecte for PgCommandes {
    async fn arret_a_collecter(
        &self,
        coursier: Uuid,
        prestataire: Uuid,
    ) -> Result<Option<ArretACollecter>, ErreurCommandes> {
        // Arrêt `à_collecter` d'ordre le plus bas de la course active du coursier
        // visant ce prestataire (livraison en_collecte assignée au coursier).
        let ligne = sqlx::query!(
            r#"SELECT a.id AS arret_id, l.id AS livraison_id, s.id AS segment_id,
                      l.commande_id, a.prestataire_id AS "prestataire_id!", a.site_lat, a.site_lon,
                      a.montant_avance, a.devise
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE l.coursier_id = $1
                 AND l.etat = 'en_collecte'
                 AND a.prestataire_id = $2
                 AND a.statut = 'a_collecter'
                 AND a.type_arret = 'collecte'
               ORDER BY s.ordre, a.ordre
               LIMIT 1"#,
            coursier,
            prestataire,
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(ligne.map(|l| ArretACollecter {
            arret_id: l.arret_id,
            livraison_id: l.livraison_id,
            segment_id: l.segment_id,
            commande_id: l.commande_id,
            prestataire_id: l.prestataire_id,
            site_lat: l.site_lat,
            site_lon: l.site_lon,
            montant_avance: l.montant_avance,
            devise: l.devise,
        }))
    }
}

impl PgCommandes {
    /// Livraison d'une commande, s'il y en a une (composant 0..n).
    ///
    /// Sert les surfaces qui nomment la COMMANDE là où le domaine travaille sur
    /// la livraison — l'admin, notamment, ne connaît que le numéro de commande.
    pub async fn livraison_de_commande(
        &self,
        commande_id: Uuid,
    ) -> Result<Option<Uuid>, ErreurCommandes> {
        Ok(sqlx::query_scalar!(
            "SELECT id FROM commandes.livraison WHERE commande_id = $1",
            commande_id,
        )
        .fetch_optional(&self.pool)
        .await?)
    }
}
