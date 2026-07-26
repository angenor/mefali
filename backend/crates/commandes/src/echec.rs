//! Arbre des échecs (CMD-08, cadrage §7.5) — « le coursier ne perd jamais ».
//!
//! Le tableau §7.5 est une promesse produit ; ce module en fait une **table de
//! décision exécutable**, et c'est toute la différence : une promesse écrite en
//! prose se discute au cas par cas, une table se teste ligne par ligne.
//!
//! Deux axes **INDÉPENDANTS** (research R14) — qui détient l'**argent**, qui
//! détient la **marchandise**. Les confondre était la faute la plus tentante :
//! le coursier peut très bien garder les courses pendant que Mefali porte la
//! dette. Deux colonnes, donc deux assertions par test, et aucune issue ne peut
//! rester silencieuse sur l'une des deux.
//!
//! Ce que ce module NE fait PAS (frontière tranchée en spec, FR-062) : il
//! n'ouvre aucun dossier de litige (AVI-04) et n'écrit aucune ligne de caisse
//! (CRS-06). Il ÉMET `litige.ouvert` et `indemnisation.due` — des contrats sans
//! consommateur ce cycle, que ces modules brancheront sans toucher à CMD.

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgCommandes;
use crate::etats::Acteur;
use crate::modele::{
    Detenteur, ErreurCommandes, EtatCommande, EtatLivraison, Sanction, TypeIssueEchec,
};

/// Clé de zone décidant si une catégorie est **périssable**.
fn cle_perissable(categorie_slug: &str) -> String {
    format!("categorie.{categorie_slug}.perissable")
}

/// Ce que l'arbre §7.5 décide pour une issue donnée.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ResolutionIssue {
    /// Qui détient l'argent à l'issue.
    pub detenteur_argent: Detenteur,
    /// Qui détient la marchandise à l'issue.
    pub detenteur_marchandise: Detenteur,
    /// Un litige est ouvert (contrat AVI-04).
    pub litige_ouvert: bool,
    /// Le coursier doit être indemnisé (contrat CRS-06).
    pub indemnisation_due: bool,
    /// Sanction DEMANDÉE sur le compte client (CPT-06) ; le rang effectif est
    /// arbitré par les restrictions déjà posées.
    pub sanction: Sanction,
}

/// Résout une ligne de l'arbre §7.5.
///
/// `perissable` et `preuves_completes` sont les deux seules entrées
/// contextuelles : tout le reste est décidé par le TYPE d'issue. Fonction pure,
/// donc testable sans base — et c'est elle qui porte la table du cadrage.
pub fn resoudre(
    type_issue: TypeIssueEchec,
    perissable: bool,
    preuves_completes: bool,
) -> ResolutionIssue {
    use TypeIssueEchec as T;
    match type_issue {
        // §7.5-1 — non périssable : retour au vendeur, remboursements tracés
        // par arrêt. Personne n'est lésé : ni litige, ni indemnisation.
        T::RefusNonPerissable => ResolutionIssue {
            detenteur_argent: Detenteur::Vendeur,
            detenteur_marchandise: Detenteur::Vendeur,
            litige_ouvert: false,
            indemnisation_due: false,
            sanction: Sanction::Aucune,
        },
        // §7.5-2 — le vendeur refuse la reprise : le coursier garde des
        // marchandises qu'il a PAYÉES. Mefali porte la dette, tout de suite.
        T::RefusRepriseVendeur => ResolutionIssue {
            detenteur_argent: Detenteur::Mefali,
            detenteur_marchandise: Detenteur::Coursier,
            litige_ouvert: true,
            indemnisation_due: true,
            sanction: Sanction::Aucune,
        },
        // §7.5-3 — périssable : rien ne se retourne. Indemnisation, ET sanction
        // client — le seul cas où le client est sanctionné, parce que c'est le
        // seul où son refus DÉTRUIT de la valeur.
        T::RefusPerissable => ResolutionIssue {
            detenteur_argent: Detenteur::Mefali,
            detenteur_marchandise: Detenteur::Coursier,
            litige_ouvert: true,
            indemnisation_due: true,
            sanction: Sanction::PrepaiementImpose,
        },
        // §7.5-4, §7.5-5 et §7.5-9 — contestation du montant, absence
        // d'appoint, annulation après achat : « mêmes règles que le refus ».
        // La NATURE de la marchandise tranche. Le coursier ne négocie jamais :
        // refuser le montant exact, c'est refuser (prix verrouillés, III), et
        // aucun paiement partiel n'existe pour l'absence d'appoint.
        T::ContestationMontant | T::SansAppoint | T::AnnulationApresAchat => {
            if perissable {
                resoudre(T::RefusPerissable, true, preuves_completes)
            } else {
                resoudre(T::RefusNonPerissable, false, preuves_completes)
            }
        }
        // §7.5-6 — faux billet : le client est parti avec la marchandise, le
        // coursier avec du papier. Le fonds d'incidents couvre.
        T::FauxBillet => ResolutionIssue {
            detenteur_argent: Detenteur::Mefali,
            detenteur_marchandise: Detenteur::Client,
            litige_ouvert: true,
            indemnisation_due: true,
            sanction: Sanction::Aucune,
        },
        // §7.5-7 — non-conformité : faute VENDEUR. Reprise et remboursement
        // obligatoires (charte) ; la photo de collecte départage.
        T::NonConformite => ResolutionIssue {
            detenteur_argent: Detenteur::Vendeur,
            detenteur_marchandise: Detenteur::Vendeur,
            litige_ouvert: true,
            indemnisation_due: false,
            sanction: Sanction::Aucune,
        },
        // §7.5-8 — casse en transport : franchise coursier plafonnée, le
        // complément par le fonds. La marchandise reste chez le coursier —
        // cassée, mais chez lui.
        T::CasseTransport => ResolutionIssue {
            detenteur_argent: Detenteur::Mefali,
            detenteur_marchandise: Detenteur::Coursier,
            litige_ouvert: true,
            indemnisation_due: true,
            sanction: Sanction::Aucune,
        },
        // §7.5-10 — client injoignable ET vendeur fermé : consigne au local,
        // re-livraison facturée sous forme de commande LIÉE (T059).
        T::VendeurFermeConsigne => ResolutionIssue {
            detenteur_argent: Detenteur::Mefali,
            detenteur_marchandise: Detenteur::Consigne,
            litige_ouvert: false,
            indemnisation_due: true,
            sanction: Sanction::Aucune,
        },
        // §7.5-11 — suspicion de faux refus : l'indemnisation est CONDITIONNÉE
        // aux preuves in-app. Sans preuves, la marchandise reste chez le
        // coursier et le litige est ouvert, mais rien n'est versé : « le
        // coursier ne perd jamais » ne veut pas dire « on paie sans regarder ».
        T::SuspicionFauxRefus => ResolutionIssue {
            detenteur_argent: if preuves_completes {
                Detenteur::Mefali
            } else {
                Detenteur::Client
            },
            detenteur_marchandise: Detenteur::Coursier,
            litige_ouvert: true,
            indemnisation_due: preuves_completes,
            sanction: Sanction::Aucune,
        },
    }
}

/// Demande de déclaration d'échec.
#[derive(Debug, Clone)]
pub struct DemandeEchec {
    /// Livraison concernée.
    pub livraison_id: Uuid,
    /// Arrêt concerné — `None` = à la remise.
    pub arret_id: Option<Uuid>,
    /// Ligne de l'arbre §7.5.
    pub type_issue: TypeIssueEchec,
    /// Clé i18n du motif — jamais du texte libre.
    pub motif_cle: String,
}

/// Une issue enregistrée.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IssueEnregistree {
    /// Identifiant de l'issue.
    pub issue_id: Uuid,
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Ce que l'arbre a décidé.
    pub resolution: ResolutionIssue,
    /// Montant en jeu (unités mineures).
    pub montant_en_jeu_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Sanction EFFECTIVEMENT posée (rang arbitré).
    pub sanction_posee: Sanction,
    /// Commande de re-livraison créée (§7.5-10 seulement).
    pub relivraison_id: Option<Uuid>,
}

impl PgCommandes {
    /// Déclare un échec et déroule l'arbre §7.5 (CMD-08).
    ///
    /// **Refusé sans preuves** (FR-056) : tant que [`crate::PreuvesEchec`] dit
    /// non, rien n'est écrit. « Le coursier ne perd jamais » suppose une trace
    /// — sans elle, la promesse deviendrait une invitation.
    pub async fn declarer_echec(
        &self,
        acteur: Uuid,
        demande: DemandeEchec,
        maintenant: DateTime<Utc>,
    ) -> Result<IssueEnregistree, ErreurCommandes> {
        if !self.preuves.preuves_reunies(demande.livraison_id).await? {
            return Err(ErreurCommandes::PreuvesIncompletes);
        }

        let contexte = sqlx::query!(
            r#"SELECT l.commande_id, l.coursier_id, l.etat::text AS "livraison_etat!",
                      l.devis_part_coursier,
                      c.client_id, c.zone_id, c.devise, c.total_unites,
                      c.etat::text AS "etat_commande!",
                      cat.slug AS "categorie_slug!"
               FROM commandes.livraison l
               JOIN commandes.commande c ON c.id = l.commande_id
               JOIN zones.categorie cat ON cat.id = c.categorie_id
               WHERE l.id = $1"#,
            demande.livraison_id,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCommandes::LivraisonInconnue(demande.livraison_id))?;

        // La nature de la marchandise décide de la moitié de l'arbre : c'est un
        // paramètre de ZONE, jamais une liste en dur (constitution I).
        let perissable = self
            .parametre_bool(contexte.zone_id, &cle_perissable(&contexte.categorie_slug))
            .await?;
        let resolution = resoudre(demande.type_issue, perissable, true);

        // Rang de la sanction : 1ᵉʳ refus → prépaiement imposé, 2ᵉ → blocage.
        // Le rang se LIT des restrictions déjà posées, il ne se compte pas — un
        // compteur parallèle divergerait de la vérité au premier incident.
        let sanction_posee = if resolution.sanction == Sanction::Aucune {
            Sanction::Aucune
        } else if self
            .restrictions
            .restrictions(contexte.client_id)
            .await?
            .prepaiement_impose
        {
            Sanction::Bloque
        } else {
            Sanction::PrepaiementImpose
        };

        // Montant en jeu : l'avance de l'arrêt s'il est nommé, sinon le total.
        let montant_en_jeu = match demande.arret_id {
            Some(arret_id) => sqlx::query_scalar!(
                "SELECT montant_avance FROM commandes.arret WHERE id = $1",
                arret_id,
            )
            .fetch_optional(&self.pool)
            .await?
            .unwrap_or(0),
            None => contexte.total_unites,
        };

        let mut tx = self.pool.begin().await?;

        let issue_id = Uuid::now_v7();
        sqlx::query!(
            "INSERT INTO commandes.issue_echec
                 (id, commande_id, arret_id, type_issue, detenteur_argent,
                  detenteur_marchandise, montant_en_jeu_unites, devise,
                  indemnisation_due, litige_ouvert, sanction, motif_cle, acteur)
             VALUES ($1, $2, $3,
                     $4::text::commandes.type_issue_echec,
                     $5::text::commandes.detenteur,
                     $6::text::commandes.detenteur,
                     $7, $8, $9, $10,
                     $11::text::commandes.sanction,
                     $12, $13)",
            issue_id,
            contexte.commande_id,
            demande.arret_id,
            demande.type_issue.comme_str(),
            resolution.detenteur_argent.comme_str(),
            resolution.detenteur_marchandise.comme_str(),
            montant_en_jeu,
            contexte.devise,
            resolution.indemnisation_due,
            resolution.litige_ouvert,
            sanction_posee.comme_str(),
            demande.motif_cle,
            acteur,
        )
        .execute(&mut *tx)
        .await?;

        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "echec.issue_enregistree",
                entite_type: "issue_echec",
                entite_id: issue_id,
                payload: json!({
                    "commande": contexte.commande_id,
                    "arret": demande.arret_id,
                    "type_issue": demande.type_issue.comme_str(),
                    "detenteur_argent": resolution.detenteur_argent.comme_str(),
                    "detenteur_marchandise": resolution.detenteur_marchandise.comme_str(),
                    "montant_en_jeu": montant_en_jeu,
                    "devise": contexte.devise,
                    "motif_cle": demande.motif_cle,
                    "acteur": acteur,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;

        // Contrat pour AVI-04 — sans consommateur ce cycle.
        if resolution.litige_ouvert {
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "litige.ouvert",
                    entite_type: "issue_echec",
                    entite_id: issue_id,
                    payload: json!({
                        "commande": contexte.commande_id,
                        "type_issue": demande.type_issue.comme_str(),
                        "arret": demande.arret_id,
                    }),
                    survenu_le: maintenant,
                },
            )
            .await?;
        }

        // Contrat pour CRS-06 — sans consommateur ce cycle. Le montant dû = ce
        // que le coursier a avancé + sa part de devis FIGÉE : il a payé, et il
        // a roulé. Les deux lui sont dus.
        if resolution.indemnisation_due {
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "indemnisation.due",
                    entite_type: "issue_echec",
                    entite_id: issue_id,
                    payload: json!({
                        "commande": contexte.commande_id,
                        "coursier": contexte.coursier_id,
                        "montant": montant_en_jeu + contexte.devis_part_coursier,
                        "devise": contexte.devise,
                    }),
                    survenu_le: maintenant,
                },
            )
            .await?;
        }

        // La sanction vit dans le crate `comptes` (P3, R12) : CMD passe par le
        // port et n'écrit pas une ligne dans `comptes.compte`.
        if sanction_posee != Sanction::Aucune {
            self.restrictions
                .poser_restriction(
                    &mut tx,
                    contexte.client_id,
                    sanction_posee,
                    &demande.motif_cle,
                )
                .await?;
        }

        // Les deux niveaux passent ÉCHOUÉ, sous la garde de la table fermée.
        if contexte.livraison_etat == EtatLivraison::EnLivraison.comme_str() {
            self.transition_livraison(
                &mut tx,
                demande.livraison_id,
                EtatLivraison::Echouee,
                Acteur::Coursier,
                maintenant,
                None,
            )
            .await?;
        }
        if contexte.etat_commande == EtatCommande::EnCours.comme_str() {
            self.transition_commande(
                &mut tx,
                contexte.commande_id,
                EtatCommande::Echouee,
                Acteur::Coursier,
                maintenant,
                Some(NouvelEvenement {
                    type_evenement: "commande.echec_declare",
                    entite_type: "commande",
                    entite_id: contexte.commande_id,
                    payload: json!({
                        "type_issue": demande.type_issue.comme_str(),
                        // Toujours `true` : sans preuves, l'écriture n'a pas eu
                        // lieu — le refus est en amont, pas dans le payload.
                        "preuves_ok": true,
                    }),
                    survenu_le: maintenant,
                }),
            )
            .await?;
        }

        // §7.5-10 — la marchandise part en consigne : une NOUVELLE commande
        // liée porte la re-livraison, avec SON PROPRE devis (T059).
        let relivraison_id = if demande.type_issue == TypeIssueEchec::VendeurFermeConsigne {
            Some(
                self.creer_relivraison(&mut tx, contexte.commande_id, maintenant)
                    .await?,
            )
        } else {
            None
        };

        tx.commit().await?;

        Ok(IssueEnregistree {
            issue_id,
            commande_id: contexte.commande_id,
            resolution,
            montant_en_jeu_unites: montant_en_jeu,
            devise: contexte.devise,
            sanction_posee,
            relivraison_id,
        })
    }

    /// **§7.5-10 (T059)** — crée la commande de re-livraison liée.
    ///
    /// ⚠ Une **nouvelle commande**, jamais un second segment. Un second segment
    /// serait la mécanique de CMD-09 (aller-retour pressing), explicitement
    /// hors périmètre ; et surtout il partagerait le devis de la première
    /// course, alors que la re-livraison est un déplacement de PLUS, à facturer
    /// comme tel. La commande liée naît donc **sans livraison** : son devis
    /// sera évalué à sa planification, sur sa géométrie réelle — le point de
    /// départ est la consigne, plus les vendeurs.
    ///
    /// Le lien `relivraison_de` est ce qui permet à l'exploitation de lire les
    /// deux commandes comme une seule histoire.
    async fn creer_relivraison(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        origine_id: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<Uuid, ErreurCommandes> {
        let relivraison_id = Uuid::now_v7();
        let code = crate::creation::code_a_4_chiffres();
        let jeton = crate::creation::jeton_aleatoire();
        sqlx::query!(
            "INSERT INTO commandes.commande
                 (id, client_id, zone_id, categorie_id, lieu_lat, lieu_lon,
                  repere_texte, repere_vocal_cle, adresse_id,
                  montant_articles_unites, total_unites, devise,
                  mode_paiement, etat_paiement, etat,
                  code_livraison, code_livraison_hash,
                  jeton_reception, jeton_reception_hash,
                  relivraison_de)
             SELECT $1, c.client_id, c.zone_id, c.categorie_id, c.lieu_lat, c.lieu_lon,
                    c.repere_texte, c.repere_vocal_cle, c.adresse_id,
                    c.montant_articles_unites, c.montant_articles_unites, c.devise,
                    c.mode_paiement, 'du'::commandes.etat_paiement,
                    'nouvelle'::commandes.etat_commande,
                    $2, $3, $4, $5, c.id
               FROM commandes.commande c
              WHERE c.id = $6",
            relivraison_id,
            code,
            socle::empreinte_code(relivraison_id, &code),
            jeton,
            socle::empreinte_jeton(&jeton),
            origine_id,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "commande.creee",
                entite_type: "commande",
                entite_id: relivraison_id,
                payload: json!({
                    "relivraison_de": origine_id,
                    "motif": "vendeur_ferme_consigne",
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        Ok(relivraison_id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// **SC-003** — les 11 lignes du tableau §7.5, avec leurs DEUX détenteurs.
    ///
    /// Table de décision pure : aucune base, aucune fixture. Si le produit
    /// change une ligne du cadrage, c'est ici que ça casse en premier.
    #[test]
    fn les_onze_lignes_de_l_arbre() {
        use Detenteur as D;
        use TypeIssueEchec as T;

        // (type, périssable, preuves) → (argent, marchandise, litige, indemn.)
        let table: &[(TypeIssueEchec, bool, bool, Detenteur, Detenteur, bool, bool)] = &[
            (T::RefusNonPerissable, false, true, D::Vendeur, D::Vendeur, false, false),
            (T::RefusRepriseVendeur, false, true, D::Mefali, D::Coursier, true, true),
            (T::RefusPerissable, true, true, D::Mefali, D::Coursier, true, true),
            // 4 — contestation : selon la NATURE.
            (T::ContestationMontant, false, true, D::Vendeur, D::Vendeur, false, false),
            (T::ContestationMontant, true, true, D::Mefali, D::Coursier, true, true),
            // 5 — sans appoint : aucun paiement partiel, donc même issue.
            (T::SansAppoint, false, true, D::Vendeur, D::Vendeur, false, false),
            (T::FauxBillet, false, true, D::Mefali, D::Client, true, true),
            (T::NonConformite, false, true, D::Vendeur, D::Vendeur, true, false),
            (T::CasseTransport, false, true, D::Mefali, D::Coursier, true, true),
            // 9 — annulation après achat : mêmes règles que le refus.
            (T::AnnulationApresAchat, true, true, D::Mefali, D::Coursier, true, true),
            (T::VendeurFermeConsigne, false, true, D::Mefali, D::Consigne, false, true),
            // 11 — suspicion : l'indemnisation SUIT les preuves.
            (T::SuspicionFauxRefus, false, true, D::Mefali, D::Coursier, true, true),
            (T::SuspicionFauxRefus, false, false, D::Client, D::Coursier, true, false),
        ];

        for (type_issue, perissable, preuves, argent, marchandise, litige, indemn) in table {
            let r = resoudre(*type_issue, *perissable, *preuves);
            assert_eq!(
                (
                    r.detenteur_argent,
                    r.detenteur_marchandise,
                    r.litige_ouvert,
                    r.indemnisation_due
                ),
                (*argent, *marchandise, *litige, *indemn),
                "§7.5 — « {} » (périssable={perissable}, preuves={preuves})",
                type_issue.comme_str(),
            );
        }
    }

    /// Le SEUL cas qui sanctionne le client est le refus d'une marchandise
    /// PÉRISSABLE — le seul où son refus détruit de la valeur.
    #[test]
    fn seule_la_marchandise_perissable_sanctionne_le_client() {
        use TypeIssueEchec as T;
        for type_issue in [
            T::RefusNonPerissable,
            T::RefusRepriseVendeur,
            T::FauxBillet,
            T::NonConformite,
            T::CasseTransport,
            T::VendeurFermeConsigne,
            T::SuspicionFauxRefus,
        ] {
            assert_eq!(
                resoudre(type_issue, false, true).sanction,
                Sanction::Aucune,
                "« {} » ne doit sanctionner personne",
                type_issue.comme_str(),
            );
        }
        assert_eq!(
            resoudre(T::RefusPerissable, true, true).sanction,
            Sanction::PrepaiementImpose,
        );
        // Et par propagation, la contestation d'un plat chaud aussi.
        assert_eq!(
            resoudre(T::ContestationMontant, true, true).sanction,
            Sanction::PrepaiementImpose,
        );
    }

    /// Les deux axes sont INDÉPENDANTS (R14) : au moins une ligne où l'argent
    /// et la marchandise sont chez deux personnes différentes — sans quoi une
    /// seule colonne aurait suffi, et le modèle serait faux.
    #[test]
    fn les_deux_detenteurs_sont_bien_independants() {
        let r = resoudre(TypeIssueEchec::FauxBillet, false, true);
        assert_ne!(r.detenteur_argent, r.detenteur_marchandise);
        let r = resoudre(TypeIssueEchec::RefusPerissable, true, true);
        assert_ne!(r.detenteur_argent, r.detenteur_marchandise);
    }
}
