//! Verticaux de service derrière le trait [`ServiceWorkflow`] (constitution II).
//!
//! **Aucune spécificité de vertical ne vit hors de ce module.** Le tronc ne
//! connaît ni « plat », ni « délai de préparation », ni « étal » : il ne connaît
//! qu'un `ServiceWorkflow` qui valide et qui, éventuellement, produit des
//! détails à ranger dans SA table (`resto_details`).
//!
//! Deux verticaux au MVP :
//!
//! | Vertical | Vendeurs | Table de détails |
//! |---|---|---|
//! | [`RestaurationWorkflow`] | **un seul** (catégorie non mixable) | `resto_details` |
//! | [`CoursesWorkflow`] | 1..n | aucune |
//!
//! Un artisan de phase N sera un troisième `ServiceWorkflow` — sans migration du
//! tronc, sans toucher à la création.

use crate::modele::ErreurCommandes;
use crate::panier::{DetailsVertical, PanierValide};

/// Vertical de service. Toute règle propre à un métier passe par là.
pub trait ServiceWorkflow: Send + Sync {
    /// Slug du vertical.
    fn slug(&self) -> &'static str;

    /// Garde propre au vertical, appliquée **AVANT** toute écriture.
    fn valider_creation(&self, panier: &PanierValide) -> Result<(), ErreurCommandes>;

    /// Détails à insérer dans la table du vertical ; `None` s'il n'en a pas.
    fn details(&self, panier: &PanierValide) -> Option<DetailsVertical>;
}

/// **Restauration** — un plat préparé se commande chez UN vendeur.
///
/// La garde mono-vendeur n'est pas une préférence d'implémentation : mêler un
/// plat chaud à une tournée de marché fait arriver le plat froid, et la
/// catégorie est seedée `mixable = false` précisément pour cela (FR-009).
///
/// ⚠ Les colonnes `acceptee_le` et `refus_motif_cle` de `resto_details` sont des
/// **PROVISIONS** de l'app vendeur (VAP, tranche T4) : aucune logique
/// d'acceptation ni de timeout n'est écrite ce cycle — « prêt ≠ construit »
/// (constitution IX).
#[derive(Debug, Clone, Copy, Default)]
pub struct RestaurationWorkflow {
    /// Délai de préparation annoncé par le vendeur, copié à la création.
    delai_preparation_min: Option<i16>,
}

impl RestaurationWorkflow {
    /// Vertical restauration, avec le délai de préparation du vendeur.
    pub fn nouveau(delai_preparation_min: Option<i16>) -> Self {
        Self {
            delai_preparation_min,
        }
    }
}

impl ServiceWorkflow for RestaurationWorkflow {
    fn slug(&self) -> &'static str {
        "restauration"
    }

    fn valider_creation(&self, panier: &PanierValide) -> Result<(), ErreurCommandes> {
        if !panier.mono_vendeur() {
            return Err(ErreurCommandes::CategorieNonMixable);
        }
        Ok(())
    }

    fn details(&self, _panier: &PanierValide) -> Option<DetailsVertical> {
        Some(DetailsVertical {
            delai_preparation_min: self.delai_preparation_min,
        })
    }
}

/// **Courses** — marché, boutique, pharmacie, gaz, quincaillerie.
///
/// Multi-vendeurs natif : c'est précisément ce que le panier de CMD-01 sert.
/// Aucune table de détails — rien de spécifique à ranger.
#[derive(Debug, Clone, Copy, Default)]
pub struct CoursesWorkflow;

impl ServiceWorkflow for CoursesWorkflow {
    fn slug(&self) -> &'static str {
        "courses"
    }

    fn valider_creation(&self, _panier: &PanierValide) -> Result<(), ErreurCommandes> {
        // Aucune garde propre : la règle de mixage est portée par la
        // configuration de zone (`categorie.<slug>.mixable`), pas par le code.
        Ok(())
    }

    fn details(&self, _panier: &PanierValide) -> Option<DetailsVertical> {
        None
    }
}

/// Choisit le vertical d'une catégorie. La restauration est le seul vertical
/// spécialisé du MVP ; toutes les autres catégories sont des **courses**.
///
/// `delai_preparation_min` n'est lu que par la restauration.
pub fn pour_categorie(
    categorie_slug: &str,
    delai_preparation_min: Option<i16>,
) -> Box<dyn ServiceWorkflow> {
    match categorie_slug {
        "restauration" => Box::new(RestaurationWorkflow::nouveau(delai_preparation_min)),
        _ => Box::new(CoursesWorkflow),
    }
}

#[cfg(test)]
mod tests {
    use uuid::Uuid;

    use super::*;
    use crate::modele::PreferenceSubstitution;
    use crate::panier::{GroupeVendeur, LignePanier, LigneValidee};

    fn panier(nb_vendeurs: usize, slug: &str) -> PanierValide {
        let groupes = (0..nb_vendeurs)
            .map(|_| {
                let presta = Uuid::now_v7();
                GroupeVendeur {
                    prestataire_id: presta,
                    nom: "Vendeur".to_owned(),
                    site_lat: 5.898,
                    site_lon: -4.823,
                    lignes: vec![LigneValidee {
                        ligne: LignePanier {
                            prestataire_id: presta,
                            article_id: Uuid::now_v7(),
                            quantite: 1,
                            preference: PreferenceSubstitution::default(),
                        },
                        nom: "Article".to_owned(),
                        prix_unites: 1_000,
                        devise: "XOF".to_owned(),
                    }],
                }
            })
            .collect();
        PanierValide {
            zone_id: Uuid::now_v7(),
            categorie_id: Uuid::now_v7(),
            categorie_slug: slug.to_owned(),
            mixable: slug != "restauration",
            groupes,
            devise: "XOF".to_owned(),
        }
    }

    #[test]
    fn restauration_refuse_le_multi_vendeurs() {
        let w = RestaurationWorkflow::nouveau(Some(20));
        w.valider_creation(&panier(1, "restauration"))
            .expect("un seul vendeur : accepté");
        let e = w
            .valider_creation(&panier(3, "restauration"))
            .expect_err("trois vendeurs : refusé");
        assert_eq!(e.message_cle(), Some("categorie_non_mixable"));
    }

    #[test]
    fn restauration_produit_ses_details_courses_non() {
        let resto = RestaurationWorkflow::nouveau(Some(25));
        assert_eq!(
            resto
                .details(&panier(1, "restauration"))
                .unwrap()
                .delai_preparation_min,
            Some(25),
        );
        assert!(
            CoursesWorkflow.details(&panier(3, "marche")).is_none(),
            "les courses n'ont aucune table de détails",
        );
    }

    #[test]
    fn courses_acceptent_le_multi_vendeurs() {
        CoursesWorkflow
            .valider_creation(&panier(3, "marche"))
            .expect("le panier multi-vendeurs est NATIF pour les courses");
    }

    #[test]
    fn resolution_du_vertical_par_categorie() {
        assert_eq!(
            pour_categorie("restauration", Some(20)).slug(),
            "restauration"
        );
        for slug in [
            "marche",
            "boutique_superette",
            "pharmacie",
            "gaz",
            "quincaillerie",
        ] {
            assert_eq!(pour_categorie(slug, None).slug(), "courses");
        }
    }
}
