//! Panier multi-vendeurs : regroupement par vendeur, règle de mixage,
//! proposition de scission (CMD-01, research R8/R9).
//!
//! **Aucune table serveur** : le panier est un brouillon local (drift côté app).
//! L'API expose un devis **sans effet de bord** — rien n'est engagé tant que la
//! commande n'existe pas. Ce module ne porte donc que des types et des règles
//! pures ; les écritures vivent dans [`crate::creation`].

use std::collections::HashMap;

use uuid::Uuid;
use zones::ConfigurationZones;

use crate::depot::PgCommandes;
use crate::modele::{ErreurCommandes, PreferenceSubstitution};

/// Une ligne telle que le client la soumet.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LignePanier {
    /// Vendeur chez qui l'article est pris.
    pub prestataire_id: Uuid,
    /// Article demandé.
    pub article_id: Uuid,
    /// Quantité (> 0).
    pub quantite: i16,
    /// Que faire si l'article manque (défaut « m'appeler »).
    pub preference: PreferenceSubstitution,
}

/// Une ligne RÉSOLUE contre le catalogue : nom et prix courants connus.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LigneValidee {
    /// La ligne soumise.
    pub ligne: LignePanier,
    /// Nom de l'article (affichage — jamais journalisé dans l'outbox).
    pub nom: String,
    /// Prix unitaire COURANT, entier en unités mineures (III).
    pub prix_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
}

impl LigneValidee {
    /// Sous-total de la ligne : prix unitaire × quantité, en entiers.
    pub fn sous_total_unites(&self) -> i64 {
        self.prix_unites * i64::from(self.ligne.quantite)
    }
}

/// Les lignes d'un même vendeur, regroupées (maquette C3-3a).
#[derive(Debug, Clone, PartialEq)]
pub struct GroupeVendeur {
    /// Vendeur.
    pub prestataire_id: Uuid,
    /// Nom affiché sur la carte vendeur.
    pub nom: String,
    /// Position du SITE du vendeur — point de retrait de la course.
    pub site_lat: f64,
    /// Position du site du vendeur.
    pub site_lon: f64,
    /// Lignes du vendeur, dans l'ordre de soumission.
    pub lignes: Vec<LigneValidee>,
}

impl GroupeVendeur {
    /// Nombre d'articles du groupe (quantités cumulées).
    pub fn nb_articles(&self) -> i32 {
        self.lignes
            .iter()
            .map(|l| i32::from(l.ligne.quantite))
            .sum()
    }

    /// Sous-total du vendeur, en unités mineures.
    pub fn sous_total_unites(&self) -> i64 {
        self.lignes.iter().map(|l| l.sous_total_unites()).sum()
    }
}

/// Un panier validé : catégorie résolue, lignes regroupées par vendeur,
/// montants calculés. Passé aux gardes de vertical (`ServiceWorkflow`).
#[derive(Debug, Clone, PartialEq)]
pub struct PanierValide {
    /// Zone de la commande (résout mixable, plafonds, devise).
    pub zone_id: Uuid,
    /// Catégorie de service.
    pub categorie_id: Uuid,
    /// Slug de la catégorie (`restauration`, `marche`…).
    pub categorie_slug: String,
    /// La catégorie accepte-t-elle d'être mêlée à d'autres au panier ?
    pub mixable: bool,
    /// Groupes, un par vendeur.
    pub groupes: Vec<GroupeVendeur>,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
}

impl PanierValide {
    /// Montant des ARTICLES seuls (les frais vivent sur la livraison, R3).
    pub fn montant_articles_unites(&self) -> i64 {
        self.groupes.iter().map(|g| g.sous_total_unites()).sum()
    }

    /// Nombre total d'articles (paliers d'effort TRF-06).
    pub fn nb_articles(&self) -> i32 {
        self.groupes.iter().map(|g| g.nb_articles()).sum()
    }

    /// Nombre de vendeurs distincts.
    pub fn nb_vendeurs(&self) -> usize {
        self.groupes.len()
    }

    /// Condition NÉCESSAIRE de l'offre de livraison vendeur VND-08 (FR-014).
    pub fn mono_vendeur(&self) -> bool {
        self.groupes.len() == 1
    }

    /// Toutes les lignes, tous vendeurs confondus, dans l'ordre des groupes.
    pub fn lignes(&self) -> impl Iterator<Item = &LigneValidee> {
        self.groupes.iter().flat_map(|g| g.lignes.iter())
    }
}

/// Détails propres au vertical, à insérer à la création (`resto_details`…).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DetailsVertical {
    /// Délai de préparation annoncé, copié du prestataire (restauration).
    pub delai_preparation_min: Option<i16>,
}

/// Cause d'une proposition de scission. Les deux causes produisent la MÊME
/// action utilisateur et le même écran (C3-3d) — d'où une seule surface
/// (research R9).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CauseScission {
    /// La catégorie soumise n'est pas `mixable` (FR-009).
    CategorieNonMixable,
    /// Le détour dépasse le plafond d'éclatement de la zone (drapeau du devis).
    PlafondEclatement,
}

impl CauseScission {
    /// Représentation textuelle (payload `panier.scission_proposee`).
    pub fn comme_str(self) -> &'static str {
        match self {
            CauseScission::CategorieNonMixable => "categorie_non_mixable",
            CauseScission::PlafondEclatement => "plafond_eclatement",
        }
    }

    /// Clé i18n fr du message affiché (VII — jamais de texte en dur).
    pub fn message_cle(self) -> &'static str {
        match self {
            CauseScission::CategorieNonMixable => "panier.scission.categorie_non_mixable",
            CauseScission::PlafondEclatement => "panier.scission.plafond_eclatement",
        }
    }
}

/// Une commande telle qu'elle sortirait de la scission : ses lignes et son
/// total d'articles ESTIMÉ (les frais de chaque commande résultante ne sont
/// connus qu'après un nouveau devis — le client en verra deux).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CommandeProposee {
    /// Clé i18n du libellé (« Le repas », « Les courses »).
    pub libelle_cle: String,
    /// Lignes qui composeraient cette commande.
    pub lignes: Vec<LignePanier>,
    /// Total des ARTICLES de cette commande (unités mineures).
    pub total_articles_unites: i64,
}

/// Proposition de scission — **une seule surface pour les deux causes**
/// (research R9). Le serveur ne scinde JAMAIS d'office (FR-010) : il propose,
/// le client renvoie N créations indépendantes s'il accepte.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PropositionScission {
    /// Ce qui a déclenché la proposition.
    pub cause: CauseScission,
    /// Clé i18n du message affiché.
    pub message_cle: String,
    /// Prévisualisation CHIFFRÉE des commandes résultantes.
    pub commandes_proposees: Vec<CommandeProposee>,
}

/// Valide la FORME d'un panier soumis, avant toute résolution de catalogue.
///
/// Ne regarde ni les prix, ni la disponibilité : uniquement ce qui rend le
/// panier structurellement inexploitable.
pub fn valider_forme(lignes: &[LignePanier]) -> Result<(), ErreurCommandes> {
    if lignes.is_empty() {
        return Err(ErreurCommandes::PanierInvalide("panier vide".to_owned()));
    }
    if lignes.iter().any(|l| l.quantite <= 0) {
        return Err(ErreurCommandes::PanierInvalide(
            "quantité nulle ou négative".to_owned(),
        ));
    }
    Ok(())
}

/// Construit la proposition de scission d'un panier, ou `None` s'il n'y a rien
/// à proposer.
///
/// Les **deux causes** produisent la même action utilisateur et le même écran
/// (C3-3d) : les fusionner évite deux chemins d'UI divergents, et évite surtout
/// qu'un panier à la fois mixte ET dispersé affiche deux bandeaux
/// contradictoires (research R9).
///
/// - `categorie_non_mixable` : le panier porte plusieurs vendeurs alors que la
///   catégorie refuse d'être mêlée → un vendeur par commande ;
/// - `plafond_eclatement` : le détour dépasse le plafond de zone (drapeau
///   `proposer_scission` du devis, décidé par TRF) → le panier est coupé en
///   deux moitiés de vendeurs.
///
/// La cause « non mixable » l'emporte : c'est un REFUS de création, l'autre
/// n'est qu'un conseil.
pub fn proposer_scission(
    panier: &PanierValide,
    proposer_pour_eclatement: bool,
) -> Option<PropositionScission> {
    let cause = if !panier.mixable && !panier.mono_vendeur() {
        CauseScission::CategorieNonMixable
    } else if proposer_pour_eclatement && !panier.mono_vendeur() {
        CauseScission::PlafondEclatement
    } else {
        return None;
    };

    let commandes_proposees = match cause {
        // Un vendeur = une commande : c'est la seule découpe qui lève le refus.
        CauseScission::CategorieNonMixable => panier
            .groupes
            .iter()
            .map(|g| CommandeProposee {
                libelle_cle: "panier.scission.par_vendeur".to_owned(),
                lignes: g.lignes.iter().map(|l| l.ligne.clone()).collect(),
                total_articles_unites: g.sous_total_unites(),
            })
            .collect(),
        // Deux tournées plus courtes : la coupe se fait sur les vendeurs, dans
        // l'ordre où le client les a composés — le serveur ne réorganise rien.
        CauseScission::PlafondEclatement => {
            let milieu = panier.groupes.len().div_ceil(2);
            panier
                .groupes
                .chunks(milieu)
                .map(|part| CommandeProposee {
                    libelle_cle: "panier.scission.par_tournee".to_owned(),
                    lignes: part
                        .iter()
                        .flat_map(|g| g.lignes.iter().map(|l| l.ligne.clone()))
                        .collect(),
                    total_articles_unites: part.iter().map(|g| g.sous_total_unites()).sum(),
                })
                .collect()
        }
    };

    Some(PropositionScission {
        cause,
        message_cle: cause.message_cle().to_owned(),
        commandes_proposees,
    })
}

impl PgCommandes {
    /// Résout un panier soumis contre la base : catégorie, règle de mixage,
    /// catalogue de chaque vendeur, position de son site.
    ///
    /// **Aucune écriture, aucun événement** (P4) : c'est une lecture pure, que
    /// le devis de panier ET la création partagent — le prix annoncé au panier
    /// et le prix verrouillé à la confirmation sortent donc du même code.
    ///
    /// Refuse (`vendeur_indisponible` / `article_indisponible`) dès qu'un
    /// vendeur n'est pas commandable ou qu'un article a disparu du catalogue :
    /// mieux vaut un refus au panier qu'un coursier devant un rideau fermé.
    pub async fn resoudre_panier(
        &self,
        zone_id: Uuid,
        categorie_slug: &str,
        lignes: &[LignePanier],
    ) -> Result<PanierValide, ErreurCommandes> {
        valider_forme(lignes)?;

        // Catégorie ACTIVE dans la zone + son `mixable` résolu par héritage
        // (constitution I : jamais en dur).
        let categories = self.zones.categories_actives(zone_id).await?;
        let categorie = categories
            .iter()
            .find(|c| c.slug == categorie_slug)
            .ok_or_else(|| {
                ErreurCommandes::PanierInvalide(format!(
                    "catégorie « {categorie_slug} » inactive dans cette zone"
                ))
            })?;
        let categorie_id = self.categorie_id(categorie_slug).await?;
        let devise = self.zones.devise(zone_id).await?.code;

        // Ordre de PREMIÈRE APPARITION des vendeurs : le regroupement suit la
        // composition du client, il ne la réorganise pas (maquette C3-3a).
        let mut ordre_vendeurs: Vec<Uuid> = Vec::new();
        for l in lignes {
            if !ordre_vendeurs.contains(&l.prestataire_id) {
                ordre_vendeurs.push(l.prestataire_id);
            }
        }

        let mut groupes = Vec::with_capacity(ordre_vendeurs.len());
        for prestataire_id in ordre_vendeurs {
            let point = self
                .prestataires
                .point_de_retrait(prestataire_id)
                .await?
                .ok_or(ErreurCommandes::VendeurIndisponible(prestataire_id))?;
            // `articles_commandables_de` rend une liste VIDE si le vendeur n'est
            // pas commandable (agréé ∧ catégorie active ∧ boutique ouverte).
            let catalogue: HashMap<Uuid, prestataires::ArticleCommandable> = self
                .prestataires
                .articles_commandables_de(prestataire_id)
                .await?
                .into_iter()
                .map(|a| (a.id, a))
                .collect();
            if catalogue.is_empty() {
                return Err(ErreurCommandes::VendeurIndisponible(prestataire_id));
            }

            let mut lignes_du_vendeur = Vec::new();
            for l in lignes.iter().filter(|l| l.prestataire_id == prestataire_id) {
                let article = catalogue
                    .get(&l.article_id)
                    .ok_or(ErreurCommandes::ArticleIndisponible(l.article_id))?;
                lignes_du_vendeur.push(LigneValidee {
                    ligne: l.clone(),
                    nom: article.nom.clone(),
                    prix_unites: article.prix_unites,
                    devise: article.devise.clone(),
                });
            }

            groupes.push(GroupeVendeur {
                prestataire_id,
                nom: point.nom,
                site_lat: point.lat,
                site_lon: point.lon,
                lignes: lignes_du_vendeur,
            });
        }

        Ok(PanierValide {
            zone_id,
            categorie_id,
            categorie_slug: categorie_slug.to_owned(),
            mixable: categorie.mixable,
            groupes,
            devise,
        })
    }

    /// Construit la **géométrie** de la course : un point de retrait par
    /// vendeur du panier (position de son SITE), et le lieu de prestation
    /// fourni par le client comme destination.
    ///
    /// Partagée par le devis de panier et par la création (T026) : le devis
    /// annoncé et le devis figé portent ainsi sur la MÊME géométrie — sans
    /// quoi le client paierait autre chose que ce qu'on lui a montré.
    pub(crate) fn geometrie(
        panier: &PanierValide,
        lieu: (f64, f64),
    ) -> (Vec<tarification::Point>, tarification::Point) {
        let retraits = panier
            .groupes
            .iter()
            .map(|g| tarification::Point {
                lat: g.site_lat,
                lon: g.site_lon,
            })
            .collect();
        let client = tarification::Point {
            lat: lieu.0,
            lon: lieu.1,
        };
        (retraits, client)
    }

    /// Évalue un panier : ordre des arrêts + devis figé, sur la géométrie
    /// ci-dessus. **Aucune écriture, aucun événement** (P4).
    ///
    /// `mono_vendeur` est renseigné ici : c'est la condition NÉCESSAIRE qui
    /// active l'offre de livraison vendeur VND-08 côté tarification (FR-014).
    /// L'oublier ferait payer au client une livraison que le vendeur offrait.
    pub async fn evaluer_panier(
        &self,
        panier: &PanierValide,
        lieu: (f64, f64),
        transport_slug: &str,
        instant: chrono::DateTime<chrono::Utc>,
    ) -> Result<tarification::Devis, ErreurCommandes> {
        let (retraits, client) = Self::geometrie(panier, lieu);
        let itineraire = self
            .optimisation
            .optimiser(panier.zone_id, &retraits, client)
            .await?;

        // VND-08 (cycle 011, T054) : l'offre du SEUL vendeur du panier est lue
        // ici et transmise telle quelle. Multi-vendeurs → aucune lecture : la
        // question n'a pas de réponse (à qui la retenue s'appliquerait-elle ?),
        // et `mono_vendeur: false` la refermerait de toute façon côté
        // tarification. L'arbitrage avec le drapeau de zone reste entier dans
        // `tarification` (research R9, R10) — le lire deux fois créerait une
        // seconde vérité tarifaire.
        let offre_livraison_vendeur = match panier.groupes.as_slice() {
            [groupe] => {
                self.prestataires
                    .offre_livraison(groupe.prestataire_id)
                    .await?
            }
            _ => None,
        };
        // Les retraits partent dans l'ORDRE OPTIMISÉ : l'évaluation tarifie le
        // trajet réellement parcouru, pas l'ordre de composition du panier.
        let retraits_ordonnes: Vec<tarification::Point> =
            itineraire.ordre.iter().map(|&i| retraits[i]).collect();

        let devis = self
            .evaluation
            .evaluer(
                tarification::DemandeDevis {
                    zone_id: panier.zone_id,
                    transport_slug: transport_slug.to_owned(),
                    retraits: retraits_ordonnes,
                    client,
                    nb_articles: panier.nb_articles(),
                    instant,
                    categorie_slug: Some(panier.categorie_slug.clone()),
                    attentes: Vec::new(),
                    montant_panier: panier.montant_articles_unites(),
                    // VND-08 : l'offre du vendeur est ARBITRÉE par TRF ; CMD
                    // n'en décide pas, il fournit la déclaration du vendeur et
                    // la condition nécessaire (mono-vendeur).
                    offre_livraison_vendeur,
                    mono_vendeur: panier.mono_vendeur(),
                },
                tarification::SourceGrille::EnVigueur,
            )
            .await?;
        Ok(devis)
    }

    /// Journalise `panier.scission_proposee` — **métrique SC-006**.
    ///
    /// ⚠ Seule écriture que le chemin du devis puisse produire, et uniquement
    /// quand une proposition est réellement FORMULÉE : le devis nominal reste
    /// strictement muet (P4). Sans cet événement, « combien de paniers mixtes
    /// se forment ? » ne serait mesurable nulle part — or c'est précisément ce
    /// que SC-006 demande de suivre.
    ///
    /// `entite_id` = le CLIENT : aucun panier n'existe côté serveur, c'est la
    /// seule entité durable en jeu (research R8).
    pub async fn journaliser_scission_proposee(
        &self,
        client_id: Uuid,
        panier: &PanierValide,
        cause: CauseScission,
        nb_commandes: usize,
    ) -> Result<(), ErreurCommandes> {
        let mut tx = self.pool.begin().await?;
        socle::ecrire_evenement(
            &mut tx,
            socle::NouvelEvenement {
                type_evenement: "panier.scission_proposee",
                entite_type: "commande",
                entite_id: client_id,
                payload: serde_json::json!({
                    "zone": panier.zone_id,
                    "categorie": panier.categorie_slug,
                    "cause": cause.comme_str(),
                    "nb_commandes": nb_commandes,
                }),
                survenu_le: chrono::Utc::now(),
            },
        )
        .await?;
        tx.commit().await?;
        Ok(())
    }

    /// Identifiant de la catégorie de service par son slug.
    pub(crate) async fn categorie_id(&self, slug: &str) -> Result<Uuid, ErreurCommandes> {
        sqlx::query_scalar!("SELECT id FROM zones.categorie WHERE slug = $1", slug)
            .fetch_optional(&self.pool)
            .await?
            .ok_or_else(|| ErreurCommandes::PanierInvalide(format!("catégorie inconnue : {slug}")))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ligne(presta: Uuid, prix: i64, quantite: i16) -> LigneValidee {
        LigneValidee {
            ligne: LignePanier {
                prestataire_id: presta,
                article_id: Uuid::now_v7(),
                quantite,
                preference: PreferenceSubstitution::default(),
            },
            nom: "Article".to_owned(),
            prix_unites: prix,
            devise: "XOF".to_owned(),
        }
    }

    fn groupe(presta: Uuid, lignes: Vec<LigneValidee>) -> GroupeVendeur {
        GroupeVendeur {
            prestataire_id: presta,
            nom: "Étal".to_owned(),
            site_lat: 5.898,
            site_lon: -4.823,
            lignes,
        }
    }

    #[test]
    fn montants_en_entiers_et_mono_vendeur() {
        let a = Uuid::now_v7();
        let b = Uuid::now_v7();
        let panier = PanierValide {
            zone_id: Uuid::now_v7(),
            categorie_id: Uuid::now_v7(),
            categorie_slug: "marche".to_owned(),
            mixable: true,
            groupes: vec![
                groupe(a, vec![ligne(a, 500, 2), ligne(a, 250, 1)]),
                groupe(b, vec![ligne(b, 1_000, 3)]),
            ],
            devise: "XOF".to_owned(),
        };
        assert_eq!(panier.groupes[0].sous_total_unites(), 1_250);
        assert_eq!(panier.groupes[1].sous_total_unites(), 3_000);
        assert_eq!(panier.montant_articles_unites(), 4_250);
        assert_eq!(panier.nb_articles(), 6);
        assert_eq!(panier.nb_vendeurs(), 2);
        assert!(!panier.mono_vendeur(), "VND-08 exige UN seul vendeur");
    }

    #[test]
    fn forme_refusee_si_vide_ou_quantite_nulle() {
        assert!(valider_forme(&[]).is_err());
        let l = LignePanier {
            prestataire_id: Uuid::now_v7(),
            article_id: Uuid::now_v7(),
            quantite: 0,
            preference: PreferenceSubstitution::default(),
        };
        assert!(valider_forme(&[l]).is_err());
    }

    fn panier_de(nb_vendeurs: usize, mixable: bool) -> PanierValide {
        let groupes = (0..nb_vendeurs)
            .map(|i| {
                let p = Uuid::now_v7();
                groupe(p, vec![ligne(p, 1_000 * (i as i64 + 1), 1)])
            })
            .collect();
        PanierValide {
            zone_id: Uuid::now_v7(),
            categorie_id: Uuid::now_v7(),
            categorie_slug: if mixable { "marche" } else { "restauration" }.to_owned(),
            mixable,
            groupes,
            devise: "XOF".to_owned(),
        }
    }

    #[test]
    fn categorie_non_mixable_propose_une_commande_par_vendeur() {
        let panier = panier_de(3, false);
        let scission = proposer_scission(&panier, false).expect("proposition attendue");
        assert_eq!(scission.cause, CauseScission::CategorieNonMixable);
        assert_eq!(scission.commandes_proposees.len(), 3);
        // La prévisualisation est CHIFFRÉE : la somme des commandes proposées
        // vaut le panier d'origine, au FCFA près.
        let somme: i64 = scission
            .commandes_proposees
            .iter()
            .map(|c| c.total_articles_unites)
            .sum();
        assert_eq!(somme, panier.montant_articles_unites());
    }

    #[test]
    fn plafond_eclatement_propose_deux_tournees() {
        let panier = panier_de(4, true);
        let scission = proposer_scission(&panier, true).expect("proposition attendue");
        assert_eq!(scission.cause, CauseScission::PlafondEclatement);
        assert_eq!(
            scission.commandes_proposees.len(),
            2,
            "deux tournées plus courtes, pas une commande par vendeur",
        );
        let somme: i64 = scission
            .commandes_proposees
            .iter()
            .map(|c| c.total_articles_unites)
            .sum();
        assert_eq!(somme, panier.montant_articles_unites());
    }

    #[test]
    fn une_seule_proposition_meme_quand_les_deux_causes_tiennent() {
        // Panier à la fois NON MIXABLE et dispersé : une seule proposition, et
        // c'est le REFUS qui l'emporte — l'autre cause n'est qu'un conseil.
        let panier = panier_de(3, false);
        let scission = proposer_scission(&panier, true).expect("proposition attendue");
        assert_eq!(
            scission.cause,
            CauseScission::CategorieNonMixable,
            "jamais deux bandeaux contradictoires (research R9)",
        );
    }

    #[test]
    fn aucune_proposition_quand_rien_ne_la_justifie() {
        // Mono-vendeur : ni le mixage ni l'éclatement n'ont de sens.
        assert!(proposer_scission(&panier_de(1, false), true).is_none());
        assert!(proposer_scission(&panier_de(1, true), true).is_none());
        // Multi-vendeurs mixable et compact : rien à proposer.
        assert!(proposer_scission(&panier_de(3, true), false).is_none());
    }

    #[test]
    fn preference_par_defaut_est_m_appeler() {
        assert_eq!(
            PreferenceSubstitution::default(),
            PreferenceSubstitution::Appeler,
            "le seul choix qui ne décide rien à la place du client (CMD-01)",
        );
    }
}
