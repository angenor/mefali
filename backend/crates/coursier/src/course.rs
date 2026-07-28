//! Composition de la course active — le cœur du pré-provisionnement (FR-011).
//!
//! Trois domaines s'assemblent ici, et **un seul aller-retour** doit suffire à
//! faire fonctionner toute la course hors ligne (FR-028) :
//!
//! | Source | Ce qu'elle apporte |
//! |---|---|
//! | `commandes::CourseCoursier` | arrêts, lignes, client, empreintes de remise, montant |
//! | `qr` (via `prestataires::contexte_plaque`) | empreintes de plaque, politique photo, rayon de scan |
//! | `prestataires` | nom et **contact** du vendeur (élargissement documenté, R6) |
//! | `zones` | les seuils de preuve de la zone |
//!
//! Le montant servi par arrêt est celui des **lignes**, pas la colonne
//! `montant_avance` : celle-ci est périmée dès qu'une ligne est retirée, et
//! c'est la somme qui fait baisser l'affichage tout de suite (FR-013, SC-002).

use std::collections::HashMap;

use chrono::Utc;
use commandes::CourseCoursier;
use uuid::Uuid;

use crate::config::ConfigCoursier;
use crate::depot::PgCoursier;
use crate::modele::{
    ArretComplet, ClientCourse, CourseComplete, ErreurCoursier, LigneArret, RemisePreprovisionnee,
};

/// Durée de vie de l'URL présignée du repère vocal.
///
/// Volontairement COURTE : l'app la télécharge immédiatement pour jouer la note
/// hors ligne (FR-024) ; une URL qui traînerait dix minutes dans un journal
/// serait dix minutes d'accès à la voix d'une cliente. Patron du cycle 003.
const PRESIGNEE_TTL: std::time::Duration = std::time::Duration::from_secs(10 * 60);

impl PgCoursier {
    /// La course active complète d'un coursier, ou `None` s'il n'en a aucune.
    ///
    /// ⚠ Cette structure ne sort **qu'après assignation** (FR-104) et n'est
    /// servie qu'au coursier assigné : c'est la lecture elle-même qui filtre
    /// par `coursier_id`, aucune garde n'est ajoutée après coup.
    pub async fn course_active(
        &self,
        coursier: Uuid,
    ) -> Result<Option<CourseComplete>, ErreurCoursier> {
        let Some(course) = CourseCoursier::course_active(&self.commandes, coursier).await? else {
            return Ok(None);
        };
        let config = ConfigCoursier::charger(&self.zones, course.zone_id).await?;

        // Contacts des vendeurs de la course, en UNE lecture. Le coursier est
        // assigné — c'est la course elle-même qui le prouve.
        let prestataires: Vec<Uuid> = course.arrets.iter().map(|a| a.prestataire_id).collect();
        let contacts: HashMap<Uuid, prestataires::ContactVendeur> = self
            .prestataires
            .contacts_vendeurs(&prestataires)
            .await?
            .into_iter()
            .map(|c| (c.prestataire_id, c))
            .collect();

        // Plaques résolues, une lecture par prestataire. Un prestataire sans
        // plaque (jamais agréé) n'a pas d'entrée : son arrêt sera servi SANS
        // empreintes plutôt que masqué — le masquer ferait disparaître une
        // étape que Yao doit tout de même faire.
        let mut plaques: HashMap<Uuid, qr::PlaqueResolue> = HashMap::new();
        for a in &course.arrets {
            if let Some(p) = self.qr.plaque_resolue(a.prestataire_id, a.montant_avance).await? {
                plaques.insert(a.prestataire_id, p);
            }
        }

        // Note vocale : URL PRÉSIGNÉE de courte durée, jamais la clé objet. Si
        // le stockage est indisponible, la course part SANS la note plutôt que
        // d'échouer : le repère écrit suffit à livrer, une course bloquée par un
        // objet manquant ne le suffit pas.
        let repere_vocal_url = match &course.client.repere_vocal_cle {
            Some(cle) => match self.objets.presigner_get(cle, PRESIGNEE_TTL).await {
                Ok(url) => Some(url.url),
                Err(e) => {
                    tracing::warn!(
                        erreur = %e,
                        livraison = %course.livraison_id,
                        "repère vocal non présignable — la course est servie sans lui"
                    );
                    None
                }
            },
            None => None,
        };

        Ok(Some(composer(
            course,
            &plaques,
            &contacts,
            repere_vocal_url,
            &config,
        )))
    }

    /// Zone d'une livraison — résout les paramètres de configuration.
    pub(crate) async fn zone_de_livraison(&self, livraison: Uuid) -> Result<Uuid, ErreurCoursier> {
        sqlx::query_scalar!(
            r#"SELECT c.zone_id FROM commandes.livraison l
               JOIN commandes.commande c ON c.id = l.commande_id
               WHERE l.id = $1"#,
            livraison,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCoursier::CourseNonProprietaire)
    }

    /// Configuration coursier de la zone d'une livraison.
    pub(crate) async fn config_de_livraison(
        &self,
        livraison: Uuid,
    ) -> Result<ConfigCoursier, ErreurCoursier> {
        let zone = self.zone_de_livraison(livraison).await?;
        ConfigCoursier::charger(&self.zones, zone).await
    }

    /// Instant serveur — un seul point d'accès, pour que les tests n'aient
    /// jamais à deviner quelle horloge fait foi (constitution V).
    pub(crate) fn maintenant(&self) -> chrono::DateTime<Utc> {
        Utc::now()
    }
}

/// La composition elle-même, **sans aucune I/O**.
///
/// Séparée de [`PgCoursier::course_active`] pour être exerçable avec des
/// doubles : trois domaines qui s'assemblent, c'est exactement le genre de code
/// où une inversion de champ passe inaperçue jusqu'à ce qu'un coursier appelle
/// le mauvais numéro. Ici, elle se teste sans base ni stockage objet.
pub(crate) fn composer(
    course: commandes::CourseDuCoursier,
    plaques: &HashMap<Uuid, qr::PlaqueResolue>,
    contacts: &HashMap<Uuid, prestataires::ContactVendeur>,
    repere_vocal_url: Option<String>,
    config: &ConfigCoursier,
) -> CourseComplete {
    let arrets = course
        .arrets
        .into_iter()
        .map(|a| {
            let plaque = plaques.get(&a.prestataire_id);
            let contact = contacts.get(&a.prestataire_id);
            let lignes: Vec<LigneArret> = a
                .lignes
                .into_iter()
                .map(|l| LigneArret {
                    ligne_id: l.ligne_id,
                    libelle: l.libelle,
                    quantite: i32::from(l.quantite),
                    prix_unitaire_unites: l.prix_unitaire_unites,
                    preference: l.preference,
                    statut: l.statut,
                })
                .collect();
            let mut arret = ArretComplet {
                arret_id: a.arret_id,
                ordre: a.ordre,
                prestataire_id: a.prestataire_id,
                // Le nom vient du contact, à défaut de la plaque : les deux le
                // portent, et un arrêt sans nom serait illisible sur K3.
                nom: contact
                    .map(|c| c.nom.clone())
                    .or_else(|| plaque.map(|p| p.nom.clone()))
                    .unwrap_or_default(),
                site_lat: a.site_lat,
                site_lon: a.site_lon,
                empreinte_jeton: plaque.map(|p| p.empreinte_jeton.clone()).unwrap_or_default(),
                empreinte_code: plaque.map(|p| p.empreinte_code.clone()).unwrap_or_default(),
                montant_avance: a.montant_avance,
                photo_exigee: plaque.is_some_and(|p| p.photo_exigee),
                distance_max_m: plaque.map(|p| p.distance_max_m).unwrap_or(0),
                statut: a.statut,
                en_route_le: a.en_route_le,
                arrive_le: a.arrive_le,
                collecte_le: a.collecte_le,
                // Le contact vient de `prestataires`, JAMAIS de la plaque : la
                // plaque est un objet public affiché sur un mur, le numéro non.
                telephone_vendeur: contact.map(|c| c.telephone.clone()),
                lignes,
            };
            // FR-013 : ce que Yao doit sortir de sa poche à CET arrêt, après
            // retraits. Un arrêt dont tout a été retiré vaut zéro, et c'est
            // exact — il n'a plus rien à payer, mais l'étape existe encore.
            arret.montant_avance = arret.montant_lignes_unites();
            arret
        })
        .collect();

    CourseComplete {
        livraison_id: course.livraison_id,
        commande_id: course.commande_id,
        etat: course.etat,
        devise: course.devise,
        arrets,
        client: ClientCourse {
            nom_usage: course.client.nom_usage,
            telephone: course.client.telephone,
            repere_texte: course.client.repere_texte,
            repere_vocal_url,
            repere_vocal_duree_s: course.client.repere_vocal_duree_s.map(i32::from),
            lieu_lat: Some(course.client.lieu_lat),
            lieu_lon: Some(course.client.lieu_lon),
            depot_autorise: course.client.depot_autorise,
        },
        remise: RemisePreprovisionnee {
            empreinte_code: course.remise.empreinte_code,
            empreinte_jeton: course.remise.empreinte_jeton,
            essais_consommes: course.remise.essais_consommes,
            // Le seuil vient du paramètre du cycle 008, pas d'un nouveau.
            essais_max: config.essais_code_livraison,
            code_bloque: course.remise.code_bloque,
            montant_a_encaisser_unites: course.remise.montant_a_encaisser_unites,
            mode_paiement: course.remise.mode_paiement,
            seuils_preuves: config.seuils_preuves(),
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use commandes::{
        ArretDeCourse, ClientDeCourse, CourseDuCoursier, LigneDeCourse, RemiseDeCourse,
    };
    use commandes::{
        EtatLivraison, ModePaiement, PreferenceSubstitution, StatutArret, StatutLigne,
    };

    fn config() -> ConfigCoursier {
        ConfigCoursier {
            zone: Uuid::now_v7(),
            devise: "XOF".to_owned(),
            preuve_appels_min: 2,
            preuve_appels_espacement_s: 180,
            preuve_presence_s: 600,
            preuve_presence_rayon_m: 100,
            preuve_presence_trou_max_s: 120,
            retention_photo_preuve_jours: 365,
            offre_interrogation_arriere_plan_s: 5,
            essais_code_livraison: 3,
        }
    }

    fn ligne(statut: StatutLigne, prix: i64, q: i16) -> LigneDeCourse {
        LigneDeCourse {
            ligne_id: Uuid::now_v7(),
            libelle: "Tomates".to_owned(),
            quantite: q,
            prix_unitaire_unites: prix,
            preference: PreferenceSubstitution::Appeler,
            statut,
        }
    }

    fn course(presta: Uuid, lignes: Vec<LigneDeCourse>) -> CourseDuCoursier {
        CourseDuCoursier {
            livraison_id: Uuid::now_v7(),
            commande_id: Uuid::now_v7(),
            zone_id: Uuid::now_v7(),
            etat: EtatLivraison::EnCollecte,
            devise: "XOF".to_owned(),
            arrets: vec![ArretDeCourse {
                arret_id: Uuid::now_v7(),
                ordre: 0,
                prestataire_id: presta,
                site_lat: 5.898,
                site_lon: -4.823,
                distance_precedent_m: None,
                montant_avance: 2_000,
                statut: StatutArret::ACollecter,
                en_route_le: None,
                arrive_le: None,
                collecte_le: None,
                lignes,
            }],
            client: ClientDeCourse {
                compte_id: Uuid::now_v7(),
                nom_usage: None,
                telephone: Some("+2250700000002".to_owned()),
                repere_texte: Some("Cour verte".to_owned()),
                repere_vocal_cle: None,
                repere_vocal_duree_s: Some(12),
                lieu_lat: 5.905,
                lieu_lon: -4.830,
                depot_autorise: false,
            },
            remise: RemiseDeCourse {
                empreinte_code: "a1b2".to_owned(),
                empreinte_jeton: "c3d4".to_owned(),
                essais_consommes: 1,
                code_bloque: false,
                montant_a_encaisser_unites: 5_800,
                mode_paiement: ModePaiement::Cash,
            },
        }
    }

    fn plaque(nom: &str) -> qr::PlaqueResolue {
        qr::PlaqueResolue {
            nom: nom.to_owned(),
            empreinte_jeton: "jeton-empreinte".to_owned(),
            empreinte_code: "code-empreinte".to_owned(),
            photo_exigee: true,
            distance_max_m: 100,
        }
    }

    fn contact(id: Uuid, nom: &str) -> prestataires::ContactVendeur {
        prestataires::ContactVendeur {
            prestataire_id: id,
            nom: nom.to_owned(),
            telephone: "+2250700000099".to_owned(),
        }
    }

    /// La composition assemble bien les TROIS sources, chacune à sa place.
    #[test]
    fn les_trois_sources_se_rejoignent_sans_se_melanger() {
        let presta = Uuid::now_v7();
        let plaques = HashMap::from([(presta, plaque("Étal Adjoua"))]);
        let contacts = HashMap::from([(presta, contact(presta, "Étal Adjoua"))]);

        let vue = composer(
            course(presta, vec![ligne(StatutLigne::Presente, 400, 2)]),
            &plaques,
            &contacts,
            Some("https://exemple/presigne".to_owned()),
            &config(),
        );

        let a = &vue.arrets[0];
        assert_eq!(a.nom, "Étal Adjoua");
        assert_eq!(a.empreinte_jeton, "jeton-empreinte", "vient de qr");
        assert_eq!(
            a.telephone_vendeur.as_deref(),
            Some("+2250700000099"),
            "vient de prestataires — la plaque est publique, le numéro non",
        );
        assert!(a.photo_exigee, "politique photo résolue par qr");
        assert_eq!(a.distance_max_m, 100);
        assert_eq!(vue.remise.essais_max, 3, "seuil du cycle 008, pas un nouveau");
        assert_eq!(vue.remise.seuils_preuves.presence_s, 600);
        assert_eq!(vue.client.repere_vocal_duree_s, Some(12));
        assert_eq!(
            vue.client.repere_vocal_url.as_deref(),
            Some("https://exemple/presigne"),
        );
    }

    /// FR-013 / SC-002 — le montant de l'arrêt suit les LIGNES, pas la colonne.
    /// Sans ce recalcul, Yao lirait 2 000 FCFA alors qu'il ne doit plus que 800.
    #[test]
    fn le_montant_d_arret_est_recalcule_depuis_les_lignes() {
        let presta = Uuid::now_v7();
        let vue = composer(
            course(
                presta,
                vec![
                    ligne(StatutLigne::Presente, 400, 2),
                    ligne(StatutLigne::Retiree, 1_200, 1),
                ],
            ),
            &HashMap::new(),
            &HashMap::new(),
            None,
            &config(),
        );
        assert_eq!(vue.arrets[0].montant_avance, 800);
    }

    /// Un arrêt dont TOUT a été retiré vaut zéro — mais il existe encore.
    /// Le masquer ferait disparaître une étape que Yao doit tout de même faire
    /// (ne serait-ce que pour déclarer l'arrêt impossible).
    #[test]
    fn un_arret_entierement_retire_vaut_zero_mais_reste_affiche() {
        let presta = Uuid::now_v7();
        let vue = composer(
            course(presta, vec![ligne(StatutLigne::Retiree, 400, 2)]),
            &HashMap::new(),
            &HashMap::new(),
            None,
            &config(),
        );
        assert_eq!(vue.arrets.len(), 1);
        assert_eq!(vue.arrets[0].montant_avance, 0);
    }

    /// Prestataire jamais agréé : pas de plaque, donc pas d'empreintes — mais
    /// l'arrêt est servi. Le mode dégradé du cycle 006 reste sa porte de sortie.
    #[test]
    fn un_arret_sans_plaque_est_servi_sans_empreintes() {
        let presta = Uuid::now_v7();
        let contacts = HashMap::from([(presta, contact(presta, "Étal sans plaque"))]);
        let vue = composer(
            course(presta, vec![ligne(StatutLigne::Presente, 400, 1)]),
            &HashMap::new(),
            &contacts,
            None,
            &config(),
        );
        assert_eq!(vue.arrets[0].nom, "Étal sans plaque");
        assert!(vue.arrets[0].empreinte_jeton.is_empty());
        assert!(!vue.arrets[0].photo_exigee);
    }

    /// SC-015 — aucun secret ne traverse la composition. Les empreintes servies
    /// sont exactement celles reçues, et rien d'autre n'est ajouté.
    #[test]
    fn la_composition_ne_fabrique_aucun_secret() {
        let presta = Uuid::now_v7();
        let vue = composer(
            course(presta, vec![ligne(StatutLigne::Presente, 400, 1)]),
            &HashMap::from([(presta, plaque("V"))]),
            &HashMap::new(),
            None,
            &config(),
        );
        assert_eq!(vue.remise.empreinte_code, "a1b2");
        assert_eq!(vue.remise.empreinte_jeton, "c3d4");
        assert_eq!(vue.remise.essais_consommes, 1);
        assert!(!vue.remise.code_bloque);
    }
}
