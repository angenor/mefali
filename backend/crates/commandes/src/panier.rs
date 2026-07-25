//! Panier multi-vendeurs : regroupement par vendeur, règle de mixage,
//! proposition de scission (CMD-01, research R8/R9).
//!
//! **Aucune table serveur** : le panier est un brouillon local (drift côté app).
//! L'API expose un devis **sans effet de bord** — rien n'est engagé tant que la
//! commande n'existe pas. Ce module ne porte donc que des types et des règles
//! pures ; les écritures vivent dans [`crate::creation`].

use uuid::Uuid;

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
        self.lignes.iter().map(|l| i32::from(l.ligne.quantite)).sum()
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

    #[test]
    fn preference_par_defaut_est_m_appeler() {
        assert_eq!(
            PreferenceSubstitution::default(),
            PreferenceSubstitution::Appeler,
            "le seul choix qui ne décide rien à la place du client (CMD-01)",
        );
    }
}
